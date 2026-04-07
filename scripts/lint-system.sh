#!/usr/bin/env bash
set -euo pipefail

# A Player OS — Cross-repo terminology lint
# Reads system.json, clones all repos, checks for deprecated terms.
# Run from the os repo root.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SYSTEM_JSON="$REPO_DIR/system.json"
WORK_DIR=$(mktemp -d)

trap 'rm -rf "$WORK_DIR"' EXIT

if [ ! -f "$SYSTEM_JSON" ]; then
  echo "  ERROR: system.json not found at $SYSTEM_JSON"
  exit 1
fi

echo ""
echo "  A Player OS — System Lint"
echo "  ========================="
echo ""

# --- Read repos from system.json ---

REPOS=$(python3 -c "
import json
with open('$SYSTEM_JSON') as f:
    data = json.load(f)
repos = [data['system']['repo']]
for stage in data['stages'].values():
    repos.append(stage['repo'])
for r in repos:
    print(r)
")

# --- Read deprecated terms from system.json ---

DEPRECATED_EXACT=$(python3 -c "
import json
with open('$SYSTEM_JSON') as f:
    data = json.load(f)
for d in data.get('deprecated', []):
    print(d['term'] + '|||' + d['replacement'])
")

DEPRECATED_WORDS=$(python3 -c "
import json
with open('$SYSTEM_JSON') as f:
    data = json.load(f)
for d in data.get('deprecated_words', []):
    wl = '|'.join(d.get('whitelist', []))
    print(d['term'] + '|||' + d['replacement'] + '|||' + wl)
")

# --- Clone repos ---

echo "  Cloning repos..."
CLONED_DIRS=""
for repo in $REPOS; do
  name=$(echo "$repo" | cut -d/ -f2)
  target="$WORK_DIR/$name"

  if git clone --depth 1 "https://github.com/$repo.git" "$target" 2>/dev/null; then
    echo "  OK    $repo"
    CLONED_DIRS="$CLONED_DIRS $target"
  else
    echo "  SKIP  $repo (not found or private)"
  fi
done
echo ""

# --- Collect files to check ---

FILES=""
for dir in $CLONED_DIRS; do
  found=$(find "$dir" \
    -type f \( -name "*.md" -o -name "setup" -o -name "*.sh" -o -name "*.json" \) \
    -not -path "*/.git/*" \
    -not -path "*/node_modules/*" \
    -not -name "system.json" \
    -not -name "GLOSSARY.md" \
    -not -name "lint-system.sh" \
    -not -name "lint-terminology.sh" \
    -not -name "lint-terminology.yml" \
    -not -name "package-lock.json" \
    2>/dev/null || true)
  FILES="$FILES $found"
done

# Strip "What we don't say" sections from ARCHITECTURE.md files
CLEAN_FILES=""
for f in $FILES; do
  if [[ "$(basename "$f")" == "ARCHITECTURE.md" ]]; then
    clean=$(mktemp)
    sed '/^### What we don.t say/,/^##[^#]/{ /^##[^#]/!d; }' "$f" > "$clean"
    CLEAN_FILES="$CLEAN_FILES $clean"
  else
    CLEAN_FILES="$CLEAN_FILES $f"
  fi
done

ERRORS=0
TOTAL_HITS=0

# --- Check exact deprecated terms ---

echo "  Checking deprecated terms..."
echo ""

while IFS='|||' read -r term replacement; do
  [ -z "$term" ] && continue

  matches=$(grep -rn "$term" $CLEAN_FILES 2>/dev/null | grep -v "never \"" | grep -v "~~" | grep -v "stands alone" || true)

  if [ -n "$matches" ]; then
    hit_count=$(echo "$matches" | wc -l | tr -d ' ')
    TOTAL_HITS=$((TOTAL_HITS + hit_count))
    ERRORS=$((ERRORS + 1))

    # Show repo-relative paths
    echo "  FAIL  \"$term\" → \"$replacement\" ($hit_count hits)"
    echo "$matches" | while read -r line; do
      # Strip the temp dir prefix to show repo name
      clean_line=$(echo "$line" | sed "s|$WORK_DIR/||")
      echo "         $clean_line"
    done
    echo ""
  fi
done <<< "$DEPRECATED_EXACT"

# --- Check deprecated words (with whitelist) ---

while IFS='|||' read -r term replacement whitelist; do
  [ -z "$term" ] && continue

  # Build grep exclude pattern from whitelist
  # Split on | and build a case-insensitive exclude chain
  if [ -n "$whitelist" ]; then
    exclude_cmd="cat"
    IFS='|' read -ra WL_ITEMS <<< "$whitelist"
    for wl_item in "${WL_ITEMS[@]}"; do
      [ -z "$wl_item" ] && continue
      exclude_cmd="$exclude_cmd | grep -vi \"$wl_item\""
    done
    matches=$(grep -wniE "\b${term}(s)?\b" $CLEAN_FILES 2>/dev/null \
      | grep -v "\\*\\*Loop\\*\\*" \
      | eval "$exclude_cmd" || true)
  else
    matches=$(grep -wniE "\b${term}(s)?\b" $CLEAN_FILES 2>/dev/null || true)
  fi

  if [ -n "$matches" ]; then
    hit_count=$(echo "$matches" | wc -l | tr -d ' ')
    TOTAL_HITS=$((TOTAL_HITS + hit_count))
    ERRORS=$((ERRORS + 1))

    echo "  FAIL  \"$term\" → \"$replacement\" ($hit_count hits)"
    echo "$matches" | head -10 | while read -r line; do
      clean_line=$(echo "$line" | sed "s|$WORK_DIR/||")
      echo "         $clean_line"
    done
    [ "$hit_count" -gt 10 ] && echo "         ... and $((hit_count - 10)) more"
    echo ""
  fi
done <<< "$DEPRECATED_WORDS"

# --- Cross-reference check: do all repos link to the OS repo? ---

echo "  Checking cross-references..."
OS_URL=$(python3 -c "import json; print(json.load(open('$SYSTEM_JSON'))['system']['url'])")
XREF_WARNINGS=0

for dir in $CLONED_DIRS; do
  name=$(basename "$dir")
  [ "$name" = "os" ] && continue

  readme="$dir/README.md"
  if [ -f "$readme" ]; then
    if ! grep -q "$OS_URL\|aplayerlabs/os" "$readme" 2>/dev/null; then
      echo "  WARN  $name/README.md — no link to A Player OS"
      XREF_WARNINGS=$((XREF_WARNINGS + 1))
    fi
  fi
done
echo ""

# --- Summary ---

echo "  ---"
if [ "$ERRORS" -eq 0 ] && [ "$XREF_WARNINGS" -eq 0 ]; then
  echo "  PASS  All repos clean. Zero deprecated terms. All cross-references present."
else
  [ "$ERRORS" -gt 0 ] && echo "  ERRORS:   $ERRORS deprecated pattern(s), $TOTAL_HITS total hits"
  [ "$XREF_WARNINGS" -gt 0 ] && echo "  WARNINGS: $XREF_WARNINGS repo(s) missing link to A Player OS"
fi

echo ""
exit "$ERRORS"
