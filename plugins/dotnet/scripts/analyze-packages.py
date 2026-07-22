#!/usr/bin/env python3
"""
analyze-packages.py — Analyse NuGet package references for .NET upgrade risks.

Usage:
    python analyze-packages.py [--repo-root .] [--target-framework net10.0]

Output: JSON report to stdout. Progress to stderr.
This script does NOT modify any files.
"""

import argparse
import json
import re
import sys
from pathlib import Path
from xml.etree import ElementTree as ET

RISKY_PACKAGES = {
    "Microsoft.EntityFrameworkCore": {
        "risk": "HIGH",
        "reason": "Major version must align with target runtime. EF Core migrations may need regeneration.",
    },
    "Microsoft.EntityFrameworkCore.SqlServer": {"risk": "HIGH", "reason": "Must align with EF Core major version."},
    "Microsoft.EntityFrameworkCore.Design": {"risk": "HIGH", "reason": "Must align with EF Core major version."},
    "Npgsql": {
        "risk": "HIGH",
        "reason": "Npgsql 8+ has breaking changes (DateTime handling, nullable). Major version upgrades require testing.",
    },
    "Npgsql.EntityFrameworkCore.PostgreSQL": {
        "risk": "HIGH",
        "reason": "Must align with both EF Core and Npgsql major versions.",
    },
    "Microsoft.Extensions.DependencyInjection": {
        "risk": "MEDIUM",
        "reason": "Ships with .NET runtime. Do not pin separately — remove Version attribute and let runtime supply it.",
    },
    "Microsoft.Extensions.Logging": {
        "risk": "MEDIUM",
        "reason": "Ships with .NET runtime. Pinning can cause conflicts.",
    },
    "Microsoft.Extensions.Configuration": {
        "risk": "MEDIUM",
        "reason": "Ships with .NET runtime. Pinning can cause conflicts.",
    },
    "Microsoft.Extensions.Http": {
        "risk": "MEDIUM",
        "reason": "Ships with .NET runtime. Pinning can cause conflicts.",
    },
    "Microsoft.AspNetCore.Authentication.JwtBearer": {
        "risk": "HIGH",
        "reason": "Ships with ASP.NET Core runtime. Major version must match target framework.",
    },
    "Microsoft.AspNetCore.OpenApi": {
        "risk": "MEDIUM",
        "reason": ".NET 9+ ships built-in OpenAPI support. This package version must match target framework.",
    },
    "Microsoft.NET.Sdk.Functions": {
        "risk": "HIGH",
        "reason": "In-process Azure Functions SDK. Not supported on .NET 10+. Migration to isolated worker required.",
    },
    "Microsoft.Azure.Functions.Worker": {
        "risk": "HIGH",
        "reason": "Isolated worker SDK. Major version alignment with target framework required.",
    },
    "Microsoft.Azure.Functions.Worker.Extensions.ServiceBus": {
        "risk": "HIGH",
        "reason": "Extension packages must align with worker SDK version.",
    },
    "Microsoft.Azure.Functions.Worker.Extensions.Http": {
        "risk": "MEDIUM",
        "reason": "Extension packages must align with worker SDK version.",
    },
    "Microsoft.Azure.Functions.Worker.Extensions.Timer": {
        "risk": "MEDIUM",
        "reason": "Extension packages must align with worker SDK version.",
    },
    "Newtonsoft.Json": {
        "risk": "MEDIUM",
        "reason": "Serialisation behaviour differs from System.Text.Json. Do not silently swap serialisers.",
    },
    "MassTransit": {
        "risk": "HIGH",
        "reason": "Major version upgrades (v7→v8→v9) contain breaking changes to consumer/producer configuration.",
    },
    "MassTransit.RabbitMQ": {
        "risk": "HIGH",
        "reason": "RabbitMQ transport breaking changes may accompany MassTransit major version upgrades.",
    },
    "RabbitMQ.Client": {
        "risk": "HIGH",
        "reason": "RabbitMQ.Client v7+ has breaking API changes. Evaluate carefully.",
    },
    "OpenTelemetry": {
        "risk": "MEDIUM",
        "reason": "OpenTelemetry SDK has had breaking changes between major versions. Check exporter compatibility.",
    },
    "OpenTelemetry.Extensions.Hosting": {"risk": "MEDIUM", "reason": "Must align with OpenTelemetry core version."},
    "Serilog": {
        "risk": "LOW",
        "reason": "Generally stable across upgrades, but sink packages may need version alignment.",
    },
    "Serilog.AspNetCore": {
        "risk": "LOW",
        "reason": "Must align with ASP.NET Core version for middleware registration.",
    },
    "Swashbuckle.AspNetCore": {
        "risk": "MEDIUM",
        "reason": "v7+ required for .NET 9+ OpenAPI support. .NET 10 built-in OpenAPI makes this a modernisation candidate — consider Scalar.",
    },
    "NSwag.AspNetCore": {
        "risk": "MEDIUM",
        "reason": "NSwag code generation output may change between major versions. Review generated clients.",
    },
    "Scalar.AspNetCore": {
        "risk": "LOW",
        "reason": "Modern OpenAPI UI. If already present, verify version compatibility with target framework.",
    },
    "FluentValidation": {
        "risk": "LOW",
        "reason": "Generally stable. FluentValidation.AspNetCore may need version alignment with ASP.NET Core.",
    },
    "MediatR": {
        "risk": "LOW",
        "reason": "Generally stable. MediatR 12+ requires updated handler registration patterns.",
    },
}

