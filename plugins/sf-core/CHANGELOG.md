# Changelog

All notable changes to the `sf-core` plugin are documented here.

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
