# Changelog

All notable changes to the `sf-core` plugin are documented here.

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
