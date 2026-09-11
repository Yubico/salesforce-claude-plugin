# SOQL & search patterns for the flow deprecation review

All queries below run through `run_soql_query` with `useToolingApi: true`
unless noted otherwise, since `Flow`, `FlowDefinition`, and
`MetadataComponentDependency` are Tooling API-only objects.

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

## Structured dependency check

```sql
SELECT MetadataComponentId, MetadataComponentName, MetadataComponentType,
       RefMetadataComponentId, RefMetadataComponentName, RefMetadataComponentType
FROM MetadataComponentDependency
WHERE RefMetadataComponentName = '<flowApiName>'
  AND RefMetadataComponentType = 'Flow'
```

Returns every component that formally references the flow (Apex classes
calling it as an invocable action, other Flows via Subflow, Quick Actions,
Workflow Rules/Process Builder flows, etc.). Not every org/edition has this
object populated — if the query errors or returns nothing where you'd expect
hits, fall back to the static search below and say so in the report rather
than reporting a false "no dependencies."

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

## Static source fallback (grep)

After `retrieve_metadata` has pulled a local copy, search across it for the
flow's API name as a plain string:

```bash
grep -rl "<flowApiName>" \
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
