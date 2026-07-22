#!/usr/bin/env python3
"""
generate-upgrade-report.py — Generate a .NET upgrade report and GitLab MR description.

Usage:
    python generate-upgrade-report.py \\
        --target-framework net10.0 \\
        [--scan-output scan.json] \\
        [--package-analysis packages.json] \\
        [--tf-update-output tf-update.json] \\
        [--version-guidance-dir references/version-guidance] \\
        [--repo-root .] \\
        [--dry-run] \\
        [--output report.md]

Output: Markdown report to stdout (or --output file). JSON summary to stderr.
"""

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path


def log(msg: str):
    print(f"[report] {msg}", file=sys.stderr)


def load_json(path: str | None) -> dict | None:
    if not path:
        return None
    p = Path(path)
    if not p.exists():
        log(f"Warning: file not found: {path}")
        return None
    try:
        return json.loads(p.read_text())
    except json.JSONDecodeError as e:
        log(f"Warning: could not parse {path}: {e}")
        return None


def load_version_guidance(guidance_dir: str | None, target: str) -> str | None:
    if not guidance_dir:
        return None
    p = Path(guidance_dir) / f"{target}.md"
    if p.exists():
        return p.read_text()
    return None


def build_project_table(projects: list[dict]) -> str:
    if not projects:
        return "_No projects found._\n"
    rows = ["| Project | Type | Current TFM | Changed |"]
    rows.append("|---------|------|-------------|---------|")
    for proj in projects:
        tf = proj.get("targetFrameworks") or proj.get("targetFramework") or "unknown"
        rows.append(f"| `{proj.get('name', '?')}` | {proj.get('type', '?')} | `{tf}` | — |")
    return "\n".join(rows) + "\n"


def build_risk_section(pkg_analysis: dict | None) -> str:
    if not pkg_analysis:
        return "_Package analysis not available. Run analyze-packages.py for details._\n"

    lines = []
    high = pkg_analysis.get("high_risk_packages", [])
    medium = pkg_analysis.get("medium_risk_packages", [])
    low = pkg_analysis.get("low_risk_packages", [])

    if high:
        lines.append("### HIGH Risk Packages\n")
        lines.append("| Package | Version | Reason |")
        lines.append("|---------|---------|--------|")
        for p in high:
            lines.append(f"| `{p['name']}` | `{p.get('version','?')}` | {p.get('risk_reason','?')} |")
        lines.append("")

    if medium:
        lines.append("### MEDIUM Risk Packages\n")
        lines.append("| Package | Version | Reason |")
        lines.append("|---------|---------|--------|")
        for p in medium:
            lines.append(f"| `{p['name']}` | `{p.get('version','?')}` | {p.get('risk_reason','?')} |")
        lines.append("")

    if low:
        lines.append("### LOW Risk Packages\n")
        lines.append(", ".join(f"`{p['name']}`" for p in low))
        lines.append("")

    if not (high or medium or low):
        lines.append("_No risky packages detected._")

    return "\n".join(lines)


def build_openapi_section(pkg_analysis: dict | None) -> str:
    if not pkg_analysis:
        return "_Package analysis not available._\n"
    openapi = pkg_analysis.get("summary", {}).get("openapi_tooling_packages", [])
    if not openapi:
        return "_No OpenAPI tooling packages detected._\n"
    lines = [f"Detected: {', '.join(f'`{p}`' for p in openapi)}", ""]
    if "Swashbuckle.AspNetCore" in openapi:
        lines.append("**Action Required (when version guidance recommends):** Evaluate Scalar as OpenAPI UI replacement.")
        lines.append("- Do NOT replace Swashbuckle automatically.")
        lines.append("- Swashbuckle v7+ is required for .NET 9+ compatibility.")
        lines.append("- Scalar uses built-in `Microsoft.AspNetCore.OpenApi` instead of Swashbuckle's generator.")
    return "\n".join(lines)


def build_functions_section(pkg_analysis: dict | None, projects: list[dict]) -> str:
    if not pkg_analysis and not projects:
        return "_No Azure Functions detected._\n"
    lines = []
    fn_inprocess = (pkg_analysis or {}).get("summary", {}).get("functions_inprocess_indicators", [])
    fn_isolated = (pkg_analysis or {}).get("summary", {}).get("functions_isolated_indicators", [])

    if fn_inprocess:
        lines.append("**IN-PROCESS model detected** (HIGH RISK):")
        lines.append(f"Packages: {', '.join(f'`{p}`' for p in fn_inprocess)}")
        lines.append("")
        lines.append("> In-process Azure Functions are NOT supported on .NET 10+.")
        lines.append("> Migration to the isolated worker model is required before upgrading.")
        lines.append("> This is a significant breaking change requiring explicit approval.")
    elif fn_isolated:
        lines.append("**ISOLATED WORKER model detected** (supported on .NET 10+).")
        lines.append(f"Packages: {', '.join(f'`{p}`' for p in fn_isolated)}")
        lines.append("Verify package versions align with target framework.")
    else:
        lines.append("_No Azure Functions SDK packages detected._")

    return "\n".join(lines)


