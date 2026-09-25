# Changelog

All notable changes to the `sf-core` plugin are documented here.

## 0.6.0 - 2026-09-25

- `sf-flow-deprecation-review`: simplified the sign-off outcome legend from
  four values down to two — `Safe to Delete` / `Keep` — and fixed the
  `"Safe to delete"` vs. `"Safe to Delete"` casing mismatch between the
  auto-fill logic and the legend.
- Fixed the frontmatter `description` field, which was invalid YAML (an
  unquoted plain scalar containing a bare `:`) and failed to parse on
  GitHub's stricter renderer.
- Fixed the structured `MetadataComponentDependency` dependency check:
  `RefMetadataComponentName` is not a filterable field in every org's API
  version; the query now filters only on `RefMetadataComponentType = 'Flow'`
  once and matches by name in memory, instead of one query per candidate flow.
- Fixed the static-search grep pattern, which was a plain substring match and
  produced false-positive dependency hits when one flow's API name is a
  prefix of another's; it now requires identifier boundaries.
- Step 9 (deliver the report) now caps the in-chat Markdown table at ~100
  rows, above which it summarizes (flagged rows in full, the rest as counts)
  and points to the xlsx instead of pasting an unreadable wall of text.
- The "external integrations can't be verified" caveat is now stated once on
  the Information sheet instead of repeated in every row's `Dependencies` cell.

## 0.5.0 - 2026-09-18

- `sf-flow-deprecation-review` now delivers its output as a two-sheet Excel
  (`.xlsx`) workbook instead of a Markdown file: a `Review` sheet with the
  per-flow-version data table, and an `Information` sheet holding the run
  metadata and outcome legend that previously appeared as the report's
  header/footer.

## 0.4.0 - 2026-09-11

- Added the `sf-flow-deprecation-review` skill: pulls all Flows and Flow
  versions from a production org, flags versions that are inactive and
  unmodified for 12+ months, checks Apex/button/quick action/integration
  dependencies via the Tooling API plus a static source search, and produces
  a sign-off report (Safe to Delete / Requires Owner Confirmation / Excluded /
  Deferred) for a human to confirm before any cleanup.

## 0.3.0 - 2026-09-08

- Added the `atlassian-mcp` MCP server (`https://mcp.atlassian.com/v1/sse`),
  giving Claude access to JIRA and Confluence via the Atlassian Rovo MCP.

## 0.2.0 - 2026-09-02

- Added the `sfdx-mcp` MCP server (`@salesforce/mcp`), giving Claude access to
  Salesforce orgs, metadata, data, users, and testing toolsets across all
  authenticated `sf` CLI orgs (`ALLOW_ALL_ORGS`).
- Removed the placeholder `example-skill`.

## 0.1.0 - 2026-09-02

- Initial plugin scaffold with a placeholder `example-skill`.
