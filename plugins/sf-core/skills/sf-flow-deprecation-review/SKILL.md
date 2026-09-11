---
name: sf-flow-deprecation-review
description: Use when asked to audit, review, or clean up Salesforce Flows for deprecation/retirement — e.g. "flow deprecation review", "find unused/inactive flows", "which flows are safe to delete", "flow cleanup audit". Pulls all flows and flow versions from a production org, flags versions that are inactive and unmodified for 12+ months, checks Apex/button/quick-action/integration dependencies via the Tooling API plus static source search, and produces a sign-off report table (Outcome column: Safe to Delete / Requires Owner Confirmation / Excluded / Deferred). This skill only reports — it never deactivates or deletes anything.
---

# Salesforce Flow Deprecation Review

Produces a report identifying Flow versions that are likely safe to delete, for a
human owner to confirm. This skill is **read-only** — it never deactivates,
deletes, or modifies any org metadata. All destructive action happens later,
manually, by the org owner, based on the report's `Outcome` column.

Use the `sfdx-mcp` tools (`get_username`, `list_all_orgs`, `run_soql_query`,
`retrieve_metadata`) for all org interaction. See `reference/soql-queries.md`
for the exact SOQL and grep patterns used in steps 3–6.

## 0. Resolve the target org

Ask the user for the production org alias/username if it isn't already clear —
never guess it. Use `get_username` to resolve an alias if the user gives one
that doesn't look like a full username.

Before proceeding, confirm with the user that this is genuinely production (not
a sandbox), since the report is only meaningful against real usage data. If
`list_all_orgs` or the org's `IsSandbox`/instance info suggests otherwise,
flag the mismatch and ask before continuing.

## 1. Pull the latest flow metadata

Retrieve all Flow metadata from the org into the local project so there's a
current, reviewable copy on disk (this is the "pull the latest copy" step, and
also gives you local `.flow-meta.xml` files to grep in step 5):

Use `retrieve_metadata` with a manifest targeting `Flow` with wildcard members
(`<members>*</members>`, type `Flow`). If the user already has a `Flow`
directory retrieved locally and just wants a refresh, pass `sourceDir`
pointing at it instead so `sf` recalculates what changed.

Note: source retrieval by default returns the **active or latest** version
per flow, not full version history as separate files — that's expected. Full
version history (every version, its status, and its last-modified metadata)
comes from the Tooling API queries in the next step, not from the retrieved
files.

## 2. Build the full flow + version inventory

Run the `FlowDefinition` and `Flow` Tooling API queries in
`reference/soql-queries.md` (`useToolingApi: true`) against the target org.
This gives you, per `FlowDefinition` (the flow "family"): whether it currently
has an active version (`ActiveVersionId`), and every version's `VersionNumber`,
`Status`, `ProcessType`, `CreatedDate`/`CreatedBy`, and
`LastModifiedDate`/`LastModifiedBy`.

## 3. Filter to candidate versions

Compute a 12-months-ago cutoff date from the current run time. A version is a
**candidate** for this review if both are true:

- `Status != 'Active'` for that version
- `LastModifiedDate` is older than the 12-month cutoff

