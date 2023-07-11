---
title: Schema Tracker
description: Tracking schema changes in VStreams
aliases: []
weight: 4
aliases: ['/user-guide/update-stream', '/docs/design-docs/vreplication/vstream/tracker/']
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
For full functionality, schema tracking relies on these non-default Vitess `vttablet` flags:
[`--watch_replication_stream`](../../flags/#watch_replication_stream) and
[`--track_schema_versions`](../../flags/#track_schema_versions). Specifically, performing a vstream from a non-PRIMARY
tablet while concurrently making DDL changes to the keyspace without one or both of these tablet options could result in
incorrect vstream results.
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

#### Replication Watcher

Replication watcher is a separate vstream that is started by the tabletserver. It notifies subscribers when it encounters
a DDL in the workflow stream.

#### Version Tracker

Version tracker runs on the `PRIMARY` tablet. It subscribes to the replication watcher and inserts a new row into the
`_vt.schema_version` table with the latest schema.

#### Version Historian

Version historian runs on both `PRIMARY` and `REPLICA` tablets and handles DDL events. For a given `GTID` it looks in its
cache to check if it has a valid schema for that `GTID`. If not, it looks up the in the `schema_version` table on `REPLICA`
tablet. If no schema is found then it provides the latest schema -- which is updated by subscribing to the schema engine’s
change notification.

### Notes

- Schema Engine is an existing service
- Replication Watcher is used as an optional vstream that the user can run. It doesn’t do anything user specific: it is only
used for the side-effect that a vstream loads the schema on a DDL to proactively load the latest schema

## Basic Flow for Version Tracking

### Primary

#### Version Tracker:

1. When the primary comes up the replication watcher (a vstream) is started from the current `GTID` position. The
tracker subscribes to the watcher.
1. Say, a DDL is applied
1. The watcher vstream sees the DDL and
1. Asks the schema engine to reload the schema, also providing the corresponding `GTID` position
1. Notifies the tracker of a schema change
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

Schema version snapshots are stored only on the `PRIMARY`. This is done when the Replication Watcher gets a DDL event
resulting in a `SchemaUpdated()` call. There are two independent flows here:

1. Replication Watcher is running
2. Schema snapshots are saved to `_vt.schema_version` when `SchemaUpdated()` is called

Point 2 is performed only when the [`--track_schema_versions`](../../flags/#track_schema_versions) `vttablet` flag is enabled.
This implies that #1 also has to happen when [`--track_schema_versions`](../../flags/#track_schema_versions) is enabled
independently of the [`--watch_replication_stream`](../../flags/#watch_replication_stream) flag.

However if the [`--watch_replication_stream`](../../flags/#watch_replication_stream) flag is enabled but
[`--track_schema_versions`](../../flags/#track_schema_versions) is disabled we still need to run the Replication
Watcher since the user has requested it, but we do not store any schema versions.

So the logic is:

1. WatchReplication==true \
   => Replication Watcher is running

2. TrackSchemaVersions==false  
   => SchemaUpdated is a noop

3. TrackSchemaVersions=true  
   => Replication Watcher is running \
   => SchemaUpdated is handled

The historian behavior is identical to that of the replica: of course if versions are not stored in `_vt.schema_versions`
it will always provide the latest version of the schema.

### Replica

Schema versions are never stored directly on `REPLICA` tablets, so SchemaUpdated is always a noop. Versions are provided
as appropriate by the historian. The historian provides the latest schema if there is no appropriate version.

So the logic is:

1. WatchReplication==true \
   => Replication Watcher is running

2. TrackSchemaVersions==false || true //noop \
   => Historian tries to get appropriate schema version

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