OPENAPI_PACKAGES = {
    "Swashbuckle.AspNetCore",
    "NSwag.AspNetCore",
    "NSwag.MSBuild",
    "Scalar.AspNetCore",
    "Microsoft.AspNetCore.OpenApi",
}

FUNCTIONS_INPROCESS_MARKERS = {
    "Microsoft.NET.Sdk.Functions",
    "Microsoft.Azure.Functions.Extensions",
}

FUNCTIONS_ISOLATED_MARKERS = {
    "Microsoft.Azure.Functions.Worker",
    "Microsoft.Azure.Functions.Worker.Sdk",
}


def log(msg: str):
    print(f"[analyze-pkg] {msg}", file=sys.stderr)


def parse_csproj_packages(path: Path) -> list[dict]:
    """Extract PackageReference entries from a .csproj or .fsproj file."""
    packages = []
    try:
        tree = ET.parse(path)
        root = tree.getroot()
        for pr in root.iter("PackageReference"):
            name = pr.get("Include", "").strip()
            version = pr.get("Version", "").strip()
            if not name:
                continue
            packages.append({"name": name, "version": version, "source": "PackageReference"})
    except ET.ParseError as e:
        log(f"XML parse error in {path}: {e}")
    return packages


def parse_directory_packages_props(path: Path) -> list[dict]:
    """Extract PackageVersion entries from Directory.Packages.props."""
    packages = []
    try:
        tree = ET.parse(path)
        root = tree.getroot()
        for pv in root.iter("PackageVersion"):
            name = pv.get("Include", "").strip()
            version = pv.get("Version", "").strip()
            if name:
                packages.append({"name": name, "version": version, "source": "PackageVersion"})
    except ET.ParseError as e:
        log(f"XML parse error in {path}: {e}")
    return packages


def find_project_files(repo_root: Path) -> list[Path]:
    files = []
    for pattern in ("**/*.csproj", "**/*.fsproj"):
        files.extend(repo_root.glob(pattern))
    return sorted(files)


def check_risky(pkg_name: str) -> dict | None:
    """Check if package is in the risky list (prefix match for families)."""
    for risky_name, info in RISKY_PACKAGES.items():
        if pkg_name == risky_name or pkg_name.startswith(risky_name + "."):
            return {**info, "matched_rule": risky_name}
    return None


