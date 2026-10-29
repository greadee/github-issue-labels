#!/usr/bin/env bash
# Create or update the template labels; preserve other labels.
# Usage: ./apply-labels.sh [--dry-run] OWNER/REPO [OWNER/REPO ...]
# Requires GitHub CLI (gh) authenticated with: gh auth login
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
labels_dir="$script_dir/labels"
category_order=(priority size relationships type state collab)

dry_run=false
if [[ "${1:-}" == "--dry-run" ]]; then dry_run=true; shift; fi
if [[ $# -eq 0 || "${1:-}" == "--help" ]]; then
  echo "Usage: $0 [--dry-run] OWNER/REPO [OWNER/REPO ...]"
  exit 0
fi
command -v gh >/dev/null || { echo "Install GitHub CLI (gh) first." >&2; exit 1; }
for repo in "$@"; do
  [[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || { echo "Expected OWNER/REPO: $repo" >&2; exit 1; }
done

apply_labels() {
  local repo=$1 file=$2
  local name color description
  while IFS='|' read -r name color description || [[ -n "$name" ]]; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    [[ -n "${seen[$name]:-}" ]] && continue
    seen[$name]=1
    if "$dry_run"; then
      printf 'gh label create %q --repo %q --color %q --description %q --force\n' "$name" "$repo" "$color" "$description"
    else
      gh label create "$name" --repo "$repo" --color "$color" --description "$description" --force
    fi
  done < "$file"
}

for repo in "$@"; do
  declare -A seen=()
  for category in "${category_order[@]}"; do
    file="$labels_dir/$category.txt"
    [[ -f "$file" ]] || continue
    apply_labels "$repo" "$file"
  done
done