def build_ci_section(scan: dict | None) -> str:
    if not scan:
        return "_Scan output not available._\n"
    ci = scan.get("gitlabCi", {})
    if not ci.get("file"):
        return "_No .gitlab-ci.yml found._\n"
    lines = [f"Found: `{ci['file']}`", ""]
    if ci.get("dotnetImages"):
        lines.append("**Docker images referenced:**")
        for img in ci["dotnetImages"].split(","):
            lines.append(f"- `{img.strip()}`")
        lines.append("")
    if ci.get("dotnetVariables"):
        lines.append("**SDK/Version variables:**")
        for v in ci["dotnetVariables"].split(","):
            lines.append(f"- `{v.strip()}`")
        lines.append("")
    lines.append("**Manual action required:** Update image tags and version variables to match target framework.")
    return "\n".join(lines)


def build_validation_commands(scan: dict | None) -> str:
    if not scan:
        return "```\ndotnet restore\ndotnet build\ndotnet test\n```\n"
    sln_files = scan.get("solutionFiles", [])
    slnx_files = scan.get("slnxFiles", [])
    solution = slnx_files[0] if slnx_files else (sln_files[0] if sln_files else None)
    if solution:
        return f"```bash\ndotnet --info\ndotnet restore {solution}\ndotnet build {solution}\ndotnet test {solution}\n```\n"
    return "```bash\ndotnet --info\ndotnet restore\ndotnet build\ndotnet test\n```\n"


