---
title: MySQL Compatibility
weight: 1
aliases: ['/docs/reference/mysql-server-protocol/', '/docs/reference/mysql-compatibility/']
---

Vitess supports MySQL and gRPC server protocol. This allows Vitess to be a drop-in replacement for MySQL Server without any changes to application code.
As Vitess is a distributed system, it is important to understand the differences between Vitess and MySQL on compatibility.

## Transaction Model

Vitess provides MySQL default semantics i.e. `REPEATABLE READ` for single-shard transactions. For multi-shard transactions the semantics change to `READ COMMITTED`.
The clients can change the shard level transaction mode with `SET` statement on a connection.

## SQL Support

The following describes some differences in query handling between Vitess and MySQL.
The Vitess team maintains a list of [unsupported queries](https://github.com/vitessio/vitess/blob/main/go/vt/vtgate/planbuilder/testdata/unsupported_cases.json) which is kept up-to-date as we add support for new constructs.

This is an area of active development in Vitess. Any unsupported query can be raised as an issue in the [Vitess GitHub Project](https://github.com/vitessio/vitess/issues/new/choose).

### DDL

Vitess supports all DDL queries. It offers both [managed, online schema changes](../../../user-guides/schema-changes/managed-online-schema-changes) and non-managed DDL.
It is recommended to use Vitess's managed schema changes, which offer non-blocking, trackable, failure agnostic, revertible, concurrent changes, and more. Read more about [making schema changes](../../../user-guides/schema-changes).

### Join, Subqueries, Union, Aggregation, Grouping, Having, Ordering, Limit Queries

Vitess supports most of these types of queries. It is recommended to leave [schema tracking](../../features/schema-tracking) enabled in order to fully utilize the available support.

### Prepared Statements

Vitess supports prepared statements via both the MySQL binary protocol and the [`PREPARE`, `EXECUTE` and `DEALLOCATE` SQL statements](https://dev.mysql.com/doc/refman/8.0/en/sql-prepared-statements.html).

### Start Transaction
There are multiple ways to start a transaction like `begin`, `start transaction` and `start transaction [transaction_characteristic [, transaction_characteristic] ...]` with several modifiers that control transaction characteristics.
```sql
transaction_characteristic: {
    WITH CONSISTENT SNAPSHOT
  | READ WRITE
  | READ ONLY
}
```
The scope of these modifications is limited to the next transaction only.
These modifications have a special purpose and more can be read about in the [MySQL reference manual](https://dev.mysql.com/doc/refman/8.0/en/commit.html).

### Set Transaction
Set Transaction statement is used to change the isolation level or access mode for transactions.
Vitess as of now **only** supports modification of isolation level at the session scope.
The change in isolation level only changes the shard level transaction isolation level and not the global Vitess level.

More details about the isolation level can be read in the [MySQL reference manual](https://dev.mysql.com/doc/refman/8.0/en/set-transaction.html).

### Stored Procedures

Calling stored procedures using CALL is only supported for:

* unsharded keyspaces
* if you directly target a specific shard

There are further limitations to calling stored procedures using CALL:

* The stored procedure CALL cannot return any results
* Only IN parameters are supported
* If you use transactions, the transaction state cannot be changed by the stored procedure.

  For example, if there is a transaction open at the beginning of the CALL, a transaction must still be open after the procedure finishes. Likewise, if no transaction is open at the beginning of the CALL, the stored procedure must not leave an open transaction after execution finishes.

CREATE PROCEDURE is not supported. You have to create the procedure directly on the underlying MySQL servers and not through Vitess.

### Views
Views are supported for sharded keyspaces as an experimental feature, it has to be enabled using: `--enable-views` on VTGate and `--queryserver-enable-views` on VTTablet. Views are only readable.

Here is an example of how to create a view:

```sql
CREATE VIEW my_view AS SELECT id, col FROM user
```

When using the view in a `SELECT` statement it will be rewritten to a derived table:

```sql
-- the query:
SELECT id FROM my_view
-- will be rewritten to:
SELECT id FROM (SELECT id, col FROM user) as my_view;
```

> **Limitations**:
>
> - The table referenced by the view must belong to the same keyspace as the view's.
>
> - Views are only readable. Updatable views are not supported.

The [RFC for views support](https://github.com/vitessio/vitess/issues/11559) is available on GitHub.

### Temporary Tables

Vitess has limited support for temporary tables. It works only for unsharded keyspaces.

If the user creates a temporary table then the session will start using reserved connections for any query sent on that session.

The query plans generated by this session will not be cached. It will still continue to use the query plan cached from other non-temporary table sessions.

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

### Common Table Expressions
Vitess supports Non-recursive CTEs with the limitation that CTE aliases cannot be the same as a base table used in the CTE. 
Currently, Vitess does not have support for recursive CTEs. 

### Window Functions
Vitess does not yet support Window Functions.

### Killing running queries

In v18, Vitess introduced the ability to terminate running queries using the [`KILL` command](https://dev.mysql.com/doc/refman/8.0/en/kill.html) through VTGate.
To execute a "kill connection" or "kill query" statement, the client needs to establish a new connection.
This behavior is similar to when a user on the MySQL shell client terminates a command by pressing ctrl+c.

The [RFC](https://github.com/vitessio/vitess/issues/13438) highlights the current limitation of the `Kill statement` support. 

Alternatively, 
- [query_timeout_ms](../../../user-guides/configuration-advanced/comment-directives/#query-timeouts-query_timeout_ms) query comment directive can be set to define a query timeout. This ensures that the query either returns a result or aborts within the specified time.
- [mysql_server_query_timeout](../../programs/vtgate/) command-line flag can be set on VTGate to establish a default timeout.

Vitess does have strict query timeouts for OLTP workloads (see below).

### Workload

By default, Vitess applies specific limitations on the execution time and the number of rows a query can return.
These limitations can be modified by adjusting the parameters like `queryserver-config-query-timeout`, `queryserver-config-transaction-timeout` and more in [vttablet](../../programs/vttablet/).
This default workload mode is referred as `OLTP`. This can be disabled by switching to `OLAP` mode by executing the following SQL statement:

```sql
set workload = olap;
```

### SELECT ... INTO Statement

The `SELECT ... INTO` form of `SELECT` in MySQL enables a query result to be stored in variables or written to a file. Vitess supports `SELECT ... INTO DUMFILE` and `SELECT ... INTO OUTFILE` constructs for unsharded keyspaces but does not support storing results in variable. Moreover, the position of `INTO` must be towards the end of the query and not in the middle. An example of a correct query is as follows:
```sql
SELECT * FROM <tableName> INTO OUTFILE 'x.txt' FIELDS TERMINATED BY ';' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '\t' LINES TERMINATED BY '\n'
```
For sharded keyspaces this statement can still be used but only after specifying the exact shard with a [USE Statement](#use-statements).

### LOAD DATA Statement

`LOAD DATA` is the complement of `SELECT ... INTO OUTFILE` that reads rows from a text file into a table at a very high speed. Just like `SELECT ... INTO` statement, `LOAD DATA` is also supported in unsharded keyspaces. An example of a correct query is as follows:
```sql
LOAD DATA INFILE 'x.txt' INTO REPLACE TABLE <tableName> FIELDS TERMINATED BY ';' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '\t' LINES TERMINATED BY '\n'
```
For sharded keyspaces this statement can still be used but only after specifying the exact shard with a [USE Statement](#use-statements).

### Create/Drop Database

Vitess does not support CREATE and DROP DATABASE queries out of the box.

However, a plugin mechanism is available that can be used to provision databases.
The plugin has to take care of creating and dropping the database, and update the topology & VSchema so that Vitess can start receiving queries for the new keyspace.

The plugin should implement the `DBDDLPlugin` interface, and be saved into a new file in the `go/vt/vtgate/engine/` directory.

```go
type DBDDLPlugin interface {
	CreateDatabase(ctx context.Context, name string) error
	DropDatabase(ctx context.Context, name string) error
}
```

It must then register itself by calling `DBDDLRegister`.
You can take a look at the `dbddl_plugin.go` in the engine package for an example of how it's done.
Finally, you need to add a command line flag to vtgate to have it use the new plugin: `--dbddl_plugin=myPluginName`

### User Defined Functions
VTGates can now track user-defined functions (UDFs) and use them during planning.
To enable it, set the `--enable-udfs` flag on VTGate.
More details on how to add UDFs can be found in [MySQL Docs](https://dev.mysql.com/doc/extending-mysql/8.0/en/adding-loadable-function.html).

## Cross-shard Transactions

Vitess supports multiple [transaction modes](../../../user-guides/configuration-advanced/shard-isolation-atomicity): `SINGLE`, `MULTI` and `TWOPC` .

The default mode is MULTI i.e. multi-shard transactions as best-effort. A transaction that affects only one shard will be fully ACID complaint.
When a transactions affects multiple shards, any failure on one or more shards will rollback the effect of that query.
Committing the multi-shard transaction issues commits to the participating shards in a particular order. This allows the application or user to undo the effects of partial commits in case of failures.

## Auto Increment

Tables in sharded keyspaces should not be defined using the `auto_increment` column attribute, as the values generated will not be unique across shards.
It is recommended to use [Vitess Sequences](../../features/vitess-sequences) instead. The semantics are very similar to `auto_increment` and the differences are documented.

## Character Set and Collation

Vitess supports ~99% of MySQL collations. More details can be found [here](../../../user-guides/configuration-basic/collations).

## Data Types

Vitess supports all of the data types available in MySQL. Using the `FLOAT` data type as part of a `PRIMARY KEY` is strongly discouraged, since features such as filtered replication and VReplication will not correctly be able to detect which rows should be included as part of a modification.

## SQL Mode

Vitess behaves similar to the `STRICT_TRANS_TABLES` sql mode, and does not recommend changing the SQL Mode setting.

## Network Protocol

### Authentication Plugins

Vitess supports both 5.7 and 8.0 authentication. E.g. `mysql_native_password`, `caching_sha2_password`, etc.

### Transport Security

To configure VTGate to support `TLS` set `--mysql_server_ssl_cert` and `--mysql_server_ssl_key`. Client certificates can also be mandated by setting `--mysql_server_ssl_ca`. If there is no CA specified then TLS is optional.

### X Dev API

Vitess does not support [X Dev API](https://dev.mysql.com/doc/x-devapi-userguide/en/).
