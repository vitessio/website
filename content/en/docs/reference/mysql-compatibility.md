---
title: MySQL Compatibility
weight: 1
aliases: ['/docs/reference/mysql-server-protocol/']
---

VTGate servers speak both gRPC and the MySQL server protocol. The MySQL server protocol support allows you to connect to Vitess as if it were a MySQL Server without changes to application code. This document refers to known compatibility issues where Vitess differs from MySQL.

## Transaction Model

Vitess provides `READ COMMITTED` semantics when executing cross-shard queries.
This differs to MySQL, which defaults to `REPEATABLE READ`. If this difference
matters to you, you can get `READ COMMITTED` semantics by placing the table(s)
for which it is important its own unsharded keyspace.

## SQL Syntax

The following describes some of the major differences in SQL Syntax handling
between Vitess and MySQL. For a list of unsupported queries, check out the
[test-suite cases](https://github.com/vitessio/vitess/blob/master/go/vt/vtgate/planbuilder/testdata/unsupported_cases.txt).
When reviewing these test cases, be aware that many of the incompabilities
only apply to cases where some/all of the tables involved are sharded. In
general, it might be possible to work around potential issues by either
isolating certain tables in an unsharded keyspace, or by just avoiding
the problematic SQL construct.

### DDL
Vitess supports MySQL DDL, and will send `ALTER TABLE` statements to each
of the underlying tablet servers. For large tables it is recommended to
use an external schema deployment tool and apply directly to the underlying
MySQL shard instances. This is discussed further in [Applying MySQL Schema](../../user-guides/making-schema-changes).

### Join Queries

Vitess supports `INNER JOIN` including cross-shard joins. `LEFT JOIN` is
supported as long as there are not expressions that compare columns on the
outer table to the inner table in sharded keyspaces.

### Aggregation

Vitess supports a subset of `GROUP BY` operations, including cross-shard operations. The VTGate servers are capable of scatter-gather operations, but can only stream results. Thus, a query that performs a `GROUP BY colx ORDER BY coly` may be refused if the intermediate result set is larger than VTGate's in-memory limit.

### Subqueries

Vitess supports a subset of subqueries. For example, a subquery combined with a `GROUP BY` operation is not supported.

### Stored Procedures

Vitess does not yet support MySQL Stored Procedures.

### Foreign Keys

Foreign keys are supported in Vitess, but can only be enforced within a single
shard.  As with all large MySQL databases, if your database is of signficant
scale, it is considered best practice to use foreign keys sparingly,
if at all.

### Window Functions and CTEs

Vitess does not yet support Window Functions or Common Table Expressions.

### Killing running queries

Vitess does not yet support killing running shard queries via the `KILL` command through VTGate. Vitess does have strict query timeouts for OLTP workloads (see below). If you need a query, you can connect to the underlying MySQL shard instance and run `KILL` from there.

### Cross-shard Transactions

By default, Vitess does not support transactions that span across shards. While Vitess can support this with the use of [Two-Phase Commit](../two-phase-commit), it is usually recommended to design the VSchema in such a way that cross-shard modifications are not required.

### OLAP Workload

By default, Vitess sets some intentional restrictions on the execution time
and number of rows that a query can return. These restrictions are set
low by default, and can be adjusted, but are there to improve the reliability
and operability of your database environment.  You should therefore not
blindly raise the row or execution time limits without due consideration
and/or adding additional guardrails.

This default workload mode of Vitess that enforces these restrictions
is called `OLTP`. This can be disabled by setting the workload to `OLAP`, e.g.:
```sql
SET workload='olap'
```

You would typically use `OLAP` workload mode for tasks that need to
pull a lot of data out of Vitess, like ETL tasks.  However, it should
be noted that `OLAP` workload mode is intended to be
used only with queries that can be streamed from backend servers, and
therefore have significantly more compatibility restrictions than
the default `OLTP` workload mode.

## Network Protocol

### Prepared Statements

Starting with version 4.0, Vitess features experimental support for prepared
statements via the MySQL protocol. Session-based commands using the `PREPARE`
and `EXECUTE` SQL statements are not supported.

### Authentication Plugins

Vitess supports the `mysql_native_password` authentication plugin.
Support for `caching_sha2_password` can be tracked in
[#5399](https://github.com/vitessio/vitess/issues/5399).

### Transport Security

To configure VTGate to support `TLS` set `-mysql_server_ssl_cert` and `-mysql_server_ssl_key`. Client certificates can also be mandated by setting `-mysql_server_ssl_ca`. If there is no CA specified then TLS is optional.

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

Tables in sharded keyspaces do not support the `auto_increment` column attribute, as the values generated would be local only to each shard. [Vitess Sequences](../vitess-sequences) are provided as an alternative, which have very close semantics to `auto_increment`.

## Extensions to MySQL Syntax

### SHOW Statements

Vitess supports a few additional options with the SHOW statement.

* `SHOW keyspaces` -- A list of keyspaces available.
* `SHOW vitess_tablets` -- Information about the current Vitess tablets such as the keyspace, key ranges, tablet type, hostname, and status.
* `SHOW vitess_shards` -- A list of shards that are available.
* `SHOW vschema tables` -- A list of tables available in the current keyspace's vschema.
* `SHOW vschema vindexes` -- Information about the current keyspace's vindexes such as the keyspace, name, type, params, and owner. Optionally supports an "ON" clause with a table name.

### USE Statements

Vitess allows you to select a keyspace using the MySQL `USE` statement, and corresponding binary API used by client libraries. SQL statements can refer to a table in another keyspace by using the standard _dot_ notation:

```sql
SELECT * FROM my_other_keyspace.table;
```

Vitess extends this functionality further by allowing you to select a specific shard and tablet-type within a `USE` statement (backticks are important):

```sql
-- `KeyspaceName:shardKeyRange@tabletType`
USE `mykeyspace:-80@rdonly`
```

A similar effect can be achieved by using a database name like `mykeyspace:-80@rdonly` in your MySQL application client connection string.

Lastly, it is possible to directly specify a `keyspace_id` in a database name
instead of the shard specifier.  This allows for advanced use-cases where you
are doing manual data placement between shards, and want your query to address
a specific part of the keyspace range, without having to specify a specific
shard (which would require knowledge of the current shard configuration). A
use-case might be where you need to access a legacy table that was sharded
before you started using Vitess, and you do not have a Vindex to direct
queries to it appropriately.  This format looks like this:

```sql
-- `KeyspaceName[keyspace_id_value]@tabletType`
USE `mykeyspace[0000000000000001]@rdonly`
```
