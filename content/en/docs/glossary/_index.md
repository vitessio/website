---
title: Glossary
description: Definitions of terms used in Vitess documentation
weight: 3000
cascade:
  skipversions: true
---

This document defines terms used throughout Vitess documentation, command-line tools, and source code.

## Backup

A consistent snapshot of data stored for disaster recovery and provisioning new tablets. Vitess supports full backups (entire dataset) and incremental backups (binary log changes). See also the [backup tablet type](#backup-tablet-type).

## Backup (tablet type) {#backup-tablet-type}

A [tablet](#tablet) state indicating the tablet has stopped replication at a consistent snapshot to upload a new [backup](#backup). After completion, it resumes replication and returns to its previous type.

## Cell

A data center, availability zone, or other failure domain. Vitess uses cells to isolate failures and route queries to geographically appropriate tablets.

## Consistent Lookup Vindex

A [lookup vindex](#lookup-vindex) that maintains consistency without requiring two-phase commit.

## Drained (tablet type) {#drained-tablet-type}

A [tablet](#tablet) state reserved for Vitess background operations such as resharding. Drained tablets do not serve queries.

## Functional Vindex

A [vindex](#vindex) that computes the [keyspace ID](#keyspace-id) using an algorithmic mapping such as a hash or identity function, without consulting external data.

## Global Topology

The portion of the [topology service](#topology-service) that stores cluster-wide metadata shared across all [cells](#cell).

## GTID Position

Global Transaction Identifier position. Marks a specific point in the MySQL binary log for replication tracking.

## Keyrange

The range of [keyspace IDs](#keyspace-id) that a [shard](#shard) is responsible for. Expressed in hexadecimal notation like `-80` (up to 0x80) or `80-` (from 0x80 onward).

## Keyspace

A logical database that maps to one or more MySQL replica sets. If using [sharding](#shard), a keyspace spans multiple MySQL replica sets (one replica set per shard); otherwise it maps to a single MySQL database. Applications interact with keyspaces as if they were single MySQL servers.

## Keyspace ID

A computed value that determines which [shard](#shard) contains a given row. The [primary vindex](#primary-vindex) maps a column value to a keyspace ID.

## Local Topology

The portion of the [topology service](#topology-service) that stores metadata specific to a single [cell](#cell).

## Lookup Vindex

A [vindex](#vindex) that uses a lookup table to map column values to [keyspace IDs](#keyspace-id). Enables routing queries on columns other than the sharding key.

## Materialize

A VReplication workflow that creates and maintains materialized views or realtime rollups across [shards](#shard).

## MoveTables

A VReplication workflow that migrates tables from one [keyspace](#keyspace) to another.

## mysqlctl

A command-line utility for managing the lifecycle of local MySQL instances used by Vitess.

## Online DDL

Non-blocking schema changes that allow tables to remain available during migrations.

## Primary

In MySQL replication, the database server that receives write operations and streams changes to replicas. In Vitess, each [shard](#shard) has one primary. See also [Primary (tablet type)](#primary-tablet-type).

## Primary (tablet type) {#primary-tablet-type}

A [tablet](#tablet) currently serving as the MySQL primary for its [shard](#shard). Handles all write operations. Formerly called "master." A [replica](#replica-tablet-type) tablet that has been promoted to primary through [reparenting](#reparenting).

## Primary Vindex

The [vindex](#vindex) that determines row-to-shard mapping. Equivalent to the sharding key.

## Rdonly (tablet type) {#rdonly-tablet-type}

A [tablet](#tablet) type for read-only MySQL replicas that are not eligible for promotion to [primary](#primary-tablet-type). Used for batch jobs, analytics, backups, and other background operations.

## Reparenting

The process of changing which [tablet](#tablet) serves as the [primary](#primary) for a [shard](#shard).

## Replica

In MySQL replication, a database server that receives and applies changes from a primary. See also [Replica (tablet type)](#replica-tablet-type).

## Replica (tablet type) {#replica-tablet-type}

A [tablet](#tablet) type for MySQL replicas that are eligible for promotion to [primary](#primary-tablet-type). Conventionally used for serving live, user-facing read requests.

## Replication Graph

Metadata that tracks MySQL primary-replica relationships within the cluster.

## Reshard

A VReplication workflow that splits or merges [shards](#shard) to scale horizontally.

## Restore (tablet type) {#restore-tablet-type}

A [tablet](#tablet) state indicating the tablet is restoring data from a [backup](#backup). After completion, it begins replicating and becomes either [replica](#replica-tablet-type) or [rdonly](#rdonly-tablet-type).

## Routing Rules

Configuration that overrides default query routing during migrations, allowing gradual traffic shifts between [keyspaces](#keyspace).

## Secondary Vindex

A [vindex](#vindex) that provides additional query routing optimization beyond the [primary vindex](#primary-vindex).

## Shard

A horizontal partition of a [keyspace](#keyspace). Each shard contains a subset of the keyspace's data based on [keyrange](#keyrange). An unsharded keyspace has a single shard named `0` or `-`.

## SwitchTraffic

A VReplication operation that redirects query traffic from a source to a target during workflows like [MoveTables](#movetables) or [Reshard](#reshard).

## Tablet

A combination of a `vttablet` process and its associated MySQL instance. Tablets are the basic unit of data storage and query serving in Vitess.

## Tablet Alias

A unique identifier for a [tablet](#tablet) in the format `cell-uid`, such as `zone1-100`.

## Topology Service

A metadata store (backed by etcd, Consul, or ZooKeeper) that holds cluster configuration, [replication graph](#replication-graph), and serving state. Often abbreviated as "topo."

## Unsharded

A [keyspace](#keyspace) with a single [shard](#shard), containing all data without horizontal partitioning.

## VDiff

A VReplication tool that verifies data consistency between source and target during migrations.

## VEXPLAIN

A SQL command that shows how Vitess will execute a query across [shards](#shard), including the generated MySQL queries.

## Vindex

Virtual index. A mechanism that maps column values to [keyspace IDs](#keyspace-id) for query routing. Types include [primary](#primary-vindex), [secondary](#secondary-vindex), [lookup](#lookup-vindex), and [functional](#functional-vindex).

## VReplication

Vitess's streaming replication mechanism for data movement operations like [MoveTables](#movetables), [Reshard](#reshard), and [Materialize](#materialize).

## VSchema

Virtual schema. Configuration that defines how a [keyspace](#keyspace) is sharded, including [vindexes](#vindex), table definitions, and routing rules.

## VStream

A change notification service on [VTGate](#vtgate) that streams row changes to clients.

## VStreamer

The component on [VTTablet](#vttablet) that streams MySQL binary log events for [VReplication](#vreplication) and [VStream](#vstream).

## vtbackup

A standalone utility for taking backups of MySQL data managed by Vitess.

## vtcombo

A single-process test environment that runs all Vitess components together. Useful for local development and testing.

## VTAdmin

A web-based administrative interface for managing and monitoring Vitess clusters.

## vtctld

The Vitess control daemon. A server process that executes cluster management commands issued by [vtctldclient](#vtctldclient).

## vtctldclient

The current command-line client for Vitess cluster management. Communicates with [vtctld](#vtctld) to execute administrative operations.

## VTEXPLAIN

A command-line tool for offline query analysis that shows how Vitess would route and execute queries without connecting to a live cluster.

## VTGate

A lightweight, stateless proxy that routes queries to the appropriate [tablets](#tablet). Applications connect to VTGate rather than directly to MySQL.

## VTOrc

Vitess Orchestrator. Provides automated failover, recovery, and tablet management for Vitess clusters.

## VTTablet

The Vitess process that manages a MySQL instance, handling query serving, replication, and schema management. Together with MySQL, it forms a [tablet](#tablet).

## vttestserver

A lightweight Vitess server for local development and testing that simulates a Vitess cluster.
