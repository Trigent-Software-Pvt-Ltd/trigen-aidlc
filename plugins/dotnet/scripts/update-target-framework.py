#!/usr/bin/env python3
"""
update-target-framework.py — Update TargetFramework/TargetFrameworks in .NET project files.

Usage:
    python update-target-framework.py --target-framework net10.0 [options]

Options:
    --target-framework   Required. Target TFM (e.g. net10.0, net8.0).
    --repo-root          Repo root directory. Default: current directory.
    --dry-run            Report changes without writing files.
    --preserve-netstandard  Preserve netstandard* targets in multi-target projects (default: true).
    --no-preserve-netstandard  Allow replacing netstandard targets.

Output: JSON summary to stdout. Progress/errors to stderr.
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path

VALID_TFM_PATTERN = re.compile(
    r'^(net\d+\.\d+|netstandard\d+\.\d+|net\d{2,3}|netcoreapp\d+\.\d+)$'
)
NETSTANDARD_PATTERN = re.compile(r'netstandard\d+\.\d+')
TF_TAG_PATTERN = re.compile(
    r'(<TargetFramework(?:s)?>)([^<]+)(</TargetFramework(?:s)?>)',
    re.IGNORECASE
)


def log(msg: str):
    print(f"[update-tf] {msg}", file=sys.stderr)


def validate_tfm(tfm: str) -> bool:
    return bool(VALID_TFM_PATTERN.match(tfm))


def is_net_versioned(tfm: str) -> bool:
    """True if this is a netX.Y style TFM (excludes netstandard)."""
    return bool(re.match(r'^net\d+\.\d+$', tfm)) or bool(re.match(r'^netcoreapp\d+\.\d+$', tfm))


def update_tfm_value(current: str, target: str, preserve_netstandard: bool) -> tuple[str, bool]:
    """
    Given a TargetFramework(s) value, return (new_value, changed).
    Handles both single TFM and semicolon-separated multi-target.
    """
    parts = [p.strip() for p in current.split(';') if p.strip()]
    new_parts = []
    changed = False

    for part in parts:
        if NETSTANDARD_PATTERN.match(part) and preserve_netstandard:
            new_parts.append(part)
        elif is_net_versioned(part):
            if part != target:
                new_parts.append(target)
                changed = True
            else:
                new_parts.append(part)
        else:
            new_parts.append(part)

    if not any(is_net_versioned(p) for p in parts):
        return current, False

    new_value = ';'.join(new_parts)
    return new_value, changed


def process_file(path: Path, target: str, preserve_netstandard: bool, dry_run: bool) -> dict:
    result = {
        "file": str(path),
        "changed": False,
        "dry_run": dry_run,
        "original": {},
        "updated": {},
        "error": None,
    }

    try:
        content = path.read_text(encoding='utf-8')
    except Exception as e:
        result["error"] = str(e)
        return result

    new_content = content
    matches_found = list(TF_TAG_PATTERN.finditer(content))

    if not matches_found:
        return result

    for m in matches_found:
        tag_open = m.group(1)
        current_val = m.group(2).strip()
        tag_close = m.group(3)
        new_val, changed = update_tfm_value(current_val, target, preserve_netstandard)

        result["original"][tag_open.strip('<>')] = current_val
        result["updated"][tag_open.strip('<>')] = new_val

        if changed:
            result["changed"] = True
            new_content = new_content.replace(
                m.group(0),
                f"{tag_open}{new_val}{tag_close}",
                1
            )

    if result["changed"] and not dry_run:
        try:
            path.write_text(new_content, encoding='utf-8')
        except Exception as e:
            result["error"] = str(e)
            result["changed"] = False

    return result


def find_project_files(repo_root: Path) -> list[Path]:
    files = []
    for pattern in ("**/*.csproj", "**/*.fsproj"):
        files.extend(repo_root.glob(pattern))
    return sorted(files)


def find_build_props(repo_root: Path) -> Path | None:
    p = repo_root / "Directory.Build.props"
    return p if p.exists() else None


def main():
    parser = argparse.ArgumentParser(description="Update .NET target frameworks.")
    parser.add_argument("--target-framework", required=True, help="Target TFM, e.g. net10.0")
    parser.add_argument("--repo-root", default=".", help="Repository root directory")
    parser.add_argument("--dry-run", action="store_true", help="Report without writing")
    parser.add_argument("--preserve-netstandard", action="store_true", default=True,
                        help="Preserve netstandard targets (default: true)")
    parser.add_argument("--no-preserve-netstandard", dest="preserve_netstandard",
                        action="store_false", help="Allow replacing netstandard targets")
    args = parser.parse_args()

    target = args.target_framework.strip()
    if not validate_tfm(target):
        log(f"ERROR: '{target}' is not a valid TFM. Expected format: net10.0, netstandard2.0, etc.")
        sys.exit(1)

    repo_root = Path(args.repo_root).resolve()
    if not repo_root.exists():
        log(f"ERROR: Repo root not found: {repo_root}")
        sys.exit(1)

    log(f"Target framework: {target}")
    log(f"Repo root: {repo_root}")
    log(f"Dry run: {args.dry_run}")
    log(f"Preserve netstandard: {args.preserve_netstandard}")

    results = []

    # Check Directory.Build.props first (centralised TFM takes precedence)
    build_props = find_build_props(repo_root)
    if build_props:
        log(f"Processing Directory.Build.props: {build_props}")
        r = process_file(build_props, target, args.preserve_netstandard, args.dry_run)
        r["file"] = "Directory.Build.props"
        r["note"] = "Centralised TFM — project files may inherit this"
        results.append(r)

    # Process project files
    proj_files = find_project_files(repo_root)
    log(f"Found {len(proj_files)} project file(s)")

    for pf in proj_files:
        rel = str(pf.relative_to(repo_root))
        log(f"Processing: {rel}")
        r = process_file(pf, target, args.preserve_netstandard, args.dry_run)
        r["file"] = rel
        results.append(r)

    changed_count = sum(1 for r in results if r["changed"])
    skipped_count = sum(1 for r in results if not r["changed"] and not r["error"])
    error_count = sum(1 for r in results if r["error"])

    summary = {
        "target_framework": target,
        "repo_root": str(repo_root),
        "dry_run": args.dry_run,
        "preserve_netstandard": args.preserve_netstandard,
        "total_files_scanned": len(results),
        "files_changed": changed_count,
        "files_skipped": skipped_count,
        "files_errored": error_count,
        "changes": results,
    }

    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
