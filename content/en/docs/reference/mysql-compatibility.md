---
title: MySQL Compatibility
weight: 1
aliases: ['/docs/reference/mysql-server-protocol/']
---

VTGate servers speak both gRPC and the MySQL server protocol. This allows you to connect to Vitess as if it were a MySQL Server without any changes to application code. This document refers to known compatibility issues where Vitess differs from MySQL.

## Transaction Model

Vitess provides `READ-COMMITTED` semantics when executing cross-shard queries. This differs to MySQL, which defaults to `REPEATABLE-READ`. 

## SQL Syntax

The following describes some of the major differences in SQL Syntax handling between Vitess and MySQL. For a list of unsupported queries, check out the [test-suite cases](https://github.com/vitessio/vitess/blob/master/go/vt/vtgate/planbuilder/testdata/unsupported_cases.txt).

### Join Queries

Vitess supports `INNER JOIN` including cross-shard joins. `LEFT JOIN` and natural join are not yet supported in sharded keyspaces.

### Aggregation

Vitess supports a subset of `GROUP BY` operations, including cross-shard operations. The VTGate servers are capable of scatter-gather operations, but can only stream results. Thus, a query that performs a `GROUP BY colx ORDER BY coly` will refuse to execute as this requires the intermediate results to be materialized. 

### Subqueries

Vitess supports a subset of subqueries. For example, a subquery combined with a `GROUP BY` operation is not supported.

### Window Functions and CTEs

Vitess does not yet support Window Functions or Common Table Expressions.

### Cross-shard Update

By default, Vitess does not support atomic modifications across shards. While Vitess can support this with the use of [Two-Phase Commit](../two-phase-commit), it is usually recommended to design the VSchema in such a way that cross-shard modifications are not required.

### OLAP Workload

By default, Vitess sets some intentional restrictions on the execution time and number of rows that a query can return. This can be disabled by setting the workload to OLTP:
```sql
SET workload='olap'
```

## Session Scope

Vitess uses a connection pool to fan-in connections from VTGate servers to Tablet servers. VTGate servers will refuse statements that make changes to the connection's session scope. This includes:

* `SET SESSION var=x`
* `CREATE TEMPORARY TABLE`
* `SET @var=x`

The exception to this, is that Vitess maintains a whitelist statements that MySQL connectors may use when they first connect to Vitess. Vitess will ignore these noisy statements when it knows it is safe to do so.

## Character Set and Collation

Vitess only supports `utf8` and variants such as `utf8mb4`.

## SQL Mode

Vitess behaves similar to the `STRICT_TRANS_TABLES` sql mode, and does not recommend changing the SQL Mode setting.

## Data Types

Vitess supports all of the data types available in MySQL. Using the `FLOAT` data type as part of a `PRIMARY KEY` is strongly discouraged, since features such as filtered replication and VReplication will not correctly be able to detect which rows should be included as part of a modification.

## Auto Increment

Tables in sharded keyspaces do not support the `auto_increment`, as the values generated would be local only to each shard. [Vitess Sequences](../vitess-sequences) are provided as an alternative, which have very close semantics to `auto_increment`.
