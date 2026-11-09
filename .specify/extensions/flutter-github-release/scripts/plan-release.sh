#!/usr/bin/env bash
# Validates the Flutter GitHub release setup and computes the next release tag.
# Read-only: it never edits pubspec.yaml, creates commits, or pushes tags.
set -euo pipefail

fail() {
	printf '[plan-release] %s\n' "$*" >&2
	exit 1
}

warn() {
	printf '[plan-release] warning: %s\n' "$*" >&2
}

workflow_matches() {
	local file="$1"

	grep -Eq 'push:' "$file" || return 1
	grep -Eq 'tags:' "$file" || return 1
	grep -Eq 'v\*' "$file" || return 1
	grep -Eq 'softprops/action-gh-release|action-gh-release|gh release create' "$file" || return 1
}

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	fail "Not a Git repository. Run this command from the Flutter project root."
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

if [[ ! -f pubspec.yaml ]]; then
	fail "pubspec.yaml not found. This command only supports Flutter projects."
fi

if ! grep -Eq '^[[:space:]]*version:[[:space:]]*' pubspec.yaml; then
	fail "No version: field in pubspec.yaml. This command only supports Flutter projects."
fi

if ! git remote get-url origin >/dev/null 2>&1; then
	fail "No 'origin' remote. Configure the GitHub remote before releasing."
fi

branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$branch" == "HEAD" || -z "$branch" ]]; then
	fail "Detached HEAD. Check out a branch before releasing."
fi

status="$(git status --porcelain)"
if [[ -n "$status" ]]; then
	tracked_dirty="$(printf '%s\n' "$status" | grep -vE '^\?\?' || true)"
	untracked="$(printf '%s\n' "$status" | grep -E '^\?\?' || true)"
else
	tracked_dirty=""
	untracked=""
fi

if [[ -n "$tracked_dirty" ]]; then
	printf '%s\n' "$tracked_dirty" >&2
	fail "The working tree has uncommitted tracked changes. Commit or stash them first."
fi

if [[ -n "$untracked" ]]; then
	untracked_count="$(printf '%s\n' "$untracked" | wc -l | tr -d ' ')"
	warn "${untracked_count} untracked file(s) are present and will not be included in the release tag."
fi

missing=()
if [[ ! -f scripts/tag-release.sh ]]; then
	missing+=("scripts/tag-release.sh")
elif [[ ! -x scripts/tag-release.sh ]]; then
	fail "scripts/tag-release.sh is not executable. Run: chmod +x scripts/tag-release.sh"
fi

workflow_file=""
preferred_workflow=".github/workflows/android-release-build.yml"
if [[ -f "$preferred_workflow" ]] && workflow_matches "$preferred_workflow"; then
	workflow_file="$(basename "$preferred_workflow")"
else
	while IFS= read -r candidate; do
		if workflow_matches "$candidate"; then
			workflow_file="$(basename "$candidate")"
			break
		fi
	done < <(find .github/workflows -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) -print 2>/dev/null | sort)
fi

if [[ -z "$workflow_file" ]]; then
	missing+=("a tag-triggered GitHub Actions workflow that publishes a GitHub Release")
fi