def build_mr_description(target: str, scan: dict | None, pkg_analysis: dict | None) -> str:
    high_count = len((pkg_analysis or {}).get("high_risk_packages", []))
    medium_count = len((pkg_analysis or {}).get("medium_risk_packages", []))
    fn_inprocess = bool((pkg_analysis or {}).get("summary", {}).get("functions_inprocess_indicators"))

    risk_badge = "🟢 Low" if high_count == 0 else ("🔴 High" if high_count > 2 or fn_inprocess else "🟡 Medium")

    lines = [
        f"## .NET Version Upgrade — `{target}`",
        "",
        "### Summary",
        f"This MR upgrades the solution to target framework `{target}`.",
        "",
        "| Item | Value |",
        "|------|-------|",
        f"| Target Framework | `{target}` |",
        f"| Risk Level | {risk_badge} |",
        f"| High-Risk Packages | {high_count} |",
        f"| Medium-Risk Packages | {medium_count} |",
        f"| In-Process Functions | {'YES — migration required' if fn_inprocess else 'No'} |",
        "",
        "### Changes Made",
        "- [ ] TargetFramework/TargetFrameworks updated in project files",
        "- [ ] global.json SDK version updated",
        "- [ ] Package versions reviewed",
        "- [ ] Build passes",
        "- [ ] Tests pass",
        "",
        "### Reviewer Checklist",
        "- [ ] All projects build successfully",
        "- [ ] All tests pass",
        "- [ ] High-risk packages verified manually",
        "- [ ] GitLab CI image tags updated",
        "- [ ] Docker base images updated",
        "- [ ] No authentication/security behaviour changes",
        "- [ ] Azure Functions execution model verified (if applicable)",
        "",
        "### Follow-Up (Not In This MR)",
        "- [ ] Evaluate Scalar for OpenAPI UI (if Swashbuckle present)",
        "- [ ] Central Package Management migration",
        "- [ ] Directory.Build.props centralisation",
        "- [ ] .slnx migration",
        "",
        "/label ~dotnet-upgrade",
        f"/label ~{target}",
    ]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Generate .NET upgrade report.")
    parser.add_argument("--target-framework", required=True)
    parser.add_argument("--scan-output", help="Path to scan-dotnet-repo JSON output")
    parser.add_argument("--package-analysis", help="Path to analyze-packages JSON output")
    parser.add_argument("--tf-update-output", help="Path to update-target-framework JSON output")
    parser.add_argument("--version-guidance-dir", help="Path to version-guidance directory")
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--output", help="Write report to this file instead of stdout")
    args = parser.parse_args()

    target = args.target_framework.strip()
    repo_root = Path(args.repo_root).resolve()
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    scan = load_json(args.scan_output)
    pkg_analysis = load_json(args.package_analysis)
    tf_update = load_json(args.tf_update_output)
    guidance = load_version_guidance(args.version_guidance_dir, target)

    projects = (scan or {}).get("projects", [])

    guidance_status = f"✅ Found — `{target}.md`" if guidance else f"❌ Not available for `{target}` — mechanical upgrade only"

    lines = [
        f"# .NET Upgrade Report",
        "",
        f"**Date:** {now}",
        f"**Repo:** `{repo_root}`",
        f"**Target Framework:** `{target}`",
        f"**Version Guidance:** {guidance_status}",
        f"**Mode:** {'report-only (dry run)' if args.dry_run else 'upgrade applied'}",
        "",
        "---",
        "",
        "## Repo Summary",
        "",
    ]

    if scan:
        sln = scan.get("solutionFiles", [])
        slnx = scan.get("slnxFiles", [])
        gj = scan.get("globalJson", {})
        pm = scan.get("packageManagement", {})
        lines += [
            f"- Solution files (`.sln`): {', '.join(f'`{s}`' for s in sln) or 'none'}",
            f"- Solution files (`.slnx`): {', '.join(f'`{s}`' for s in slnx) or 'none'}",
            f"- `global.json` SDK: `{gj.get('sdkVersion') or 'not found'}`",
            f"- Central Package Management: {'✅ active' if pm.get('centralPackageManagement') else '❌ not active'}",
            f"- `Directory.Build.props`: {'✅ present' if pm.get('directoryBuildProps') else '❌ absent'}",
            f"- TFM in `Directory.Build.props`: {'✅ yes' if pm.get('targetFrameworkInBuildProps') else 'no'}",
            "",
        ]
    else:
        lines.append("_Scan output not provided._\n")

    lines += [
        "## Project Summary",
        "",
        build_project_table(projects),
        "",
        "## Changes Applied",
        "",
    ]

    if tf_update:
        changed = [c for c in tf_update.get("changes", []) if c.get("changed")]
        skipped = [c for c in tf_update.get("changes", []) if not c.get("changed") and not c.get("error")]
        errors = [c for c in tf_update.get("changes", []) if c.get("error")]
        lines += [
            f"- Files changed: **{len(changed)}**",
            f"- Files skipped (already at target): **{len(skipped)}**",
            f"- Errors: **{len(errors)}**",
            "",
        ]
        if changed:
            lines.append("### Modified Files")
            for c in changed:
                for tag, original in c.get("original", {}).items():
                    updated = c.get("updated", {}).get(tag, "?")
                    lines.append(f"- `{c['file']}`: `{original}` → `{updated}`")
            lines.append("")
    else:
        lines.append("_No TFM update output provided._\n")

    lines += [
        "## Package Risks",
        "",
        build_risk_section(pkg_analysis),
        "",
        "## OpenAPI Tooling",
        "",
        build_openapi_section(pkg_analysis),
        "",
        "## Azure Functions",
        "",
        build_functions_section(pkg_analysis, projects),
        "",
        "## GitLab CI",
        "",
        build_ci_section(scan),
        "",
        "## Build & Test",
        "",
        "Run after applying changes:",
        "",
        build_validation_commands(scan),
        "",
        "## Manual Follow-Up Checklist",
        "",
        "- [ ] Review all HIGH-risk packages and update versions manually",
        "- [ ] Update GitLab CI image tags to match target framework",
        "- [ ] Update Dockerfile base images to match target framework",
        "- [ ] Verify test results are green",
        "- [ ] Review any nullable reference type warnings introduced",
        "- [ ] Check for deprecated API usage flagged by build warnings",
    ]

    if not guidance:
        lines += [
            "",
            f"> **Note:** No version-specific guidance exists for `{target}`.",
            "> Only safe mechanical upgrade changes (TFM update, global.json) have been applied.",
            f"> To add guidance, create `references/version-guidance/{target}.md` using the `future-lts-template.md`.",
        ]
    else:
        lines += [
            "",
            "## Version-Specific Guidance",
            "",
            f"_From `references/version-guidance/{target}.md`:_",
            "",
            guidance[:2000] + ("..." if len(guidance) > 2000 else ""),
        ]

    lines += [
        "",
        "---",
        "",
        "## GitLab MR Description",
        "",
        "```markdown",
        build_mr_description(target, scan, pkg_analysis),
        "```",
    ]

    report = "\n".join(lines)

    if args.output:
        Path(args.output).write_text(report)
        log(f"Report written to {args.output}")
    else:
        print(report)

    meta = {
        "target_framework": target,
        "guidance_available": guidance is not None,
        "projects_found": len(projects),
        "high_risk_packages": len((pkg_analysis or {}).get("high_risk_packages", [])),
        "medium_risk_packages": len((pkg_analysis or {}).get("medium_risk_packages", [])),
    }
    log(json.dumps(meta))


if __name__ == "__main__":
    main()
