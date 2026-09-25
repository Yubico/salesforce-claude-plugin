# SOQL & search patterns for the flow deprecation review

All queries below run through `run_soql_query` with `useToolingApi: true`
unless noted otherwise, since `Flow` and `FlowDefinition` are Tooling
API-only objects.

## Flow family / activation state

```sql
SELECT Id, DeveloperName, MasterLabel, NamespacePrefix,
       ActiveVersionId, LatestVersionId
FROM FlowDefinition
ORDER BY DeveloperName
```

`ActiveVersionId = null` means the entire flow family currently has no active
version — treat that as a bigger decision than a single stale version (see
SKILL.md step 3/7; never auto-default `Outcome` in that case).

## Version history

```sql
SELECT Id, DefinitionId, MasterLabel, VersionNumber, Status, ProcessType,
       ApiVersion, CreatedDate, CreatedBy.Name, LastModifiedDate,
       LastModifiedBy.Name
FROM Flow
ORDER BY DefinitionId, VersionNumber
```

Join in memory on `Flow.DefinitionId = FlowDefinition.Id`. A version is a
candidate when `Status != 'Active'` and `LastModifiedDate` is older than the
12-month cutoff computed from the run time.

To pull just one flow's history once you know its `DeveloperName`, filter via
its `FlowDefinition.Id`:

```sql
SELECT Id, VersionNumber, Status, ProcessType, CreatedDate, CreatedBy.Name,
       LastModifiedDate, LastModifiedBy.Name
FROM Flow
WHERE DefinitionId = '<flowDefinitionId>'
ORDER BY VersionNumber
```

## Admin/deploy activity heuristic

```sql
SELECT Action, Section, Display, CreatedDate, CreatedBy.Name
FROM SetupAuditTrail
WHERE Display LIKE '%<flowApiNameOrLabel>%'
ORDER BY CreatedDate DESC
LIMIT 50
```

`SetupAuditTrail` only retains a rolling window (varies by org, typically
6 months), so a miss here doesn't prove nothing recent happened — treat it as
corroborating evidence, not proof.

## Static source search (grep)

Note: an earlier version of this skill also queried
`MetadataComponentDependency` (Tooling API) as a structured check before
falling back to this grep. That query has been dropped — it reliably
returned zero rows for Flow references across every org this skill has been
run against, so this static search is now the sole dependency check.

After `retrieve_metadata` has pulled a local copy, search across it for the
flow's API name:

```bash
grep -rlE "(^|[^A-Za-z0-9_])<flowApiName>([^A-Za-z0-9_]|$)" \
  force-app/main/default/classes \
  force-app/main/default/triggers \
  force-app/main/default/flows \
  force-app/main/default/quickActions \
  force-app/main/default/objects/*/webLinks \
  force-app/main/default/approvalProcesses \
  force-app/main/default/flexipages \
  force-app/main/default/lwc \
  force-app/main/default/aura \
  2>/dev/null
```

Do **not** use a plain substring match (`grep -rl "<flowApiName>"`) or `grep
-w` — flow API names use underscores, which count as "word" characters, so
neither approach stops one flow's name from matching inside a longer flow
name that has it as a prefix (e.g. searching for `Account_Creation` would
also match every occurrence of `Account_Creation_Shipping_Address_Same_as_Billing`,
producing a false-positive dependency hit). The `(^|[^A-Za-z0-9_])...([^A-Za-z0-9_]|$)`
pattern explicitly requires a non-identifier character (or line start/end) on
both sides of the match.

Adjust the paths to match the project's actual `sfdx-project.json` package
directories. For custom buttons/web links specifically, also check the `<url>`
field for a literal `/flow/<flowApiName>` path — those don't always show up
as a plain text match if the button builds the URL dynamically.

## Object / trigger context

The record-triggered object isn't exposed cleanly via Tooling API fields on
`Flow`/`FlowDefinition`. Read it from the retrieved `<DeveloperName>.flow-meta.xml`
instead:

- Record-triggered flows: `<start><object>ObjectApiName</object></start>`
- Screen/autolaunched flows with no record context: no `<object>` element —
  report `N/A`.