if [[ ${#missing[@]} -gt 0 ]]; then
	printf '[plan-release] Release automation is incomplete:\n' >&2
	for item in "${missing[@]}"; do
		printf ' - missing %s\n' "$item" >&2
	done
	printf '[plan-release] Install/apply the `flutter-github-deploy` skill first, then re-run this command. No files were changed.\n' >&2
	exit 10
fi

if [[ "${PLAN_RELEASE_NO_FETCH:-0}" != "1" ]]; then
	if ! GIT_TERMINAL_PROMPT=0 git fetch --tags --quiet origin >/dev/null 2>&1; then
		warn "Could not fetch tags from origin; using the local tags only."
	fi
fi

current_full="$(sed -nE 's/^[[:space:]]*version:[[:space:]]*//p' pubspec.yaml | head -n1 | sed -E 's/[[:space:]]+#.*$//' | xargs)"
current_version="${current_full%%+*}"
if [[ ! "$current_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	fail "Unsupported pubspec.yaml version '${current_full}'. Expected X.Y.Z or X.Y.Z+build."
fi

local_versions="$(git tag --list 'v*' | sed -E 's/^v//' || true)"
remote_versions="$(git ls-remote --tags origin 'refs/tags/v*' 2>/dev/null | sed -E 's#.*refs/tags/v##; s/\^\{\}$//' || true)"
all_versions="$(printf '%s\n%s\n' "$local_versions" "$remote_versions" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -u || true)"
latest_version="$(printf '%s\n' "$all_versions" | sort -V | tail -n1)"
latest_tag=""
if [[ -n "$latest_version" ]]; then
	latest_tag="v$latest_version"
fi

base_version="$current_version"
if [[ -n "$latest_version" ]]; then
	base_version="$(printf '%s\n%s\n' "$current_version" "$latest_version" | sort -V | tail -n1)"
	if [[ "$current_version" != "$latest_version" ]]; then
		warn "pubspec.yaml version ${current_version} differs from the latest tag ${latest_tag}; using ${base_version} as the base version."
	fi
fi

has_latest_ref=0
if [[ -n "$latest_tag" ]] && git rev-parse -q --verify "refs/tags/$latest_tag" >/dev/null 2>&1; then
	has_latest_ref=1
fi

bump="patch"
bump_reason="no feat or breaking commits"
commit_log=""
has_changes=unknown

if [[ -n "$latest_tag" && $has_latest_ref -eq 0 ]]; then
	warn "Latest tag ${latest_tag} is not available locally. Cannot analyse the commits since that release; defaulting to a patch bump."
	bump_reason="latest tag ${latest_tag} is not available locally; defaulting to patch"
elif [[ -z "$latest_tag" ]]; then
	commit_count="$(git rev-list --count HEAD 2>/dev/null || echo 0)"
	commit_log="$(git log HEAD --format='%s%n%b' 2>/dev/null || true)"
	if [[ "${commit_count:-0}" -gt 0 ]]; then
		has_changes=true
	else
		has_changes=false
		warn "No commits found in the repository. The proposed tag would release an empty history."
	fi
elif git merge-base --is-ancestor "$latest_tag" HEAD >/dev/null 2>&1; then
	commit_count="$(git rev-list --count "$latest_tag..HEAD" 2>/dev/null || echo 0)"
	commit_log="$(git log "$latest_tag..HEAD" --format='%s%n%b' 2>/dev/null || true)"
	if [[ "${commit_count:-0}" -gt 0 ]]; then
		has_changes=true
	else
		has_changes=false
		warn "No commits found since ${latest_tag}. The proposed tag would release the same code."
	fi
elif git merge-base --is-ancestor HEAD "$latest_tag" >/dev/null 2>&1; then
	has_changes=false
	warn "Current branch is behind the latest release ${latest_tag} and does not contain it. Defaulting to a patch bump."
	bump_reason="current branch is behind ${latest_tag}; defaulting to patch"
else
	commit_count="$(git rev-list --count "$latest_tag..HEAD" 2>/dev/null || echo 0)"
	commit_log="$(git log "$latest_tag..HEAD" --format='%s%n%b' 2>/dev/null || true)"
	warn "Current branch diverges from the latest release ${latest_tag}; analysing only commits reachable from HEAD."
	if [[ "${commit_count:-0}" -gt 0 ]]; then
		has_changes=true
	else
		has_changes=false
		warn "No commits found on this branch since the latest release ${latest_tag}."
	fi
fi

if [[ -n "$commit_log" ]]; then
	if grep -Eq 'BREAKING[ -]CHANGE|^[A-Za-z]+(\([^)]*\))?!:' <<< "$commit_log"; then
		bump="breaking"
		bump_reason="$(grep -Em1 'BREAKING[ -]CHANGE|^[A-Za-z]+(\([^)]*\))?!:' <<< "$commit_log")"
	elif grep -Eq '^feat(\([^)]*\))?:' <<< "$commit_log"; then
		bump="minor"
		bump_reason="$(grep -Em1 '^feat(\([^)]*\))?:' <<< "$commit_log")"
	fi
fi
bump_reason="$(printf '%s' "$bump_reason" | tr '\n' ' ' | cut -c1-200)"

IFS=. read -r major minor patch <<< "$base_version"
major=$((10#$major))
minor=$((10#$minor))
patch=$((10#$patch))

case "$bump" in
	breaking)
		if [[ "$major" -eq 0 ]]; then
			minor=$((minor + 1))
			patch=0
			bump="minor"
			bump_reason="breaking change on 0.x: $bump_reason"
		else
			major=$((major + 1))
			minor=0
			patch=0
			bump="major"
		fi
		;;
	minor)
		minor=$((minor + 1))
		patch=0
		;;
	patch)
		patch=$((patch + 1))
		;;
esac

proposed_version="${major}.${minor}.${patch}"
proposed_tag="v${proposed_version}"
build_number=$((10#$major * 10000 + 10#$minor * 100 + 10#$patch))

if git rev-parse -q --verify "refs/tags/$proposed_tag" >/dev/null 2>&1; then
	fail "Proposed tag ${proposed_tag} already exists locally. Choose a different version."
fi

if git ls-remote --tags origin "refs/tags/$proposed_tag" 2>/dev/null | grep -q .; then
	fail "Proposed tag ${proposed_tag} already exists on origin. Choose a different version."
fi

if [[ "$branch" != "main" && "$branch" != "master" ]]; then
	warn "Current branch '${branch}' is not main or master; scripts/tag-release.sh will push this branch and tag its HEAD."
fi

if git rev-parse -q --verify "origin/$branch" >/dev/null 2>&1; then
	behind="$(git rev-list --count "HEAD..origin/$branch" 2>/dev/null || echo 0)"
	if [[ "${behind:-0}" -gt 0 ]]; then
		warn "Current branch is ${behind} commit(s) behind origin/${branch}; pull before releasing."
	fi
fi

gh_available=false
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
	gh_available=true
else
	warn "gh is not installed or not authenticated; the workflow cannot be monitored automatically."
fi

printf 'PROJECT_TYPE=flutter\n'
printf 'BRANCH=%s\n' "$branch"
printf 'WORKFLOW_FILE=%s\n' "$workflow_file"
printf 'CURRENT_VERSION=%s\n' "$current_version"
printf 'LATEST_TAG=%s\n' "$latest_tag"
printf 'LATEST_VERSION=%s\n' "$latest_version"
printf 'BUMP=%s\n' "$bump"
printf 'BUMP_REASON=%s\n' "$bump_reason"
printf 'PROPOSED_VERSION=%s\n' "$proposed_version"
printf 'PROPOSED_TAG=%s\n' "$proposed_tag"
printf 'BUILD_NUMBER=%s\n' "$build_number"
printf 'HAS_CHANGES=%s\n' "$has_changes"
printf 'GH_AVAILABLE=%s\n' "$gh_available"
