---
title: Schema Tracker
description: Tracking schema changes in VStreams
weight: 76
aliases: ['/user-guide/update-stream', '/docs/design-docs/vreplication/vstream/tracker/', '/docs/24.0/reference/vreplication/internal/tracker/']
---

# Tracking Schema Changes in VStreams

## Motivation

Currently, vstreams work with a single (the latest or current) database schema. On every DDL the schema engine reloads the
schema from the database engine.

All vstreams on a tablet share a common schema engine. VStreams that are lagging can see a more recent schema than when
the older binlog events occurred. So the lagging vstreams will see an incorrect version of the schema in case DDLs were
applied in between that affect the schema of the tables involved in those lagging events.

In addition, reloading schemas is an expensive operation. If there are multiple vstreams them each of them will separately
receive a DDL event resulting in multiple reloads for the same DDL.

{{< info >}}
For full functionality, schema tracking requires the [`--track-schema-versions`](../../flags/#track-schema-versions) `vttablet` flag. Without this flag, streaming from a non-PRIMARY tablet while DDL changes are being made to the keyspace could produce incorrect results.
{{< /info >}}

## Goals

1. Provide a mechanism for maintaining versions of the schema
2. Reduce the number of redundant schema loads

## Model

We add a new `schema_version` table in the internal `_vt` database with columns, including, the `GTID` position, the
schema as of that position, and the DDL that led to this schema. Inserting into this table generates a `version` event
in the vstream.

## Actors

#### Schema Engine

Schema engine gets the schema from the database and only keeps the last (latest) copy it loaded. It notifies subscribers
if the schema changes. It polls for the latest schema at intervals or can be explicitly requested to load the schema for
a tablet using the [`ReloadSchemaKeyspace`](../../../programs/vtctl/schema-version-permissions/#reloadschemakeyspace)
vtctl client command.

#### Version Tracker

Version tracker runs on the `PRIMARY` tablet. It monitors the replication stream for DDL events and inserts a new row into the
`_vt.schema_version` table with the latest schema.

#### Version Historian

Version historian runs on both `PRIMARY` and `REPLICA` tablets and handles DDL events. For a given `GTID` it looks in its
cache to check if it has a valid schema for that `GTID`. If not, it looks up the in the `schema_version` table on `REPLICA`
tablet. If no schema is found then it provides the latest schema -- which is updated by subscribing to the schema engine’s
change notification.

### Notes

- Schema Engine is an existing service

## Basic Flow for Version Tracking

### Primary

#### Version Tracker:

1. When the primary comes up, a vstream is started from the current `GTID` position to monitor replication events
1. Say, a DDL is applied
1. The vstream sees the DDL and asks the schema engine to reload the schema, providing the corresponding `GTID` position
1. The tracker is notified of the schema change
1. Tracker stores its latest schema into the `_vt.schema_version` table associated with the given `GTID` and DDL

#### Historian/VStreams:

1. Historian warms its cache from the `_vt.schema_version` table when it starts
2. When the tracker inserts the latest schema into `_vt.schema_version` table, the vstream converts it into a (new)
   version event
3. For every version event the vstream registers it with the historian
4. On the version event, the tracker loads the new row from the `_vt.schema_version` table
5. When a vstream needs a new `TableMap` event it asks the historian for it along with the corresponding `GTID`
6. Historian looks in its cache for a schema version for that `GTID`. If not present it provides the latest schema it
   has received from the schema engine

#### Replica

1. Version tracker does not run: the tracker can only store versions on the `PRIMARY` since it requires writing to the
database
2. Historian functionality is identical to that on the `PRIMARY`

## Flags

### Primary

Schema version snapshots are stored only on the `PRIMARY` tablet. When a DDL event is detected, it triggers a `SchemaUpdated()` call.

When the [`--track-schema-versions`](../../flags/#track-schema-versions) `vttablet` flag is enabled:
- The replication stream is monitored for DDL events automatically
- Schema snapshots are saved to `_vt.schema_version` when DDLs are detected

The historian behaves the same as on replicas: if no versions are stored in `_vt.schema_versions`, it provides the latest schema.

You can use [`--schema-version-max-age-seconds`](../../flags/#schema-version-max-age-seconds) to periodically purge older schema version records from memory. This does not remove the rows stored in the database.

### Replica

`REPLICA` tablets never store schema versions directly, so `SchemaUpdated` is always a noop. The historian provides the appropriate schema version when available, falling back to the latest schema otherwise.

## Caveat

Only best-effort versioning can be provided due to races between DDLs and DMLs. Some examples below:

### Situation 1

If multiple DDLs are applied in a quick sequence we can end up with the following binlog scenario:

```text
T1: DDL 1 on table1

T2: DDL 2 on table1

T3: Version Event DDL1 // gets written because of the time taken by tracker processing DDL1

T4: DML1 on table1

T5: Version Event DDL2 // gets written AFTER DML1
```

</br>

So now on the `REPLICA`, at T4, the version historian will incorrectly provide the schema from T1 after DDL1 was applied.

### Situation 2

If version tracking is turned off on the `PRIMARY` for some time, correct versions may not be available to the historian
which will always return the latest schema. This might result in an incorrect schema when a vstream is processing events
in the past.

#### Possible New Features Around This Functionality

- Schema tracking vstream client for notifications of all ddls
- Raw history of schema changes for auditing, root cause analysis, etc.
