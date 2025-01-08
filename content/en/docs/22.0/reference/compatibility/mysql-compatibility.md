---
title: MySQL Compatibility
weight: 1
aliases: ['/docs/reference/mysql-server-protocol/', '/docs/reference/mysql-compatibility/']
---

## Introduction

Vitess supports MySQL and gRPC server protocols, allowing it to serve as a drop-in replacement for MySQL Server without changes to application code. However, because Vitess is a distributed system, there are compatibility differences to be aware of.

## Table of Contents
1. [Transaction and Isolation Levels](#transaction-and-isolation-levels)
2. [SQL Support](#sql-support)
   1. [DDL](#ddl)
   2. [Join, Subqueries, Union, Aggregation, Grouping, Having, Ordering, Limit Queries](#join-subqueries-union-aggregation-grouping-having-ordering-limit-queries)
   3. [Prepared Statements](#prepared-statements)
   4. [Stored Procedures](#stored-procedures)
   5. [Views](#views)
   6. [Temporary Tables](#temporary-tables)
   7. [USE Statements](#use-statements)
   8. [Common Table Expressions (CTEs)](#common-table-expressions)
   9. [Window Functions](#window-functions)
   10. [Killing Running Queries](#killing-running-queries)
   11. [SELECT ... INTO Statement](#select--into-statement)
   12. [LOAD DATA Statement](#load-data-statement)
   13. [Create/Drop Database](#createdrop-database)
   14. [User Defined Functions (UDFs)](#user-defined-functions)
   15. [LAST_INSERT_ID](#last_insert_id)
3. [Cross-shard Transactions](#cross-shard-transactions)
4. [Auto Increment](#auto-increment)
5. [Character Set and Collation](#character-set-and-collation)
6. [Data Types](#data-types)
7. [SQL Mode](#sql-mode)
8. [Network Protocol](#network-protocol)
   1. [Authentication Plugins](#authentication-plugins)
   2. [Transport Security](#transport-security)
   3. [X Dev API](#x-dev-api)
9. [Workload](#workload)

---

## Transaction and Isolation Levels

Vitess offers MySQL default semantics (`REPEATABLE READ`) for single-shard transactions. For multi-shard transactions, the semantics change to `READ COMMITTED`.

- You can change the isolation level at the shard level using the `SET` statement on a connection.
- `START TRANSACTION` supports modifiers like `WITH CONSISTENT SNAPSHOT`, `READ WRITE`, and `READ ONLY`, but they apply only to the next transaction.
- `SET TRANSACTION` is currently supported only for changing the isolation level at the session scope in Vitess (affecting shard-level isolation, not global Vitess).

---

## SQL Support

While Vitess is mostly compatible with MySQL, there are some limitations. A current list of unsupported queries is maintained in the [Vitess GitHub repo](https://github.com/vitessio/vitess/blob/main/go/vt/vtgate/planbuilder/testdata/unsupported_cases.json).

### DDL

Vitess supports all DDL queries:
- **Managed, online schema changes** (non-blocking, revertible, etc.).
- **Non-managed DDL** is also supported.

Refer to [making schema changes](../../../user-guides/schema-changes) for more details.

### Join, Subqueries, Union, Aggregation, Grouping, Having, Ordering, Limit Queries

Vitess supports most of these query types. For the best experience:
- Leave [schema tracking](../../features/schema-tracking) enabled to leverage full support.

### Prepared Statements

Vitess supports:
- Prepared statements via MySQL binary protocol.
- SQL statements: [`PREPARE`, `EXECUTE`, `DEALLOCATE`](https://dev.mysql.com/doc/refman/8.0/en/sql-prepared-statements.html).

### Stored Procedures

You can call stored procedures (`CALL`) with the following limitations:
- Must be on an **unsharded keyspace** or target a **specific shard**.
- No results can be returned.
- Only `IN` parameters are supported.
- Transaction state cannot be changed by the procedure.

`CREATE PROCEDURE` is not supported through Vitess; create procedures on the underlying MySQL servers directly.

### Views

Views are supported for **sharded keyspaces** as an experimental feature:
- Enable with `--enable-views` on VTGate and `--queryserver-enable-views` on VTTablet.
- Views are only readable (no updatable views).
- All tables referenced by the view must belong to the same keyspace.

See the [Views RFC](https://github.com/vitessio/vitess/issues/11559) for more details.

### Temporary Tables

Vitess has limited support for temporary tables, only for **unsharded keyspaces**:
- Creating a temporary table forces the session to start using [reserved connections](../../query-serving/reserved-conn).
- Query plans in this session won’t be cached.

### USE Statements

Vitess allows selecting a keyspace (and shard/tablet-type) using the MySQL `USE` statement:
```sql
USE `mykeyspace:-80@rdonly`
```

Or refer to another keyspace’s table via standard dot notation:

```sql
SELECT * 
FROM other_keyspace.table;
```

### Common Table Expressions
 - Non-recursive CTEs are supported.
 - Recursive CTEs have experimental support; feedback is encouraged.

### Window Functions

Window Functions are not currently supported in Vitess.

### Killing Running Queries

Starting with Vitess v18, you can terminate running queries with the KILL command through VTGate:
 - Issue `KILL connection` or `KILL query` from a new client connection (similar to `ctrl+c` in MySQL shell).
 - You can also ask Vitess to kill queries that run beyond a specified timeout. The timeout can be set per query or globally.
 - `query_timeout_ms` (per-query timeouts).
 - `mysql_server_query_timeout command-line` flag (global default timeout).

### SELECT … INTO Statement

Vitess supports `SELECT ... INTO DUMPFILE` and `SELECT ... INTO OUTFILE` for unsharded keyspaces:
 - Position of `INTO` must be at the end of the query.
 - For sharded keyspaces, you must specify the exact shard with a `USE` statement.

### LOAD DATA Statement

`LOAD DATA` (the counterpart to `SELECT ... INTO OUTFILE`) is supported only in unsharded keyspaces:
 - Must be used similarly to the `SELECT ... INTO` statement.
 - For sharded keyspaces, use the USE Statement to target an exact shard.

### Create/Drop Database

Vitess does not support `CREATE DATABASE` or `DROP DATABASE` by default:
 - A plugin mechanism ([`DBDDLPlugin`](https://github.com/vitessio/vitess/blob/release-21.0/go/vt/vtgate/engine/dbddl.go#L53) interface) exists for provisioning databases.
 - The plugin must handle database creation, topology updates, and VSchema updates.
 - Register the plugin with `DBDDLRegister` and specify `--dbddl_plugin=myPluginName` when running vtgate.

### User Defined Functions

Vitess can track UDFs if you enable the `--enable-udfs` flag on VTGate. More details on creating UDFs can be found in the MySQL Docs.

### LAST_INSERT_ID

Vitess supports `LAST_INSERT_ID` both for returning the last auto-generated ID and for the form `LAST_INSERT_ID(expr)`, which sets the session’s last-insert-id value.

**Example**:

```sql
insert into test (id) values (null); -- Inserts a row with an auto-generated ID
select LAST_INSERT_ID(); -- Returns the last auto-generated ID
SELECT LAST_INSERT_ID(123); -- Sets the session’s last-insert-id value to 123
SELECT LAST_INSERT_ID(); -- Returns 123
```

**Limitation**: When using `LAST_INSERT_ID(expr)` as a SELECT expression in *ordered queries*, MySQL sets the session’s `LAST_INSERT_ID` value based on the *last row returned*. 
Vitess, however, does **not** guarantee which row’s value will be used.

**Example**:

```sql
SELECT LAST_INSERT_ID(col) 
FROM table 
ORDER BY foo;
```

## Cross-shard Transactions

Vitess supports multiple [transaction modes](../../../user-guides/configuration-advanced/shard-isolation-atomicity): `SINGLE`, `MULTI` and `TWOPC` .
 - Default: `MULTI` — multi-shard transactions on a best-effort basis.
 - A single-shard transaction is fully ACID-compliant.
 - Multi-shard commits are done in a specific order; partial commits can be manually undone if needed.

## Auto Increment

Avoid the `auto_increment` column attribute in sharded keyspaces; values won’t be unique across shards.
Use [Vitess Sequences](../../../user-guides) instead — they behave similarly to `auto_increment`.

## Character Set and Collation

Vitess supports ~99% of MySQL collations. For details, see the [collations documentation](../../../user-guides/configuration-basic/collations).

## Data Types

Vitess supports all MySQL data types. Using `FLOAT` as part of a `PRIMARY KEY` is discouraged because it can break features like filtered replication and VReplication.

## SQL Mode

Vitess behaves similarly to `STRICT_TRANS_TABLES` and does not recommend changing the SQL Mode.

## Network Protocol

### Authentication Plugins

Vitess supports MySQL authentication plugins, such as `mysql_native_password` and `caching_sha2_password`.

### Transport Security

To enable TLS on VTGate:
 - Set `--mysql_server_ssl_cert` and `--mysql_server_ssl_key`.
 - Optionally require client certificates with `--mysql_server_ssl_ca`.
 - If no CA is specified, TLS is optional.

### X Dev API

Vitess does not support the X Dev API.

## Workload

By default, Vitess applies strict limitations on execution time and row counts, often referred to as OLTP mode:
 - These parameters can be tweaked with `queryserver-config-query-timeout`, `queryserver-config-transaction-timeout`, and [others](../../programs/vttablet) on vttablet.
 - You can switch to OLAP mode by issuing:

```sql
SET workload = olap;
```
