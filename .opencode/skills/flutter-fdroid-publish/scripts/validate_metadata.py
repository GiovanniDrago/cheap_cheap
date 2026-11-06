#!/usr/bin/env python3
"""Independent checks for a Flutter F-Droid metadata file.

This complements `fdroid lint` with cross-field checks that are easy to get wrong:
ABI/version-code mapping, output/binary consistency, signing fingerprint, placeholders,
line endings, git diff scope, URL availability, and the upstream commit.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

ABIS = ("armeabi-v7a", "arm64-v8a", "x86_64")
HEX40 = re.compile(r"^[0-9a-f]{40}$")
HEX64 = re.compile(r"^[0-9a-f]{64}$")
PLACEHOLDER_PATTERNS = [
    re.compile(r"__[A-Z0-9_]+__"),
    re.compile(r"\{\{[^}]+\}\}"),
    re.compile(r"<[A-Z][A-Z0-9_]+>"),
    re.compile(r"\bTODO\b"),
    re.compile(r"\bCHANGEME\b"),
    re.compile(r"\bREPLACE_ME\b"),
]


class Report:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []
        self.checks: list[dict[str, Any]] = []

    def error(self, message: str) -> None:
        self.errors.append(message)

    def warn(self, message: str) -> None:
        self.warnings.append(message)

    def check(self, name: str, ok: bool, detail: str = "") -> None:
        self.checks.append({"name": name, "ok": ok, "detail": detail})
        if not ok:
            self.error(f"{name}: {detail}" if detail else name)


def load_json(path: str) -> dict[str, Any]:
    return json.loads(Path(path).read_text(encoding="utf-8"))


def load_yaml(path: str) -> Any:
    try:
        import yaml
    except ImportError:
        sys.exit("PyYAML is required. Run scripts/bootstrap.sh and use its Python binary.")
    return yaml.safe_load(Path(path).read_text(encoding="utf-8"))


def find_placeholders(value: Any, path: str = "") -> list[str]:
    found: list[str] = []
    if isinstance(value, str):
        for pattern in PLACEHOLDER_PATTERNS:
            if pattern.search(value):
                found.append(f"{path or '$'}: {value!r}")
                break
    elif isinstance(value, dict):
        for key, item in value.items():
            found.extend(find_placeholders(item, f"{path}.{key}" if path else key))
    elif isinstance(value, list):
        for index, item in enumerate(value):
            found.extend(find_placeholders(item, f"{path}[{index}]"))
    return found


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def build_abi(build: dict[str, Any]) -> str | None:
    output = str(build.get("output", ""))
    match = re.search(r"app-(armeabi-v7a|arm64-v8a|x86_64)", output)
    if match:
        return match.group(1)
    for abi in ABIS:
        if abi in output:
            return abi
    return None


def run(command: list[str], cwd: str | None = None) -> tuple[int, str]:
    try:
        result = subprocess.run(
            command,
            cwd=cwd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
    except OSError as exc:
        return 127, str(exc)
    return result.returncode, result.stdout.rstrip()


def check_url(url: str, timeout: int = 20) -> tuple[bool, str]:
    request = urllib.request.Request(
        url,
        method="HEAD",
        headers={"User-Agent": "opencode-flutter-fdroid-publish/1.0"},
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return 200 <= response.status < 400, f"HTTP {response.status}"
    except urllib.error.HTTPError as exc:
        if exc.code not in (403, 405):
            return False, f"HTTP {exc.code}"
    except Exception as exc:  # noqa: BLE001 - network failures are reported
        return False, str(exc)

    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": "opencode-flutter-fdroid-publish/1.0",
            "Range": "bytes=0-0",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return response.status in (200, 206), f"HTTP {response.status}"
    except Exception as exc:  # noqa: BLE001
        return False, str(exc)


def download(url: str, destination: Path, timeout: int = 60) -> None:
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "opencode-flutter-fdroid-publish/1.0"},
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        with destination.open("wb") as output:
            shutil.copyfileobj(response, output)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def signing_fingerprint(apk: Path) -> str | None:
    if not shutil.which("keytool"):
        return None
    code, output = run(["keytool", "-printcert", "-jarfile", str(apk)])
    if code != 0:
        return None
    match = re.search(r"SHA256:\s*([0-9A-F:]+)", output)
    if not match:
        return None
    return match.group(1).replace(":", "").lower()


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate F-Droid metadata")
    parser.add_argument("--context", required=True, help="fdroid-context.json")
    parser.add_argument("--handoff", required=True, help="upstream.json")
    parser.add_argument("--metadata", required=True, help="metadata/<appid>.yml")
    parser.add_argument(
        "--categories-json", help="categories.json produced by fetch_categories.py"
    )
    parser.add_argument("--check-urls", action="store_true")
    parser.add_argument("--check-apks", action="store_true")
    parser.add_argument("--check-remote", action="store_true")
    parser.add_argument("--check-diff", action="store_true")
    parser.add_argument("--repo-dir", default=".", help="fdroiddata clone for git checks")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = Report()
    context = load_json(args.context)
    handoff = load_json(args.handoff)
    metadata_path = Path(args.metadata)

    try:
        metadata = load_yaml(str(metadata_path))
    except Exception as exc:  # noqa: BLE001
        print(f"error: cannot parse metadata YAML: {exc}", file=sys.stderr)
        return 1
    if not isinstance(metadata, dict):
        print("error: metadata is not a YAML mapping", file=sys.stderr)
        return 1

    raw = metadata_path.read_bytes()
    if b"\r\n" in raw:
        report.error("metadata uses CRLF line endings; use LF")
    if not raw.endswith(b"\n"):
        report.warn("metadata does not end with a newline")
    if raw.startswith(b"\xef\xbb\xbf"):
        report.error("metadata starts with a UTF-8 BOM")

    placeholders = find_placeholders(metadata)
    report.check("no-placeholders", not placeholders, "; ".join(placeholders))

    package_id = context.get("app", {}).get("packageId", "")
    version_name = context.get("release", {}).get("versionName", "")
    base_code = context.get("release", {}).get("baseVersionCode")
    abis = as_list(context.get("release", {}).get("abis"))
    integration = context.get("flutter", {}).get("integration", "submodule")

    required = [
        "Categories",
        "License",
        "AuthorName",
        "SourceCode",
        "IssueTracker",
        "RepoType",
        "Repo",
        "Builds",
        "AutoUpdateMode",
        "UpdateCheckMode",
        "VercodeOperation",
        "UpdateCheckData",
        "CurrentVersion",
        "CurrentVersionCode",
    ]
    missing = [key for key in required if key not in metadata]
    report.check("required-fields", not missing, f"missing: {', '.join(missing)}")

    categories = metadata.get("Categories")
    if not isinstance(categories, list) or not categories:
        report.error("Categories must be a non-empty list")
    elif not all(isinstance(item, str) and item for item in categories):
        report.error("Categories must contain non-empty strings")

    categories_json = None
    if args.categories_json:
        try:
            categories_json = load_json(args.categories_json)
        except Exception as exc:  # noqa: BLE001
            report.error(f"cannot read categories JSON: {exc}")
    if categories_json:
        names = {item["name"] for item in categories_json.get("categories", [])}
        for category in as_list(categories):
            report.check(
                f"category:{category}",
                category in names,
                "not present in the live categories.yml",
            )
        expected_sha = context.get("category", {}).get("sourceSha256")
        actual_sha = categories_json.get("sourceSha256")
        if expected_sha and actual_sha and expected_sha != actual_sha:
            report.error(
                "context category.sourceSha256 does not match categories.json"
            )

    license_value = metadata.get("License")
    if not isinstance(license_value, str) or not license_value:
        report.error("License is missing")
    elif re.search(r"\s", license_value):
        report.warn("License contains whitespace; use one SPDX identifier")

    for key in ("SourceCode", "IssueTracker", "Changelog"):
        value = metadata.get(key)
        if value is not None and not str(value).startswith("https://"):
            report.error(f"{key} must start with https://")
    repo = metadata.get("Repo")
    if not isinstance(repo, str) or not repo.startswith("https://"):
        report.error("Repo must be a public https:// URL")
    elif not repo.endswith(".git"):
        report.warn("Repo normally ends with .git")
    if metadata.get("RepoType") != "git":
        report.error("RepoType must be git")

    for forbidden in ("Summary", "Description", "Name"):
        if forbidden in metadata:
            report.error(
                f"{forbidden} must stay in the upstream fastlane metadata, not here"
            )
    if "Binaries" in metadata:
        report.warn(
            "top-level Binaries is unusual for a build recipe; use per-build binary"
        )

    builds = as_list(metadata.get("Builds"))
    if not builds:
        report.error("Builds must be a non-empty list")
    if len(builds) > 3:
        report.warn("more than three build blocks; confirm the ABI set")

    handoff_release = handoff.get("release", {})
    handoff_commit = handoff_release.get("commit")
    handoff_key = handoff_release.get("signingKeySha256")
    handoff_apks = {
        item.get("abi"): item for item in as_list(handoff_release.get("abis"))
    }
    reproducible = bool(handoff_release.get("reproducible", True))

    version_codes: list[int] = []
    seen_abis: list[str] = []
    commits: list[str] = []

    for index, build in enumerate(builds):
        label = f"Builds[{index}]"
        if not isinstance(build, dict):
            report.error(f"{label} is not a mapping")
            continue
        for key in ("versionName", "versionCode", "commit", "output"):
            if key not in build:
                report.error(f"{label} missing {key}")

        if build.get("versionName") != version_name:
            report.error(
                f"{label}.versionName {build.get('versionName')!r} != {version_name!r}"
            )

        commit = str(build.get("commit", ""))
        commits.append(commit)
        if not HEX40.match(commit):
            report.error(f"{label}.commit must be a full 40-character hash")
        if handoff_commit and commit != handoff_commit:
            report.error(f"{label}.commit does not match the upstream handoff")

        code = build.get("versionCode")
        if not isinstance(code, int) or isinstance(code, bool):
            report.error(f"{label}.versionCode must be an integer")
        else:
            version_codes.append(code)

        abi = build_abi(build)
        if abi is None:
            report.error(f"{label}.output does not contain a known ABI")
        else:
            seen_abis.append(abi)
            if abis and abi not in abis:
                report.error(f"{label}.output uses ABI {abi!r} not in the context")
            if isinstance(base_code, int) and isinstance(code, int):
                expected = base_code * 10 + ABIS.index(abi) + 1
                if code != expected:
                    report.error(
                        f"{label}.versionCode {code} != expected {expected} for {abi}"
                    )

        output = str(build.get("output", ""))
        if output and not output.startswith("build/app/outputs/flutter-apk/"):
            report.warn(f"{label}.output is not the usual Flutter APK path")

        expected_apk = handoff_apks.get(abi or "", {})
        if expected_apk.get("apk") and Path(output).name != Path(
            expected_apk["apk"]
        ).name:
            report.error(
                f"{label}.output {Path(output).name!r} != handoff {expected_apk['apk']!r}"
            )

        binary = build.get("binary")
        if reproducible:
            if not binary:
                report.error(f"{label}.binary is required for a reproducible build")
            else:
                binary = str(binary)
                if "%v" not in binary:
                    report.error(f"{label}.binary must contain %v")
                if output and not binary.endswith(Path(output).name):
                    report.error(
                        f"{label}.binary does not end with the output filename"
                    )
                if (
                    expected_apk.get("url")
                    and binary.replace("%v", version_name) != expected_apk["url"]
                ):
                    report.error(f"{label}.binary does not match the handoff URL")
        elif binary:
            report.warn(
                f"{label}.binary is present but the handoff says not reproducible"
            )

        if integration == "submodule":
            if build.get("submodules") is not True:
                report.warn(f"{label} should set submodules: true")
        else:
            srclibs = as_list(build.get("srclibs"))
            if "flutter@stable" not in srclibs:
                report.error(f"{label}.srclibs must include flutter@stable")

        rm = as_list(build.get("rm"))
        for directory in ("ios", "linux", "macos", "web", "windows"):
            if directory not in rm:
                report.warn(f"{label}.rm does not remove {directory}")

        prebuild = as_list(build.get("prebuild"))
        build_steps = as_list(build.get("build"))
        if not prebuild:
            report.error(f"{label}.prebuild is empty")
        if not build_steps:
            report.error(f"{label}.build is empty")

    report.check("commits-match", len(set(commits)) == 1, "all builds must use one commit")
    report.check(
        "abis-unique",
        len(seen_abis) == len(set(seen_abis)),
        f"duplicate ABI outputs: {seen_abis}",
    )

    vercode_ops = as_list(metadata.get("VercodeOperation"))
    report.check(
        "vercode-operation-count",
        len(vercode_ops) == len(builds),
        f"{len(vercode_ops)} operations for {len(builds)} builds",
    )
    for operation in vercode_ops:
        if "%c" not in str(operation):
            report.error(f"VercodeOperation {operation!r} does not contain %c")

    current_code = metadata.get("CurrentVersionCode")
    if version_codes:
        report.check(
            "current-version-code",
            current_code == max(version_codes),
            f"{current_code!r} != max({version_codes})",
        )
    report.check(
        "current-version",
        metadata.get("CurrentVersion") == version_name,
        f"{metadata.get('CurrentVersion')!r} != {version_name!r}",
    )

    update_data = metadata.get("UpdateCheckData")
    if not isinstance(update_data, str) or update_data.count("|") != 3:
        report.error("UpdateCheckData must have four parts separated by three pipes")
    if metadata.get("AutoUpdateMode") != "Version":
        report.error("AutoUpdateMode must be Version")
    if not str(metadata.get("UpdateCheckMode", "")).startswith("Tags"):
        report.error("UpdateCheckMode must start with Tags")

    allowed = metadata.get("AllowedAPKSigningKeys")
    if reproducible:
        if not isinstance(allowed, str) or not HEX64.match(allowed):
            report.error("AllowedAPKSigningKeys must be a lowercase SHA-256")
        elif handoff_key and allowed != handoff_key:
            report.error("AllowedAPKSigningKeys does not match the handoff")
    elif allowed:
        report.warn(
            "AllowedAPKSigningKeys is present but the handoff says not reproducible"
        )

    if args.check_remote:
        upstream_dir = context.get("paths", {}).get("upstreamDir", "")
        if not upstream_dir or not Path(upstream_dir).is_dir():
            report.warn("upstreamDir is not available; skipping remote check")
        else:
            code, _ = run(
                ["git", "-C", upstream_dir, "cat-file", "-e", f"{handoff_commit}^{{commit}}"]
            )
            report.check(
                "upstream-commit",
                code == 0,
                f"commit {handoff_commit!r} not found in {upstream_dir}",
            )
            tag = handoff_release.get("tag")
            if tag:
                code, resolved = run(
                    ["git", "-C", upstream_dir, "rev-parse", f"{tag}^{{commit}}"]
                )
                report.check(
                    "upstream-tag",
                    code == 0 and resolved == handoff_commit,
                    f"{tag!r} resolves to {resolved!r}, expected {handoff_commit!r}",
                )

    if args.check_diff:
        code, output = run(["git", "-C", args.repo_dir, "status", "--porcelain"])
        if code != 0:
            report.warn("cannot inspect the fdroiddata work tree")
        else:
            allowed_path = f"metadata/{package_id}.yml"
            unexpected = []
            for line in output.splitlines():
                if not line:
                    continue
                path = line[3:].strip()
                if " -> " in path:
                    path = path.split(" -> ", 1)[1]
                if path != allowed_path:
                    unexpected.append(path)
            report.check(
                "diff-scope",
                not unexpected,
                f"unexpected paths: {', '.join(unexpected)}",
            )

    urls: list[str] = []
    if reproducible:
        for build in builds:
            if isinstance(build, dict) and build.get("binary"):
                urls.append(str(build["binary"]).replace("%v", version_name))

    if args.check_urls or args.check_apks:
        for url in sorted(set(urls)):
            ok, detail = check_url(url)
            report.check(f"url:{url}", ok, detail)

    if args.check_apks:
        if not shutil.which("keytool"):
            report.warn("keytool not found; APK signing fingerprints were not checked")
        with tempfile.TemporaryDirectory(prefix="fdroid-apks-") as tmp:
            for abi, item in sorted(handoff_apks.items()):
                url = item.get("url")
                expected_sha = item.get("sha256")
                if not url:
                    report.error(f"handoff APK for {abi} has no URL")
                    continue
                destination = Path(tmp) / Path(url).name
                try:
                    download(url, destination)
                except Exception as exc:  # noqa: BLE001
                    report.error(f"cannot download {url}: {exc}")
                    continue
                actual_sha = sha256_file(destination)
                report.check(
                    f"apk-sha256:{abi}",
                    actual_sha == expected_sha,
                    f"{actual_sha} != {expected_sha}",
                )
                fingerprint = signing_fingerprint(destination)
                if fingerprint:
                    report.check(
                        f"apk-signing:{abi}",
                        fingerprint == handoff_key,
                        f"{fingerprint} != {handoff_key}",
                    )

    result = {
        "ok": not report.errors,
        "errors": report.errors,
        "warnings": report.warnings,
        "checks": report.checks,
    }
    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        for warning in report.warnings:
            print(f"warning: {warning}", file=sys.stderr)
        for error in report.errors:
            print(f"error: {error}", file=sys.stderr)
        if not report.errors:
            print(f"metadata OK ({len(report.checks)} checks)")
        else:
            print(f"{len(report.errors)} error(s)", file=sys.stderr)

    return 0 if not report.errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
