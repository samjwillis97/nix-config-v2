#!/usr/bin/env bash
#
# cleanup-stale-worktrees.sh
#
# Interactively clean up STALE git worktrees under an owner directory
# (default: ~/code/github.com/nib-group), using the workspace `rm-tree` tool.
#
# "Stale" = the worktree's HEAD commit is older than $DAYS days (default 60).
#
# Phase 1 (auto, one confirmation):
#     Deletes worktrees that are SAFE = clean working tree AND fully pushed
#     to their remote (nothing to lose; you can recreate them with `f`).
#
# Phase 2 (interactive, one-by-one):
#     For every remaining stale worktree (uncommitted changes / unpushed
#     commits / no remote), shows you exactly what would be lost (changed
#     files, unpushed commits) and asks what to do.
#
# master / main worktrees are NEVER touched.
#
# Usage:
#     ./cleanup-stale-worktrees.sh           # do it for real
#     DRY_RUN=1 ./cleanup-stale-worktrees.sh # preview only, delete nothing
#     DAYS=90 ./cleanup-stale-worktrees.sh   # change the staleness threshold
#     BASE=~/code/github.com/other ./cleanup-stale-worktrees.sh
#
set -uo pipefail

BASE="${BASE:-$HOME/code/github.com/nib-group}"
DAYS="${DAYS:-60}"
DRY_RUN="${DRY_RUN:-0}"
PROTECTED_RE='^(master|main)$'   # branch dirs that are NEVER deleted

