#!/usr/bin/env bash
# Validates a user-supplied release tag before it is passed to scripts/tag-release.sh.
# Prints the normalized tag (with the leading "v") on success.
set -euo pipefail

fail() {
	printf '[validate-tag] %s\n' "$*" >&2
	exit 1
}

if [[ $# -lt 1 || -z "${1:-}" ]]; then
	printf 'Usage: %s <tag> [latest_version]\n' "$0" >&2
	exit 1
fi

raw_tag="$1"
latest_version="${2:-}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	fail "Not a Git repository."
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

tag="$raw_tag"
if [[ "$tag" != v* ]]; then
	tag="v$tag"
fi
version="${tag#v}"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	fail "Invalid tag '${raw_tag}'. Expected vX.Y.Z or X.Y.Z."
fi

if [[ -n "$latest_version" && "$latest_version" != "none" ]]; then
	if [[ ! "$latest_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
		fail "Invalid latest version '${latest_version}'."
	fi

	highest="$(printf '%s\n%s\n' "$version" "$latest_version" | sort -V | tail -n1)"
	if [[ "$version" == "$latest_version" || "$highest" != "$version" ]]; then
		fail "Tag ${tag} must be greater than the latest release v${latest_version}."
	fi
fi

if git rev-parse -q --verify "refs/tags/$tag" >/dev/null 2>&1; then
	fail "Tag ${tag} already exists locally."
fi

if git ls-remote --tags origin "refs/tags/$tag" 2>/dev/null | grep -q .; then
	fail "Tag ${tag} already exists on origin."
fi

printf '%s\n' "$tag"