For each candidate, also record whether its **parent FlowDefinition currently
has an active version** (`ActiveVersionId IS NOT NULL`, and not equal to this
candidate version's own Id). This flag matters for the `Outcome` default in
step 7 — it distinguishes "this old version is dead weight next to a live
version" from "this entire flow appears fully retired," which is a bigger
decision than a version cleanup and should never be auto-defaulted.

## 4. Technical dependency check

For each candidate flow's API name (`DeveloperName`), check whether anything
still invokes it:

1. **Structured check** — query `MetadataComponentDependency` (Tooling API,
   see reference doc) filtered on the flow as the referenced component. This
   surfaces Apex classes/triggers, other Flows (subflow calls), Quick Actions,
   Workflow Rules, and other components with a formal metadata dependency.
2. **Static fallback** — grep the locally retrieved metadata (Apex classes/
   triggers, LWC, Aura, other Flow XML, Quick Actions, Custom Buttons/Web
   Links, Approval Processes, FlexiPages) for the flow's API name. This catches
   references the dependency API misses — most notably custom buttons/links
   that invoke a flow by URL, and formula-built flow finish URLs.
3. **Not fully automatable** — external integration calls (REST/SOAP
   invocations of an autolaunched flow, External Services, scheduled/batch
   triggers configured outside metadata) can't be verified from metadata
   alone. Say so explicitly in the report rather than assuming "not invoked."

Populate the `Dependencies` column with what was found (component type +
name), or `"None found (structured + static search)"` if both checks came back
empty — never claim "no dependencies" without qualifying how that was checked.

## 5. Deployment / package / admin reliance check

- If `FlowDefinition.NamespacePrefix` is populated, the flow belongs to a
  managed/unlocked package — do not treat it as a deletion candidate; note
  this in the report and steer its `Outcome` toward `Excluded`.
- Query `SetupAuditTrail` (see reference doc) for recent entries mentioning
  the flow's name, as a heuristic for recent admin/deploy activity that
  wouldn't otherwise show up as a `LastModifiedDate` change.
- Ask the user if the org maintains any admin-owned registry (custom
  metadata/custom setting, CI/CD manifest, deployment pipeline config) that
  might reference flow API names — this skill can't discover systems it isn't
  told about.

## 6. Business process check

Best-effort only — this is a business judgment call, not something metadata
can confirm on its own:

- If Atlassian/Confluence or Jira tools are connected, search for the flow's
  label and API name to see if there's a related retirement/replacement
  ticket or documentation page. Cite what you find (ticket/page link).
- If nothing turns up, write `"No linked documentation found — manual
  confirmation needed"` rather than guessing the process is retired.

Put this in its own **Business Process Check** column, separate from
`Dependencies` — it answers "should this still exist" rather than "does
anything still call it."

## 7. Build the report

Render a single Markdown table, one row per candidate flow version, with
exactly these columns:

`Name | Api Name | Version | Status | Last Modified Date | Last Modified By | Created By | Created Date | Type | Object | Dependencies | Business Process Check | Outcome`

- **Type** — the version's `ProcessType` (e.g. `AutoLaunchedFlow`, `Flow`,
  `Workflow` for Process Builder).
- **Object** — the primary object from the flow's `<start>`/trigger
  definition in the retrieved XML; `N/A` for flows with no object (e.g.
  screen flows not tied to a record).
- **Outcome** — leave **blank** by default. Auto-fill `"Safe to delete"`
  *only* when **all** of these hold:
  - the version is inactive and unmodified for 12+ months (step 3), **and**
  - its FlowDefinition has a currently active *different* version (step 3's
    flag), **and**
  - no dependencies were found in step 4, **and**
  - it isn't packaged/flagged in step 5.

  In every other case — including a flow whose FlowDefinition has *no* active
  version at all — leave `Outcome` blank for the reviewer to assign one of
  the four values in the legend below.

### Report header (above the table)

```
Flow Deprecation Review
Run Time: <YYYY-MM-DD>, <IANA/local timezone>
Run Environment: <org alias> (<username>, production)
Created By: <name/email of the person who requested this review>
```

Get the timezone from the local system clock unless the user specifies one.
For "Created By," ask the user if it isn't already established in the
conversation — don't assume it's the Salesforce running user.

### Report footer (below the table)

Append exactly this instructional block, verbatim:

```
Each reviewed item should be assigned one of the following outcomes:

Safe to Delete — no active dependency and no known business need

Requires Owner Confirmation — likely inactive, but ownership or usage is unclear

Excluded — should remain in place, with a documented reason

Deferred — not ready for deletion in the current quarter, but should be reviewed again
```

## 8. Deliver the report

Show the table in chat, and ask whether the user wants it saved to a file
(e.g. `flow-deprecation-review_<org-alias>_<YYYY-MM-DD>.md` in the current
project directory). Don't write files into the plugin/skill directory itself.

Remind the user this is an analysis artifact only — no flow was deactivated
or deleted as part of producing it.