usage() {
  cat <<EOF
Usage: cleanup-stale-worktrees [-h]

Interactively clean up STALE git worktrees under an owner directory
(default: \$HOME/code/github.com/nib-group), using the workspace 'rm-tree' tool.

"Stale" = the worktree's HEAD commit is older than \$DAYS days (default 60).

Phase 1 (auto, one confirmation):
    Deletes worktrees that are SAFE = clean working tree AND fully pushed
    to their remote (nothing to lose; you can recreate them with 'f').

Phase 2 (interactive, one-by-one):
    For every remaining stale worktree (uncommitted changes / unpushed
    commits / no remote), shows you exactly what would be lost and asks
    what to do. master / main worktrees are NEVER touched.

Options:
    -h, --help    Show this help and exit.

Environment variables:
    DRY_RUN=1     Preview only, delete nothing.
    DAYS=90       Change the staleness threshold (default 60).
    BASE=<dir>    Owner directory to scan
                  (default \$HOME/code/github.com/nib-group).

Examples:
    cleanup-stale-worktrees                 # do it for real
    DRY_RUN=1 cleanup-stale-worktrees       # preview only
    DAYS=90 cleanup-stale-worktrees         # 90-day threshold
    BASE=~/code/github.com/other cleanup-stale-worktrees
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown argument '$arg'" >&2; echo >&2; usage >&2; exit 2 ;;
  esac
done

command -v rm-tree >/dev/null 2>&1 || { echo "error: 'rm-tree' not found on PATH"; exit 1; }
[ -d "$BASE" ] || { echo "error: BASE '$BASE' does not exist"; exit 1; }

now=$(date +%s)
self=$(pwd -P)

# ---- colors (no-op if not a tty) -------------------------------------------
if [ -t 1 ]; then
  bold=$'\e[1m'; dim=$'\e[2m'; red=$'\e[31m'; grn=$'\e[32m'; ylw=$'\e[33m'; cyn=$'\e[36m'; rst=$'\e[0m'
else
  bold=; dim=; red=; grn=; ylw=; cyn=; rst=
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
SAFE_F="$work/safe.tsv"      # age \t date \t repo \t branch
REVIEW_F="$work/review.tsv"  # age \t date \t reason \t repo \t branch
: >"$SAFE_F"; : >"$REVIEW_F"

# ---- remove one worktree via rm-tree (with guards) -------------------------
remove_worktree() { # $1=repo  $2=branch_dir
  local repo="$1" br="$2" repo_dir="$BASE/$1" wt="$BASE/$1/$2" tp
  if [[ "$br" =~ $PROTECTED_RE ]]; then
    echo "${ylw}  refusing to delete protected branch: $repo/$br${rst}"; return 1
  fi
  tp=$(cd "$wt" 2>/dev/null && pwd -P || true)
  if [ -n "$tp" ] && { [ "$self" = "$tp" ] || [[ "$self" == "$tp"/* ]]; }; then
    echo "${ylw}  skipping (you are currently inside it): $repo/$br${rst}"; return 1
  fi
  if [ ! -d "$repo_dir/main" ] && [ ! -d "$repo_dir/master" ]; then
    echo "${red}  cannot use rm-tree (no main/master worktree in $repo): $br -- skipped${rst}"; return 1
  fi
  if [ "$DRY_RUN" = 1 ]; then
    echo "${dim}  [dry-run] (cd $repo && rm-tree $br)${rst}"; return 0
  fi
  # NOTE: `rm-tree` exits non-zero because of its own `set -u` quirk -- after
  # the final `shift` it re-checks `[ -n "$1" ]` on an unbound `$1`. That error
  # fires *after* the worktree dir is removed and the branch deleted, so the
  # exit code is unreliable. We therefore ignore it and verify success by
  # checking that the worktree directory is actually gone.
  ( cd "$repo_dir" && rm-tree "$br" ) 2>&1 | grep -v 'unbound variable' || true
  if [ -d "$wt" ]; then
    echo "${red}  rm-tree did NOT remove $repo/$br${rst}"; return 1
  fi
  echo "${grn}  deleted $repo/$br${rst}"; return 0
}

# ---- Phase 0: scan & classify ---------------------------------------------
printf '%sScanning %s for worktrees with HEAD older than %s days...%s\n' "$bold" "$BASE" "$DAYS" "$rst"
total=0; scanned=0
for d in "$BASE"/*/*/; do
  [ -d "$d" ] || continue
  git -C "$d" rev-parse --is-inside-work-tree >/dev/null 2>&1 || continue
  total=$((total+1))
  read -r ct cs < <(git -C "$d" log -1 --format='%ct %cs' 2>/dev/null)
  [ -z "${ct:-}" ] && continue
  age=$(( (now - ct) / 86400 ))
  (( age < DAYS )) && continue
  rel=${d#"$BASE"/}; rel=${rel%/}
  repo=${rel%/*}; br=${rel##*/}
  [[ "$br" =~ $PROTECTED_RE ]] && continue          # never list master/main
  scanned=$((scanned+1))
  dirty=0; [ -n "$(git -C "$d" status --porcelain 2>/dev/null)" ] && dirty=1
  if git -C "$d" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
    ahead=$(git -C "$d" rev-list --count '@{upstream}..HEAD' 2>/dev/null); hasup=1
  else
    ahead=0; hasup=0
  fi
  if (( dirty==0 && hasup==1 && ahead==0 )); then
    printf '%s\t%s\t%s\t%s\n' "$age" "$cs" "$repo" "$br" >>"$SAFE_F"
  else
    reason=
    (( dirty ))    && reason+="uncommitted "
    (( hasup==0 )) && reason+="no-remote "
    (( ahead>0 ))  && reason+="unpushed($ahead) "
    printf '%s\t%s\t%s\t%s\t%s\n' "$age" "$cs" "$reason" "$repo" "$br" >>"$REVIEW_F"
  fi
done

n_safe=$(wc -l <"$SAFE_F" | tr -d ' ')
n_review=$(wc -l <"$REVIEW_F" | tr -d ' ')
printf '%sScanned %d worktrees, %d stale (>%dd): %s%d SAFE%s, %s%d to review%s\n\n' \
  "$bold" "$total" "$scanned" "$DAYS" "$grn" "$n_safe" "$rst$bold" "$ylw" "$n_review" "$rst"
[ "$DRY_RUN" = 1 ] && printf '%s*** DRY RUN: nothing will be deleted ***%s\n\n' "$ylw" "$rst"

# ---- Phase 1: delete SAFE worktrees ---------------------------------------
del=0; fail=0
if [ "$n_safe" -gt 0 ]; then
  printf '%s== Phase 1: SAFE to delete (clean + fully pushed) ==%s\n' "$bold" "$rst"
  sort -rn "$SAFE_F" | while IFS=$'\t' read -r age cs repo br; do
    printf '  %4sd  %s  %s/%s\n' "$age" "$cs" "$repo" "$br"
  done
  printf '\n%sDelete all %d SAFE worktrees above?%s [type "yes" to confirm] ' "$bold" "$n_safe" "$rst"
  read -r ans </dev/tty
  if [ "$ans" = "yes" ]; then
    i=0
    while IFS=$'\t' read -r age cs repo br; do
      i=$((i+1)); printf '%s[%d/%d]%s ' "$dim" "$i" "$n_safe" "$rst"
      if remove_worktree "$repo" "$br"; then del=$((del+1)); else fail=$((fail+1)); fi
    done < <(sort -rn "$SAFE_F")
  else
    echo "Skipped Phase 1."
  fi
  echo
fi

# ---- Phase 2: review the rest ---------------------------------------------
rdel=0
if [ "$n_review" -gt 0 ]; then
  printf '%s== Phase 2: review (these would LOSE work) ==%s\n' "$bold" "$rst"
  printf '%sFor each: [d]elete  [v]iew diff  [s]kip (default)  [q]uit phase%s\n\n' "$dim" "$rst"
  i=0
  while IFS=$'\t' read -r age cs reason repo br <&3; do
    i=$((i+1))
    wt="$BASE/$repo/$br"
    printf '%s---------------------------------------------------------------%s\n' "$dim" "$rst"
    printf '%s[%d/%d] %s/%s%s  %s(%sd, last commit %s)%s\n' "$bold" "$i" "$n_review" "$repo" "$br" "$rst" "$dim" "$age" "$cs" "$rst"
    printf '       reason: %s%s%s\n' "$ylw" "$reason" "$rst"
    if [ -n "$(git -C "$wt" status --porcelain 2>/dev/null)" ]; then
      printf '       %suncommitted changes:%s\n' "$cyn" "$rst"
      git -C "$wt" -c color.status=always status --short 2>/dev/null | sed 's/^/         /' | head -40
    fi
    if git -C "$wt" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
      ahead=$(git -C "$wt" rev-list --count '@{upstream}..HEAD' 2>/dev/null)
      if [ "${ahead:-0}" -gt 0 ]; then
        printf '       %s%s unpushed commit(s):%s\n' "$cyn" "$ahead" "$rst"
        git -C "$wt" log --oneline --no-decorate '@{upstream}..HEAD' 2>/dev/null | sed 's/^/         /' | head -20
      fi
    else
      printf '       %sno remote tracking branch -- recent commits:%s\n' "$cyn" "$rst"
      git -C "$wt" log --oneline --no-decorate -5 2>/dev/null | sed 's/^/         /'
    fi
    while true; do
      printf '%s   action [d/v/s/q]?%s ' "$bold" "$rst"
      read -r a </dev/tty || a=q
      case "$a" in
        d|D) if remove_worktree "$repo" "$br"; then rdel=$((rdel+1)); fi; break ;;
        v|V) git -C "$wt" diff; git -C "$wt" status --short ;;   # loops back to prompt
        q|Q) echo "Stopping review."; break 2 ;;
        *)   echo "   skipped."; break ;;
      esac
    done
  done 3< <(sort -rn "$REVIEW_F")
  echo
fi

# ---- summary ---------------------------------------------------------------
printf '%s== Done ==%s\n' "$bold" "$rst"
printf '  SAFE deleted:   %s%d%s' "$grn" "$del" "$rst"; [ "$fail" -gt 0 ] && printf '   (%s%d failed/skipped%s)' "$red" "$fail" "$rst"; echo
printf '  REVIEW deleted: %s%d%s\n' "$grn" "$rdel" "$rst"
echo
echo "Tip: confirm reclaimed space with:  df -h /System/Volumes/Data"
echo "Optional: shrink each repo's git objects with:  git -C <repo>/master gc"
