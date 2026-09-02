---
name: plugin-bump-version
description: Use before opening or updating a PR in this repo that touches files under plugins/. Reviews the diff scope, decides whether the change is a patch or a release, bumps the affected plugin's version in plugin.json and its marketplace.json entry, and writes release notes to the plugin's CHANGELOG.md. Every PR that changes plugin content must bump the version — CI enforces this.
---

# Plugin Version Bump

Every PR that changes files under `plugins/<plugin-name>/` must bump that plugin's
version, or CI (`.github/workflows/version-check.yml`) will fail the PR. Users only
discover plugin updates and what changed when the version number moves.

## 1. Find the scope of changes

Diff against the PR base branch (usually `main`):

```bash
git diff main...HEAD -- plugins/
```

Identify every `plugins/<name>/` directory touched. If more than one plugin
changed, handle each independently — each gets its own version decision and
changelog entry.

## 2. Classify the change

For each changed plugin, decide:

**Patch (`x.y.Z` → `x.y.(Z+1)`)** — bump the last number by 0.0.1. Use for:
- Bug fixes or corrections to existing skill/command/agent content
- Wording, formatting, or doc-only edits
- Non-functional refactors (no behavior change)
- Small additions that don't change what the skill covers (e.g. an extra example)

**Release (`x.Y.z` → `x.(Y+1).0`)** — bump the middle number by 0.1 and reset the
patch number to 0. Use for:
- A new skill, command, agent, or hook added
- An existing skill's scope, trigger conditions, or behavior meaningfully changed
- Anything a user of the plugin would want to know about (changelog-worthy)

If unsure, prefer release over patch — the goal is that users notice meaningful
changes, not that the number stays small.

## 3. Bump the version

Update two files to the identical new version:
- `plugins/<name>/.claude-plugin/plugin.json` — the `version` field
- `.claude-plugin/marketplace.json` — the matching entry in `plugins[]` — its
  `version` field

Keep these two in sync. CI only checks `plugin.json`, but a mismatch confuses
version pinning for anyone installing via the marketplace.

## 4. Write release notes

Add an entry to `plugins/<name>/CHANGELOG.md` (create it if it doesn't exist yet)
at the top, above any prior entries:

```markdown
## <new-version> - <YYYY-MM-DD>

- <one bullet per meaningful change, written for someone installing the plugin>
```

Base the bullets on the actual diff content, not file names — describe what
changed in the skill's behavior or coverage (e.g. "Added a skill for validating
package.xml before deploy"), not "updated SKILL.md".

## 5. Verify before opening the PR

- [ ] `plugin.json` version bumped and is valid semver, strictly greater than before
- [ ] `marketplace.json` plugin entry version matches `plugin.json`
- [ ] `CHANGELOG.md` has a new entry describing the change
