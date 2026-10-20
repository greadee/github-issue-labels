#!/usr/bin/env bash
# Delete ALL labels, also removing them from existing issues and pull requests.
# Usage: ./clear-labels.sh [--dry-run] OWNER/REPO [OWNER/REPO ...]
# Requires GitHub CLI (gh) authenticated with: gh auth login
set -euo pipefail

dry_run=false
if [[ "${1:-}" == "--dry-run" ]]; then dry_run=true; shift; fi
if [[ $# -eq 0 || "${1:-}" == "--help" ]]; then
  echo "Usage: $0 [--dry-run] OWNER/REPO [OWNER/REPO ...]"
  echo "Deletes every label, including its assignments on issues and pull requests."
  exit 0
fi
command -v gh >/dev/null || { echo "Install GitHub CLI (gh) first." >&2; exit 1; }
for repo in "$@"; do
  [[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || { echo "Expected OWNER/REPO: $repo" >&2; exit 1; }
done
labels_file=$(mktemp)
trap 'rm -f "$labels_file"' EXIT
for repo in "$@"; do
  # Fetch every page successfully before beginning deletion.
  gh api --paginate "repos/$repo/labels?per_page=100" --jq '.[].name' > "$labels_file"
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    if "$dry_run"; then
      printf 'gh label delete %q --repo %q --yes\n' "$name" "$repo"
    else
      gh label delete "$name" --repo "$repo" --yes
    fi
  done < "$labels_file"
done
