#!/usr/bin/env bash
# Create or update the template labels; preserve other labels.
# Usage: ./apply-labels.sh [--dry-run] OWNER/REPO [OWNER/REPO ...]
# Requires GitHub CLI (gh) authenticated with: gh auth login
set -euo pipefail

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
for repo in "$@"; do
  while IFS='|' read -r name color description; do
    if "$dry_run"; then
      printf 'gh label create %q --repo %q --color %q --description %q --force\n' "$name" "$repo" "$color" "$description"
    else
      gh label create "$name" --repo "$repo" --color "$color" --description "$description" --force
    fi
  done <<'LABELS'
low|F8B4B4|Low priority
medium|EF7373|Medium priority
high|DC3434|High priority
critical|990F1F|Critical priority; requires immediate attention
deferred|9CA3AF|Postponed for later consideration
chore|6B7280|Routine maintenance or housekeeping
bug|703070|Something is not working as expected
feature|BF7FBF|New functionality
enhancement|68A9E8|Improvement to existing functionality
documentation|153E75|Documentation additions or improvements
testing|8B5CF6|Tests, test coverage, or quality verification
revision|A4C8F0|Changes or rework to existing implementation
design|397BC6|Design, user experience, or architecture work
ci/cd|FFFDD0|Continuous integration, delivery, or deployment
tracking|2A9D8F|Tracks ongoing work, progress, or follow-up
help wanted|FFD700|Contributions or additional assistance welcome
question|FFF3B0|A question or clarification is needed
in-progress|238636|Work is actively underway
ready|A7E8A1|Ready for work to begin
parent|C65D0A|Tracks a larger body of work with child issues
child|FFC078|A subtask belonging to a parent issue
LABELS
done