def classify_package(pkg: dict) -> dict:
    result = {**pkg, "risk_level": "OK", "risk_reason": None, "flags": []}
    risky = check_risky(pkg["name"])
    if risky:
        result["risk_level"] = risky["risk"]
        result["risk_reason"] = risky["reason"]
        result["matched_rule"] = risky["matched_rule"]
    if pkg["name"] in OPENAPI_PACKAGES:
        result["flags"].append("openapi-tooling")
    if pkg["name"] in FUNCTIONS_INPROCESS_MARKERS:
        result["flags"].append("functions-inprocess")
    if pkg["name"] in FUNCTIONS_ISOLATED_MARKERS:
        result["flags"].append("functions-isolated")
    return result


def main():
    parser = argparse.ArgumentParser(description="Analyse NuGet packages for upgrade risks.")
    parser.add_argument("--repo-root", default=".", help="Repository root")
    parser.add_argument("--target-framework", default="", help="Target TFM for context (optional)")
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    if not repo_root.exists():
        log(f"ERROR: Repo root not found: {repo_root}")
        sys.exit(1)

    log(f"Repo root: {repo_root}")
    log(f"Target framework: {args.target_framework or 'not specified'}")

    all_packages: dict[str, dict] = {}
    project_package_map: dict[str, list[str]] = {}

    # Collect CPM packages
    cpm_path = repo_root / "Directory.Packages.props"
    cpm_active = False
    if cpm_path.exists():
        cpm_pkgs = parse_directory_packages_props(cpm_path)
        log(f"Found {len(cpm_pkgs)} package(s) in Directory.Packages.props")
        cpm_active = True
        for pkg in cpm_pkgs:
            if pkg["name"] not in all_packages:
                all_packages[pkg["name"]] = pkg
            if "Directory.Packages.props" not in project_package_map:
                project_package_map["Directory.Packages.props"] = []
            project_package_map["Directory.Packages.props"].append(pkg["name"])

    # Collect per-project packages
    proj_files = find_project_files(repo_root)
    log(f"Found {len(proj_files)} project file(s)")
    for pf in proj_files:
        rel = str(pf.relative_to(repo_root))
        pkgs = parse_csproj_packages(pf)
        project_package_map[rel] = [p["name"] for p in pkgs]
        for pkg in pkgs:
            if pkg["name"] not in all_packages:
                all_packages[pkg["name"]] = pkg
            elif not all_packages[pkg["name"]]["version"] and pkg["version"]:
                all_packages[pkg["name"]]["version"] = pkg["version"]

    log(f"Total unique packages: {len(all_packages)}")

    # Classify packages
    classified = [classify_package(pkg) for pkg in all_packages.values()]
    classified.sort(key=lambda x: ({"HIGH": 0, "MEDIUM": 1, "LOW": 2, "OK": 3}[x["risk_level"]], x["name"]))

    high_risk = [p for p in classified if p["risk_level"] == "HIGH"]
    medium_risk = [p for p in classified if p["risk_level"] == "MEDIUM"]
    low_risk = [p for p in classified if p["risk_level"] == "LOW"]
    openapi_pkgs = [p for p in classified if "openapi-tooling" in p["flags"]]
    fn_inprocess = [p for p in classified if "functions-inprocess" in p["flags"]]
    fn_isolated = [p for p in classified if "functions-isolated" in p["flags"]]

    report = {
        "repo_root": str(repo_root),
        "target_framework": args.target_framework,
        "central_package_management": cpm_active,
        "total_unique_packages": len(all_packages),
        "summary": {
            "high_risk_count": len(high_risk),
            "medium_risk_count": len(medium_risk),
            "low_risk_count": len(low_risk),
            "openapi_tooling_packages": [p["name"] for p in openapi_pkgs],
            "functions_inprocess_indicators": [p["name"] for p in fn_inprocess],
            "functions_isolated_indicators": [p["name"] for p in fn_isolated],
        },
        "high_risk_packages": high_risk,
        "medium_risk_packages": medium_risk,
        "low_risk_packages": low_risk,
        "ok_packages": [p["name"] for p in classified if p["risk_level"] == "OK"],
        "project_package_map": project_package_map,
    }

    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
