---
title: Glossary
description: Short definitions of the terms, abbreviations and jargon used in the Vitess documentation
weight: 11
---

This glossary briefly explains the terms that you will come across in the Vitess documentation. Where a term has a page of its own, the entry links to it. For more in-depth explanations of the core ideas, see [Concepts](../../concepts/).

## Backup (tablet type)

A [tablet type](#tablet-type) for a tablet that is out of service while it takes a backup of its shard. A tablet only takes this type when the backup requires it, such as a full backup with the `builtin` engine, which stops replication and shuts down MySQL while it copies the data files. When the backup is done, the tablet returns to its previous type.

## Backup engine

The component that copies a tablet's MySQL data when Vitess takes a backup, and restores it again. It is selected with the `--backup-engine-implementation` flag: `builtin` (the default) copies the data files while MySQL is shut down, `xtrabackup` uses Percona XtraBackup to take a backup while MySQL is running, and the experimental `mysqlshell` engine uses the dump and load utilities of MySQL Shell. See [Backup and Restore](../../user-guides/operating-vitess/backup-and-restore/overview/).

## Backup storage

Where Vitess stores backups, selected with the `--backup-storage-implementation` flag. Vitess has plugins for a local or network file system (`file`), Amazon S3 and compatible stores (`s3`), Google Cloud Storage (`gcs`), Azure Blob Storage (`azblob`) and Ceph (`ceph`). See [Backup and Restore](../../user-guides/operating-vitess/backup-and-restore/overview/).

## Buffering

A VTGate feature that holds queries for a shard in memory during a planned failover, or while SwitchTraffic or ReverseTraffic switches the traffic of a MoveTables or Reshard workflow, and sends them on once the new primary, shards or keyspace are serving, instead of returning errors to the application. See [VTGate Buffering](../features/vtgate-buffering/).

## CDC

Change data capture: streaming every change made to the data to another system. In Vitess, CDC clients use [VStream](#vstream).

## Cell

A group of servers and network infrastructure that is isolated from failures in other cells, typically a data center or an availability zone. Each cell has its own [local topology service](#local-topology-service). See [Cell](../../concepts/cell/).

## Consolidator

See [query consolidation](#query-consolidation).

## Copy phase

The first phase of a [VReplication](#vreplication) stream, in which the existing rows of the source tables are copied to the target. The stream then moves on to replicating the changes made since then from the source's binary logs, and keeps doing that until the workflow is completed. See [Life of a Stream](../vreplication/internal/life-of-a-stream/).

## Cutover

See [SwitchTraffic](#switchtraffic). For [Online DDL](#online-ddl), the cutover is the brief moment when Vitess swaps the migrated table with the original one.

## DDL strategy

How Vitess applies a schema change. `vitess` runs a managed [Online DDL](#online-ddl) migration using [VReplication](#vreplication), `mysql` lets the Online DDL scheduler manage the migration but runs it as a normal MySQL statement, and `direct` sends the DDL straight to MySQL without any management. See [Online DDL strategies](../../user-guides/schema-changes/ddl-strategies/).

## Distributed transaction

A transaction that writes to more than one shard. The [transaction mode](#transaction-mode) decides whether Vitess allows it and how it commits it. Atomic distributed transactions use [two-phase commit](#two-phase-commit-2pc). See [Distributed Transactions](../features/distributed-transaction/).

## Drained (tablet type)

A [tablet type](#tablet-type) for a replica that a Vitess background process has reserved, so that it doesn't serve queries.

## Durability policy

A keyspace setting that tells Vitess which tablets can be promoted to primary and how [semi-sync](#semi-sync) replication is set up, for example `none`, `semi_sync` or `cross_cell`. VTOrc and the reparenting commands follow it. See [Durability Policy](../../user-guides/configuration-basic/durability_policy/).

## EmergencyReparentShard (ERS)

A `vtctldclient` command that promotes a new primary when the current primary is unreachable or dead. It picks the most up-to-date eligible replica. [VTOrc](#vtorc) runs it automatically when it detects a dead primary. See [Reparenting](../../user-guides/configuration-advanced/reparenting/).

## etcd

A distributed key-value store and the most commonly used backend of the [topology service](#topology-service) (the `etcd2` topology implementation). Vitess also supports ZooKeeper (`zk2`) and Consul (`consul`).

## Execution plan

The plan that VTGate builds for a query: which keyspaces and shards it sends work to, and which operations, such as joins, sorts or aggregations, it performs itself on the rows that come back. VTGate caches plans. See [Execution Plans](../../concepts/execution-plans/) and [VEXPLAIN](#vexplain).

## External reparenting

Changing a shard's primary with a tool outside of Vitess, and then telling Vitess about the new primary with the `TabletExternallyReparented` command so that it can update the topology service. See [Reparenting](../../user-guides/configuration-advanced/reparenting/).

## Global routing

Sending a query on an unqualified table name to the keyspace that contains the table, when no keyspace is selected on the connection and the table name is unique across keyspaces. See [Global Routing](../features/global-routing/).

## Global topology service

The part of the [topology service](#topology-service) that stores cluster-wide data that changes rarely, such as the list of keyspaces and shards, and each shard's primary. It should have servers in several cells so that it survives the loss of a cell. See [Topology Service](../../concepts/topology-service/).

## GTID

Global transaction identifier: an ID that MySQL gives every transaction it commits. Vitess requires GTID-based replication, and uses GTID positions to set up replication, choose a new primary, and track the progress of [VReplication](#vreplication) streams and backups.

## Heartbeat

A timestamp that VTTablet writes regularly on a primary, to a table in the [sidecar database](#sidecar-database), when it runs with `--heartbeat-enable`. Replicas compare the replicated value with the current time to measure their replication lag, and the [tablet throttler](#tablet-throttler) can use it too.

## Hot row protection

A VTTablet feature that queues transactions that update the same row, so that a burst of updates to one row doesn't use up the transaction pool. It is enabled with `--enable-hot-row-protection`.

## Key range

A range of [keyspace IDs](#keyspace-id). Each shard of a sharded keyspace covers one key range, and the serving shards of a keyspace together cover all keyspace IDs without overlapping. The [shard name](#shard-name) is its key range. See [Sharding](../features/sharding/).

## Keyspace

A logical database that is stored in one MySQL replica set per [shard](#shard): a single replica set if it is [unsharded](#unsharded-keyspace), and several if it is [sharded](#sharded-keyspace). Applications use a keyspace as if it were a single MySQL database. See [Keyspace](../../concepts/keyspace/).

## Keyspace ID

The value that decides which shard a row lives in. A row's [primary vindex](#primary-vindex) computes it from the value of a column, such as a user ID. See [Keyspace ID](../../concepts/keyspace-id/).

## Local topology service

The part of the [topology service](#topology-service) that runs in each cell and stores information about the cell's own tablets and the [serving graph](#serving-graph). Queries are still served while it is briefly unavailable. See [Topology Service](../../concepts/topology-service/).

## Lookup vindex

A [vindex](#vindex) that stores the mapping from a column value to a keyspace ID in a separate lookup table, which lets VTGate route queries on columns other than the sharding key to the right shard. An owned lookup vindex is updated automatically when rows are inserted into, updated in, or deleted from its owner table. Use [`LookupVindex`](../vreplication/lookupvindex/) to create and backfill one. See [Vindexes](../features/vindexes/).

## Materialize

A [VReplication](#vreplication) workflow that keeps a copy, a subset or an aggregation of one or more source tables up to date in a target keyspace. See [Materialize](../vreplication/materialize/).

## Messaging

A Vitess feature that stores messages in a MySQL table and lets applications send, receive and acknowledge them, with guaranteed delivery. See [Vitess Messaging](../features/messaging/).

## Migrate

A [VReplication](#vreplication) workflow that moves tables from another Vitess cluster, which is linked with [Mount](#mount), into the current one. See [Migrate](../vreplication/migrate/).

## Mirror rules

Rules that make VTGate send a copy of a percentage of the read queries for some tables to another keyspace, to see how the queries perform there before switching traffic with [MoveTables](#movetables). See [Schema Mirror Rules](../features/schema-mirror-rules/).

## Mount

A command that registers the topology service of another Vitess cluster with the current one, so that a [Migrate](#migrate) workflow can copy tables from it. See [Mount](../vreplication/mount/).

## MoveTables

A [VReplication](#vreplication) workflow that moves tables from one keyspace to another, including from an external MySQL database into Vitess, without downtime. See [MoveTables](../../concepts/move-tables/) and the [MoveTables reference](../vreplication/movetables/).

## mysqlctl

A command-line tool that initializes, starts and stops the `mysqld` instance of a tablet. `mysqlctld` does the same as a long-running daemon. See [mysqlctl](../programs/mysqlctl/).

## OLAP

Online analytical processing. In Vitess, the `olap` [workload](#workload) streams query results and doesn't apply the row count and execution time limits of the default `oltp` workload, so that it can run long reporting queries.

## OLTP

Online transaction processing: many short reads and writes. `oltp` is the default [workload](#workload).

## Online DDL

Schema changes that Vitess schedules, runs and tracks for you, and that it can cancel, retry or revert. With the `vitess` [DDL strategy](#ddl-strategy), they don't block the table while they run, apart from holding its queries briefly at the [cutover](#cutover). See [Managed, Online Schema Changes](../../user-guides/schema-changes/managed-online-schema-changes/).

## PlannedReparentShard (PRS)

A `vtctldclient` command that moves a healthy shard's primary role to another tablet, for example before maintenance. It waits for the new primary to catch up on replication, and VTGate can [buffer](#buffering) queries while it runs. See [Reparenting](../../user-guides/configuration-advanced/reparenting/).

## Point-in-time recovery (PITR)

Restoring a shard to the data that it had at a given time or [GTID](#gtid) position, using a full backup and the incremental backups taken after it. See [Point In Time Recovery](../features/recovery/).

## Primary (tablet type)

The [tablet type](#tablet-type) of the tablet that runs the MySQL primary of its shard. All writes to the shard go to it. Each shard has at most one primary at any time. Older documentation and flags call it `master`.

## Primary vindex

The [vindex](#vindex) that decides which shard each row of a table in a sharded keyspace lives in, by computing its [keyspace ID](#keyspace-id). Every sharded table has one, and tables with the same primary vindex keep the rows that have the same value for it in the same shard. See [Vindexes](../features/vindexes/).

## Query consolidation

A VTTablet feature that runs only one copy of identical read queries that arrive at the same time, and returns its result to all the callers, to protect MySQL from a sudden spike of the same query. See [Query Consolidation](../../user-guides/configuration-advanced/query-consolidation/).

## Rdonly (tablet type)

A [tablet type](#tablet-type) for a replica that can't be promoted to primary. Rdonly tablets are typically used for background work such as backups, analytics and other batch jobs.

## Reference table

A small, rarely updated table, such as a list of countries, of which every shard of a sharded keyspace has a copy that is kept in sync with a source table, so that queries can join it with sharded tables on any shard. See [Reference Tables](../vreplication/reference_tables/).

## Reparenting

Changing a shard's primary, either in a planned way with [PlannedReparentShard](#plannedreparentshard-prs), after a failure with [EmergencyReparentShard](#emergencyreparentshard-ers), or [externally](#external-reparenting). See [Reparenting](../../user-guides/configuration-advanced/reparenting/).

## Replica (tablet type)

A [tablet type](#tablet-type) for a MySQL replica that can be promoted to primary. Replica tablets can also serve reads that can tolerate replication lag.

## Replication graph

The relationships between each shard's primary and its replicas, which Vitess uses to repoint the replicas when the primary changes. See [Replication Graph](../../concepts/replication-graph/).

## Reserved connection

A MySQL connection that is dedicated to a single client session, instead of being shared through the connection pools of VTTablet, because the session has changed state that only that connection has, such as a temporary table or an advisory lock taken with `GET_LOCK()`. With a temporary table, VTGate reserves one on each shard that the session uses. Advisory locks all use one reserved connection, on the first shard of the alphabetically first keyspace. See [Reserved Connections](../query-serving/reserved-conn/) and [Locking Functions](../query-serving/locking-functions/).

## Reshard

A [VReplication](#vreplication) workflow that splits shards into more shards, or merges them into fewer, on a running keyspace. See [Reshard](../vreplication/reshard/) and [Resharding](../../user-guides/configuration-advanced/resharding/).

## Restore (tablet type)

A [tablet type](#tablet-type) for a tablet that is restoring a backup of its shard, either because it started with no data or because of the `RestoreFromBackup` command. When the restore is done, it starts replicating from the [GTID](#gtid) position of the backup and becomes a [replica](#replica-tablet-type) or [rdonly](#rdonly-tablet-type) tablet, except after a point-in-time recovery, which leaves replication stopped and the tablet [drained](#drained-tablet-type).

## ReverseTraffic

A workflow command that switches traffic back to the source of a [MoveTables](#movetables) or [Reshard](#reshard) workflow after [SwitchTraffic](#switchtraffic). When writes are switched, Vitess starts a reverse workflow that keeps the source up to date, so that traffic can be switched back. See [Workflow](../vreplication/workflow/).

## Routing rules

Rules that redirect the queries for tables, keyspaces or shards to other keyspaces. [VReplication](#vreplication) workflows manage them while they move data. See [Schema Routing Rules](../features/schema-routing-rules/).

## Scatter query

A query on a sharded keyspace that VTGate can't route to particular shards with a vindex, so it sends the query to every shard and combines the results. See [Execution Plans](../../concepts/execution-plans/).

## Schema tracking

A VTGate feature that keeps an up-to-date list of the tables and columns in each keyspace, by watching for schema changes reported by VTTablet, and uses it to plan queries. See [Schema Tracking](../features/schema-tracking/).

## Semi-sync

MySQL semi-synchronous replication, in which the primary waits until at least one replica acknowledges each transaction before the commit completes. The keyspace's [durability policy](#durability-policy) decides which tablets can acknowledge.

## Sequence

A Vitess feature that generates unique, increasing IDs for a column of a table in a sharded keyspace, like MySQL's `AUTO_INCREMENT` does for a single database. The IDs come from a sequence table in an unsharded keyspace. See [Sequences](../features/vitess-sequences/).

## Serving graph

The data in the [local topology service](#local-topology-service) that VTGate uses to route queries: the shards of each keyspace (`SrvKeyspace`) and the combined VSchema (`SrvVSchema`).

## Shard

A subset of the data of a keyspace, stored in one MySQL replica set: a primary and its replicas. An [unsharded keyspace](#unsharded-keyspace) has a single shard. See [Shard](../../concepts/shard/).

## Shard name

The name of a shard of a sharded keyspace, which is its [key range](#key-range) in hexadecimal. For example, `-80` holds the keyspace IDs below `0x80` and `80-` holds the rest. The single shard of an unsharded keyspace is named `0` or `-` by convention. See [Shard Naming](../../concepts/shard/#shard-naming).

## Shard targeting

Sending queries to one shard or tablet type instead of letting VTGate route them, by naming it in the database name of the connection or in a `USE` statement, for example ``USE `commerce:-80` `` or `USE commerce@replica`.

## Sharded keyspace

A [keyspace](#keyspace) that its [VSchema](#vschema) marks as sharded, so that its data can be split across several [shards](#shard). The [primary vindex](#primary-vindex) of each sharded table decides which shard each row lives in.

## Sharding key

The column whose value decides which shard a row lives in. In Vitess, the sharding key is the column of the [primary vindex](#primary-vindex), and other columns can be used to route queries with [lookup vindexes](#lookup-vindex). See [Vindexes](../features/vindexes/).

## Sidecar database

The database, named `_vt` by default, in which Vitess keeps its own metadata on each MySQL instance, such as the state of VReplication streams, Online DDL migrations and [heartbeats](#heartbeat).

## SwitchTraffic

A workflow command that switches reads, writes, or both from the source to the target of a [MoveTables](#movetables) or [Reshard](#reshard) workflow, by updating the [routing rules](#routing-rules) or the [serving graph](#serving-graph). Writes are switched after the target has caught up with the source. See [Workflow](../vreplication/workflow/).

## Table lifecycle

The steps in which Vitess drops a table without locking up the database: it renames the table, keeps it for a while so that it can be restored, and then drops it, first purging its rows gradually if the MySQL server needs that to drop a large table without stalling. See [Table lifecycle](../../user-guides/schema-changes/table-lifecycle/).

## Tablet

A `mysqld` process and the `vttablet` process that manages it, usually on the same machine. Each tablet has a [tablet type](#tablet-type) and a [tablet alias](#tablet-alias). See [Tablet](../../concepts/tablet/).

## Tablet alias

The unique name of a tablet, made of its cell and a numeric ID, such as `zone1-0000000100`.

## Tablet throttler

A VTTablet service that measures the load on its shard, such as replication lag, and slows down background work, such as VReplication and Online DDL, when the load is too high. See [Tablet throttler](../features/tablet-throttler/).

## Tablet type

The role of a tablet, which decides what traffic VTGate sends to it. The main types are [primary](#primary-tablet-type), [replica](#replica-tablet-type) and [rdonly](#rdonly-tablet-type). A tablet is temporarily of the [backup](#backup-tablet-type) type while it takes a backup that requires taking it out of service, such as a full backup with the `builtin` engine, and of the [restore](#restore-tablet-type) type while it restores a backup. See [Tablet Types](../../concepts/tablet/#tablet-types).

## Topo

Short for the [topology service](#topology-service).

## Topology service

The distributed key-value store, such as [etcd](#etcd), in which Vitess keeps its configuration and the state of the cluster, and which provides the locks that Vitess uses to coordinate changes. It is made up of a [global topology service](#global-topology-service) and a [local topology service](#local-topology-service) in each cell. See [Topology Service](../../concepts/topology-service/).

## Transaction mode

The VTGate setting, set with the `--transaction-mode` flag or the `transaction_mode` session variable, that decides how transactions that write to more than one shard are handled: `SINGLE` rejects them, `MULTI` allows them and commits each shard on its own, and `TWOPC` commits them atomically with [two-phase commit](#two-phase-commit-2pc). See [Distributed Transactions](../features/distributed-transaction/).

## Two-phase commit (2PC)

The protocol that Vitess uses to commit a [distributed transaction](#distributed-transaction) atomically: all the shards involved first prepare the transaction, and then all of them commit it. See [Distributed Transactions](../features/distributed-transaction/).

## Unmanaged tablet

A tablet for a MySQL server that Vitess doesn't manage, such as an existing database or one hosted by a cloud provider. It is commonly used to move an existing database into Vitess with [MoveTables](#movetables). See [Unmanaged Tablet](../../user-guides/configuration-advanced/unmanaged-tablet/).

## Unsharded keyspace

A [keyspace](#keyspace) whose data isn't split, so that it has a single [shard](#shard), and so a single MySQL primary.

## VDiff

A tool that compares the rows of the source and target tables of a [VReplication](#vreplication) workflow, to check that the target has the same data before switching traffic. See [VDiff](../vreplication/vdiff/).

## VEXPLAIN

A SQL statement that shows how VTGate plans and runs a query, such as its [execution plan](#execution-plan) or the queries it sends to each shard. See [Analyzing a SQL statement using VEXPLAIN](../../user-guides/sql/vexplain/).

## Vindex

Short for Vitess index. A function that maps the values of a column to [keyspace IDs](#keyspace-id), which tells VTGate the shard in which a row lives. Each sharded table has one [primary vindex](#primary-vindex), and can have secondary vindexes, such as [lookup vindexes](#lookup-vindex). See [Vindexes](../features/vindexes/).

## Viper

The Go configuration library that Vitess uses to read its configuration, including values that can be changed while a binary is running. See [Viper](../viper/).

## VReplication

The Vitess component that copies data from source tables to target tables and keeps the target up to date with the source's binary logs. It powers [MoveTables](#movetables), [Reshard](#reshard), [Materialize](#materialize), [Online DDL](#online-ddl) and more. See [VReplication](../vreplication/vreplication/).

## VSchema

The Vitess schema of a keyspace, which describes how its data is laid out: whether the keyspace is sharded, the [vindexes](#vindex) of its tables, and its [sequences](#sequence) and [reference tables](#reference-table). VTGate uses it to route queries. See [VSchema](../../concepts/vschema/) and the [VSchema reference](../features/vschema/).

## VStream

A VTGate API that streams the changes made to the data of one or more shards, or of a whole keyspace, as events, for [CDC](#cdc). It reads them through the VStreamer service of each tablet, which reads its MySQL binary log. See [VStream](../../concepts/vstream/).

## VTAdmin

A web interface (`vtadmin-web`) and API server (`vtadmin`) to see and manage one or more Vitess clusters. See [VTAdmin](../vtadmin/).

## vtbackup

A program that takes a backup of a shard without taking a serving tablet out of service. It restores the latest backup into its own `mysqld`, catches up on replication, and takes a new backup. See [vtbackup](../programs/vtbackup/).

## vtcombo

A single process that runs VTGate and the tablets of a whole Vitess cluster, used for testing. [vttestserver](#vttestserver) is built on it. See [vtcombo](../programs/vtcombo/).

## vtctld

The server that runs the administrative commands sent by `vtctldclient`, and the HTTP pages to see the state of the cluster. See [vtctld](../../concepts/vtctld/).

## vtctldclient

The command-line client used to administer a Vitess cluster through [vtctld](#vtctld), for example to create keyspaces, run workflows and reparent shards. See [vtctldclient](../programs/vtctldclient/).

## vtexplain

A command-line tool that shows how Vitess would run a query for a given schema and VSchema, without a running cluster. See [vtexplain](../programs/vtexplain/).

## VTGate

The stateless proxy that applications connect to with the MySQL protocol or gRPC. It parses and plans each query, routes it to the right tablets, and combines their results. See [VTGate](../../concepts/vtgate/).

## VTOrc

The Vitess component that monitors the tablets of a cluster and repairs replication problems automatically, for example by running an [EmergencyReparentShard](#emergencyreparentshard-ers) when a primary fails. See [VTOrc](../../user-guides/configuration-basic/vtorc/).

## VTTablet

The process that runs alongside each `mysqld` and manages it. It serves the queries that VTGate sends, with connection pooling and protections such as query limits and [query consolidation](#query-consolidation), and runs replication, backups and VReplication. See [Tablet](../../concepts/tablet/).

## vttestserver

A program, also available as a Docker image, that starts MySQL and a [vtcombo](#vtcombo) process, so that a whole Vitess cluster runs on one machine or in one container, for local development and tests. See [vttestserver](../programs/vttestserver/).

## Workflow

A long-running VReplication job, such as [MoveTables](#movetables) or [Reshard](#reshard), that is identified by its name and target keyspace and is managed with commands such as `show`, [`SwitchTraffic`](#switchtraffic) and `complete`. See [Workflow](../vreplication/workflow/).

## Workload

A session setting that tells Vitess what kind of queries a connection runs, set with `SET workload = ...`. The default is [`oltp`](#oltp), and [`olap`](#olap) is meant for long analytical queries. See [Workload](../compatibility/mysql-compatibility/#workload).

## Zone

Another name for a [cell](#cell).
