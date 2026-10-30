#!/usr/bin/env bash
# Create or update the template labels; preserve other labels.
# Usage: ./apply-labels.sh [--dry-run] [--CATEGORY ...] OWNER/REPO [OWNER/REPO ...]
# Requires GitHub CLI (gh) authenticated with: gh auth login
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
labels_dir="$script_dir/labels"
category_order=(priority size relationships type state collab)

usage() {
  cat <<EOF
Usage: $0 [--dry-run] [--CATEGORY ...] OWNER/REPO [OWNER/REPO ...]

Without a category option, every category is applied.
Available categories:
EOF
  local category
  for category in "${category_order[@]}"; do
    if [[ -f "$labels_dir/$category.txt" ]]; then
      printf '  --%s\n' "$category"
    fi
  done
  cat <<'EOF'

Use --all to reset the selection to every category.
EOF
}

dry_run=false
apply_all=true
declare -A selected=()
repos=()

while (($#)); do
  case "$1" in
    --dry-run)
      dry_run=true
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --all)
      selected=()
      apply_all=true
      ;;
    --*)
      category=${1#--}
      valid=false
      for candidate in "${category_order[@]}"; do
        if [[ "$category" == "$candidate" && -f "$labels_dir/$category.txt" ]]; then
          valid=true
          break
        fi
      done
      if [[ "$valid" == false ]]; then
        echo "Unknown option or category: $1" >&2
        usage >&2
        exit 1
      fi
      selected["$category"]=1
      apply_all=false
      ;;
    *)
      repos+=("$1")
      ;;
  esac
  shift
done

if ((${#repos[@]} == 0)); then
  usage
  exit 0
fi

command -v gh >/dev/null || { echo "Install GitHub CLI (gh) first." >&2; exit 1; }
for repo in "${repos[@]}"; do
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

for repo in "${repos[@]}"; do
  declare -A seen=()
  for category in "${category_order[@]}"; do
    if [[ "$apply_all" == false && -z "${selected[$category]:-}" ]]; then
      continue
    fi
    file="$labels_dir/$category.txt"
    [[ -f "$file" ]] || continue
    apply_labels "$repo" "$file"
  done
done
