# salesforce-claude-plugin

A Claude Code plugin marketplace with skills for Salesforce development workflows.

## Structure

```
salesforce-claude-plugin/
├── .claude/
│   └── skills/
│       └── plugin-bump-version/
│           └── SKILL.md       # version/changelog workflow for PRs in this repo
├── .claude-plugin/
│   └── marketplace.json       # marketplace manifest
├── .github/
│   ├── workflows/
│   │   └── version-check.yml  # fails PRs that don't bump a changed plugin's version
│   └── scripts/
│       └── check-version-bump.sh
└── plugins/
    └── sf-core/
        ├── .claude-plugin/
        │   └── plugin.json    # plugin manifest (skills + MCP servers)
        ├── CHANGELOG.md
        └── skills/             # (empty — add real Salesforce skills here)
```

## MCP servers

`sf-core` registers the Salesforce DX MCP server (`sfdx-mcp`, via
`@salesforce/mcp`), giving Claude access to Salesforce orgs, metadata, data,
users, and testing tools through the `sf` CLI. It requires the `sf` CLI to be
installed and authenticated locally (`sf org login web`) — the server itself
is fetched on demand via `npx`.

Configured toolsets: `aura-experts`, `core`, `data`, `enrichment`,
`experts-validation`, `lwc-experts`, `metadata`, `orgs`, `scale-products`,
`testing`, `users`. Orgs are set to `ALLOW_ALL_ORGS` (any authenticated org),
and the server runs with `--no-telemetry --debug`.

> `--debug` is currently enabled for all installs of this plugin, which means
> verbose MCP server logs for every user, not just local development. Consider
> removing it from `plugins/sf-core/.claude-plugin/plugin.json` before the
> next release unless it's intentionally meant to ship.

## Usage

Add this marketplace (locally, while developing):

```bash
claude plugin marketplace add ./salesforce-claude-plugin
```

Or once pushed to a remote:

```bash
claude plugin marketplace add Yubico/salesforce-claude-plugin
```

Install the plugin:

```bash
claude plugin install sf-core@yubico-salesforce
```

## Adding a skill

Add a new directory under `plugins/sf-core/skills/<skill-name>/` containing a
`SKILL.md` with frontmatter (`name`, `description`) describing when Claude should
use it. Skills in this directory are auto-discovered — no changes to
`plugin.json` are required.
