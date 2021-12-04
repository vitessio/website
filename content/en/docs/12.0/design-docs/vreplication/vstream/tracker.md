---
title: Schema Tracker
description: Tracking schema changes in Vstreams
aliases: ["/user-guide/update-stream"]
weight: 1
---

# Tracking schema changes in Vstreams

## Motivation

Currently, Vstreams work with a single (the latest) database schema. On every DDL the schema engine reloads the schema from the database engine.

All Vstreams on a tablet share a common engine. Vstreams that are lagging might be seeing a newer (and hence incorrect) version of the schema in case ddls were applied in between.

In addition reloading schemas is an expensive operation. If there are multiple Vstreams each of them will separately receive a DDL event resulting in multiple reloads for the same DDL.

{{< info >}}
For full functionality, schema tracking relies on non-default Vitess vttablet options: `-watch_replication_stream` and `-track_schema_versions`. Specifically, performing a Vstream from a non-primary tablet while concurrently making DDL changes to the keyspace without one or both of these tablet options will result in incorrect Vstream results.
{{< /info >}}

## Goals

1. Provide a mechanism for maintaining versions of the schema
2. Reduce the number of redundant schema loads

## Model

We add a new schema_version table in \_vt with columns, including, the gtid position, the schema as of that position, and the ddl that led to this schema. Inserting into this table generates a Version event in Vstream.

## Actors

#### Schema Engine

Schema engine gets the schema from the database and only keeps the last (latest) copy it loaded. It notifies subscribers if the schema changes. It polls for the latest schema at intervals or can be explicitly requested to load the schema.

#### Replication watcher

Replication watcher is a Vstream that is started by the tabletserver. It notifies subscribers when it encounters a DDL

#### Version Tracker

Version tracker runs on the primary. It subscribes to the replication watcher and inserts a new row into the schema_version table with the latest schema.

#### Version Historian

Version historian runs on both primary and replica and handles DDL events. For a given GTID it looks up its cache to check if it has a schema valid for that GTID. If not, on the replica, it looks up the schema_version table. If no schema is found then it provides the latest schema which is updated by subscribing to the schema engine’s change notification.

### Notes

- Schema Engine is an existing service
- Replication Watcher already exists and is used as an optional Vstream that the user can run. It doesn’t do anything specific: it is used for the side-effect that a Vstream loads the schema on a DDL, to proactively load the latest schema.

## Basic Flow for version tracking

### Primary

#### Version tracker:

1. When the primary comes up the replication watcher (a Vstream) is started from the current GTID position. Tracker subscribes to the watcher.
1. Say, a DDL is applied
1. The watcher Vstream sees the DDL and
   1. asks the schema engine to reload the schema, also providing the corresponding gtid position
   2. notifies the tracker of a schema change
1. Tracker stores its latest schema into the \_vt.schema_version table associated with the given GTID and DDL

#### Historian/Vstreams:

1. Historian warms its cache from the schema_version table when it loads
2. When the tracker inserts the latest schema into \_vt.schema_version table, the Vstream converts it into a (new) Version event
3. For every Version event the Vstream registers it with the Historian
4. On the Version event, the tracker loads the new row from the \_vt.schema_version table
5. When a Vstream needs a new TableMap it asks the Historian for it along with the corresponding GTID.
6. Historian looks up its cache for a schema version for that GTID. If not present just provides the latest schema it has received from the schema engine.

#### Replica

1. Version tracker does not run: the tracker can only store versions on the primary since it is writing to the database.
2. Historian functionality is identical to that on the primary.

## Flags

### Primary

Schema version snapshots are stored only on the primary. This is done when the Replication Watcher gets a DDL event resulting in a SchemaUpdated(). There are two independent flows here:

1. Replication Watcher is running
2. Schema snapshots are saved to \_vt.schema_version when SchemaUpdated is called

Point 2 is performed only when the flag TrackSchemaVersions is enabled. This implies that #1 also has to happen when TrackSchemaVersions is enabled independently of the WatchReplication flag

However if the WatchReplication flag is enabled but TrackSchemaVersions is disabled we still need to run the Replication Watcher since the user has requested it, but we should not store schema versions.

So the logic is:

1. WatchReplication==true \
   => Replication Watcher is running

2. TrackSchemaVersions==false  
   => SchemaUpdated is a noop

3. TrackSchemaVersions=true  
   => Replication Watcher is running \
   => SchemaUpdated is handled

The Historian behavior is identical to that of the replica: of course if versions are not stored in \_vt.schema_versions it will always provide the latest version of the scheme.

### Replica

Schema versions are never stored on replicas, so SchemaUpdated is always a Noop. Versions are provided as appropriate by the historian. The historian provides the latest schema if there is no appropriate version.

So the logic is:

1. WatchReplication==true \
   => Replication Watcher is running

2. TrackSchemaVersions==false || true //noop \
   => Historian tries to get appropriate schema version

## Caveat

Only best-effort versioning can be provided due to races between DDLs and DMLs. Some examples below:

### Situation 1

If multiple DDLs are applied in a quick sequence we can end up with the following binlog.

T1: DDL 1 on table1

T2: DDL 2 on table1

T3: Version Event DDL1 // gets written because of the time taken by tracker processing DDL1

T4: DML1 on table1

T5: Version Event DDL2 // gets written AFTER DML1

So now on the replica, at T4, the version historian will incorrectly provide the schema from T1 after DDL1 was applied.

### Situation 2

If version tracking is turned off on the primary for some time, correct versions may not be available to the historian which will always return the latest schema. This might result in an incorrect schema when a Vstream is processing events in the past.

#### Possible new features around this functionality

- Schema tracking Vstream client for notifications of all ddls
- Raw history of schema changes for auditing, root cause analysis, etc.
