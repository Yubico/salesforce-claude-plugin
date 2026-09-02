#!/usr/bin/env bash
# Fails if any plugin whose files changed in this PR did not get its
# plugins/<name>/.claude-plugin/plugin.json "version" bumped to a strictly
# greater semver value compared to the base ref.
set -uo pipefail

BASE_REF="${1:-origin/main}"
fail=0

changed_plugin_dirs=$(git diff --name-only "$BASE_REF"...HEAD -- 'plugins/*' | awk -F/ '{print $1"/"$2}' | sort -u)

if [ -z "$changed_plugin_dirs" ]; then
  echo "No plugin files changed; skipping version check."
  exit 0
fi

for dir in $changed_plugin_dirs; do
  plugin_json="$dir/.claude-plugin/plugin.json"

  if [ ! -f "$plugin_json" ]; then
    continue
  fi

  new_version=$(jq -r '.version // empty' "$plugin_json")
  old_version=$(git show "$BASE_REF:$plugin_json" 2>/dev/null | jq -r '.version // empty')

  if [ -z "$old_version" ]; then
    echo "✓ $dir is a new plugin; skipping version comparison."
    continue
  fi

  if [ -z "$new_version" ]; then
    echo "✗ $dir: plugin.json has no version field."
    fail=1
    continue
  fi

  if python3 -c "
import sys
old = tuple(int(p) for p in sys.argv[1].split('.'))
new = tuple(int(p) for p in sys.argv[2].split('.'))
sys.exit(0 if new > old else 1)
" "$old_version" "$new_version"; then
    echo "✓ $dir: version bumped $old_version -> $new_version."
  else
    echo "✗ $dir: version was not bumped ($old_version -> $new_version). Every PR that changes a plugin must bump its version in plugin.json (patch: +0.0.1, release: +0.1.0). See the plugin-bump-version skill."
    fail=1
  fi
done

exit $fail
