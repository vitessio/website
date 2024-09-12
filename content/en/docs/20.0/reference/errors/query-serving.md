---
title: Query Serving
weight: 1
description: Errors a users might encounter while querying Vitess
---

{{< info >}}
These error messages are internal to Vitess. If you are getting other errors from MySQL you can check them on this MySQL error [page](https://dev.mysql.com/doc/mysql-errors/8.0/en/server-error-reference.html).
{{< /info >}}

## New Errors
<!-- start -->

| ID | Description | Error | MySQL Error Code | SQL State |
| --- | --- | --- | --- | --- |
| VT03001 | This aggregation function only takes a single argument. | aggregate functions take a single argument '%s' | 1149 | 42000 |
| VT03002 | This schema change is not allowed. You cannot change the keyspace of a table. | changing schema from '%s' to '%s' is not allowed | 1450 | HY000 |
| VT03003 | The specified table in this DELETE statement is unknown. | unknown table '%s' in MULTI DELETE | 1109 | 42S02 |
| VT03004 | You cannot delete something that is not a real MySQL table. | the target table %s of the DELETE is not updatable | 1288 | HY000 |
| VT03005 | The planner does not allow grouping on certain field. For instance, aggregation function. | cannot group on '%s' | 1056 | 42000 |
| VT03006 | The number of columns you want to insert do not match the number of columns of your SELECT query. | column count does not match value count with the row | 1136 | 21S01 |
| VT03007 | You need to add a keyspace qualifier. | keyspace not specified | 0 |  |
| VT03008 | The given token is not usable in this situation. Please refer to the MySQL documentation to learn more about your token's syntax. | incorrect usage/placement of '%s' | 1234 | 42000 |
| VT03009 | You cannot assign this type to the given variable. | unexpected value type for '%s': %v | 1231 | 42000 |
| VT03010 | You cannot set the given variable as it is a read-only variable. | variable '%s' is a read only variable | 1238 | HY000 |
| VT03011 | The given value type is not accepted. | invalid value type: %v | 0 |  |
| VT03012 | The syntax is invalid. Please refer to the MySQL documentation for the proper syntax. | invalid syntax: %s | 0 |  |
| VT03013 | This table or alias name is already use. Please use another one that is unique. | not unique table/alias: '%s' | 1066 | 42000 |
| VT03014 | The given column is unknown. | unknown column '%s' in '%s' | 1054 | 42S22 |
| VT03015 | Cannot assign multiple values to a column in an update statement. | column has duplicate set values: '%v' | 0 |  |
| VT03016 | The given column is unknown in the vindex table. | unknown vindex column: '%s' | 0 |  |
| VT03017 | This vstream where clause can only be a greater than filter. | where clause can only be of the type 'pos > <value>' | 1149 | 42000 |
| VT03018 | You cannot use the NEXT syntax on a table that is not a sequence table. | NEXT used on a non-sequence table | 0 |  |
| VT03019 | The given column was not found or is not available. | column %s not found | 0 |  |
| VT03020 | The given column was not found in the subquery. | column %s not found in subquery | 0 |  |
| VT03021 | The given column is ambiguous. You can use a table qualifier to make it unambiguous. | ambiguous column reference: %v | 0 |  |
| VT03022 | The given column cannot be found. | column %v not found in %v | 0 |  |
| VT03023 | When targeting a range of shards, Vitess does not know which shard to send the INSERT to. | INSERT not supported when targeting a key range: %s | 0 |  |
| VT03024 | The query cannot be prepared using the user defined variable as it does not exists for this session. | '%s' user defined variable does not exists | 0 |  |
| VT03025 | The execute statement have wrong number of arguments | Incorrect arguments to %s | 1210 | HY000 |
| VT03024 | The query cannot be executed as missing the bind variable. | '%s' bind variable does not exists | 0 |  |
| VT03027 | The column cannot have null value. | Column '%s' cannot be null | 1048 | 23000 |
| VT03028 | The column cannot have null value. | Column '%s' cannot be null on row %d, col %d | 1048 | 23000 |
| VT03029 | The number of columns you want to insert do not match the number of columns of your SELECT query. | column count does not match value count with the row for vindex '%s' | 1136 | 21S01 |
| VT03030 | The number of columns you want to insert do not match the number of columns of your SELECT query. | lookup column count does not match value count with the row (columns, count): (%v, %d) | 1136 | 21S01 |
| VT03031 | EXPLAIN has to be sent down as a single query to the underlying MySQL, and this is not possible if it uses tables from multiple keyspaces | EXPLAIN is only supported for single keyspace | 0 |  |
| VT03032 | You cannot update a table that is not a real MySQL table. | the target table %s of the UPDATE is not updatable | 1288 | HY000 |
| VT03033 | The table column list and derived column list have different column counts. | In definition of view, derived table or common table expression, SELECT list and column names list have different column counts | 1353 | HY000 |
| VT05001 | The given database does not exist; Vitess cannot drop it. | cannot drop database '%s'; database does not exists | 1008 | HY000 |
| VT05002 | The given database does not exist; Vitess cannot alter it. | cannot alter database '%s'; unknown database | 1049 | 42000 |
| VT05003 | The given database does not exist in the VSchema. | unknown database '%s' in vschema | 1049 | 42000 |
| VT05004 | The given table is unknown. | table '%s' does not exist | 1109 | 42S02 |
| VT05005 | The given table does not exist in this keyspace. | table '%s' does not exist in keyspace '%s' | 1146 | 42S02 |
| VT05006 | The given system variable is unknown. | unknown system variable '%s' | 1193 | HY000 |
| VT05007 | Table information is not available. | no table info | 0 |  |
| VT06001 | The given database name already exists. | cannot create database '%s'; database exists | 1007 | HY000 |
| VT07001 | Kill statement is not allowed. More in docs about how to enable it and its limitations. | %s | 1095 | HY000 |
| VT09001 | the table does not have a primary vindex, the operation is impossible. | table '%s' does not have a primary vindex | 1173 | 42000 |
| VT09002 | This type of DML statement is not allowed on a replica target. | %s statement with a replica target | 1874 | HY000 |
| VT09003 | A vindex column is mandatory for the insert, please provide one. | INSERT query does not have primary vindex column '%v' in the column list | 0 |  |
| VT09004 | You need to provide the list of columns you want to insert, or provide a VSchema with authoritative columns. If schema tracking is disabled you can enable it to automatically have authoritative columns. | INSERT should contain column list or the table should have authoritative columns in vschema | 0 |  |
| VT09005 | A database must be selected. | no database selected: use keyspace<:shard><@type> or keyspace<[range]><@type> (<> are optional) | 1046 | 3D000 |
| VT09006 | VITESS_MIGRATION commands work only on primary tablets, you must send such commands to a primary tablet. | %s VITESS_MIGRATION works only on primary tablet | 0 |  |
| VT09007 | VITESS_THROTTLED_APPS commands work only on primary tablet, you must send such commands to a primary tablet. | %s VITESS_THROTTLED_APPS works only on primary tablet | 0 |  |
| VT09008 | vexplain queries/all will actually run queries. `/*vt+ EXECUTE_DML_QUERIES */` must be set to run DML queries in vtexplain. Example: `vexplain /*vt+ EXECUTE_DML_QUERIES */ queries delete from t1` | vexplain queries/all will actually run queries | 0 |  |
| VT09009 | Stream is only supported for primary tablets, please use a stream on those tablets. | stream is supported only for primary tablet type, current type: %v | 0 |  |
| VT09010 | SHOW VITESS_THROTTLER STATUS works only on primary tablet. | SHOW VITESS_THROTTLER STATUS works only on primary tablet | 0 |  |
| VT09011 | The prepared statement is not available | Unknown prepared statement handler (%s) given to %s | 1243 | HY000 |
| VT09012 | This type of statement is not allowed on the given tablet. | %s statement with %s tablet not allowed | 0 |  |
| VT09013 | Durability policy wants Vitess to use semi-sync, but the MySQL instances don't have the semi-sync plugin loaded. | semi-sync plugins are not loaded | 0 |  |
| VT09014 | The vindex cannot be used as table in DML statement | vindex cannot be modified | 0 |  |
| VT09015 | This query cannot be planned without more information on the SQL schema. Please turn on schema tracking or add authoritative columns information to your VSchema. | schema tracking required | 0 |  |
| VT09016 | SET DEFAULT is not supported by InnoDB | Cannot delete or update a parent row: a foreign key constraint fails | 1451 | 23000 |
| VT09017 | Invalid syntax for the statement type. | %s | 0 |  |
| VT09018 | Invalid syntax for the vindex function statement. | %s | 0 |  |
| VT09019 | Vitess doesn't support cyclic foreign keys. | keyspace '%s' has cyclic foreign keys. Cycle exists between %v | 0 |  |
| VT09020 | Vitess does not allow using multiple vindex hints on the same table. | can not use multiple vindex hints for table %s | 0 |  |
| VT09021 | Vindex hints have to reference an existing vindex, and no such vindex could be found for the given table. | Vindex '%s' does not exist in table '%s' | 1176 | 42000 |
| VT09022 | Cannot send query to multiple shards. | Destination does not have exactly one shard: %v | 0 |  |
| VT09023 | Unable to determine the shard for the given row. | could not map %v to a keyspace id | 0 |  |
| VT09024 | Unable to determine the shard for the given row. | could not map %v to a unique keyspace id: %v | 0 |  |
| VT09026 |  | Recursive Common Table Expression '%s' should contain a UNION | 3573 | HY000 |
| VT09027 |  | Recursive Common Table Expression '%s' can contain neither aggregation nor window functions in recursive query block | 3575 | HY000 |
| VT09028 |  | In recursive query block of Recursive Common Table Expression '%s', the recursive table must neither be in the right argument of a LEFT JOIN, nor be forced to be non-first with join order hints | 3576 | HY000 |
| VT09029 |  | In recursive query block of Recursive Common Table Expression %s, the recursive table must be referenced only once, and not in any subquery | 3577 | HY000 |
| VT10001 | Foreign key constraints are not allowed, see https://vitess.io/blog/2021-06-15-online-ddl-why-no-fk/. | foreign key constraints are not allowed | 0 |  |
| VT10002 | The distributed transaction cannot be committed. A rollback decision is taken. | atomic distributed transaction not allowed: %s | 0 |  |
| VT12001 | This statement is unsupported by Vitess. Please rewrite your query to use supported syntax. | unsupported: %s | 0 |  |
| VT12002 | Vitess does not support cross shard foreign keys. | unsupported: cross-shard foreign keys | 0 |  |
| VT13001 | This error should not happen and is a bug. Please file an issue on GitHub: https://github.com/vitessio/vitess/issues/new/choose. | [BUG] %s | 0 |  |
| VT13002 | This error should not happen and is a bug. Please file an issue on GitHub: https://github.com/vitessio/vitess/issues/new/choose. | unexpected AST struct for query: %s | 0 |  |
| VT14001 | The connection failed. | connection error | 0 |  |
| VT14002 | No available connection. | no available connection | 0 |  |
| VT14003 | No connection for the given tablet. | no connection for tablet %v | 0 |  |
| VT14004 | The specified keyspace could not be found. | cannot find keyspace for: %s | 0 |  |
| VT14005 | Failed to read sidecar database identifier. | cannot lookup sidecar database for keyspace: %s | 0 |  |
<!-- end -->

## Old Errors
| Error Number | Error State |  Message | Meaning |
| :--: |:--: | :-- | -- |
| 1192 | HY000 | Can't execute the given command because you have an active transaction | The provided statement cannot be executed inside a transaction. |
| 1231 | 42000 | invalid transaction_mode: %s | Valid transaction_mode values are 'SINGLE', 'MULTI' or 'TWOPC'. |
| 1231 | 42000 | invalid workload: %s | Valid workload values are 'OLTP', 'OLAP' or 'DBA'. |
| 1231 | 42000 | invalid DDL strategy: %s | Valid DDL strategies are gh-ost, pt-osc. |
| 1690 | 22003 | %s value is out of range in %v [+,-,*,/] %v | Arithmetic operation lead to out of range value for the type. |
| 1047 | 42000 | connection ID and transaction ID do not exist | The session is pointing to a transaction and/or reserved connection that is not valid. |
| 1105 | HY000 | %d is not a boolean | Tried setting a system variable to a value that could not be converted a boolean value.  |
| 1105 | HY000 | %s is not a sequence | The given table is not a sequence table. |
| 1105 | HY000 | %v cannot be converted to a go type | This type can't be represented as a golang value. |
| 1105 | HY000 | 2pc is not enabled | This functionality requires 2PC. Read more about 'transaction_mode' to learn how to enable it. |
| 1105 | HY000 | GTIDSet Mismatch: requested source position:%v, current target vrep position: %v | The requested GTIDSet does not exist in the vrep stream.  |
| 1105 | HY000 | No target | TODO https://github.com/vitessio/vitess/blob/9542883311c0849c645cfb1b5c77ac761990b31b/go/vt/vttablet/tabletserver/state_manager.go#L376 |
| 1105 | HY000 | Unexpected error, DestinationKeyspaceID mapping to multiple shards | This is an internal error. If you see this error, please report it as a bug. |
| 1105 | HY000 | auto sequence generation can happen through single shard only, it is getting routed to %d shards | A sequence query has to be routed to a single shard, but this query was not. |
| 1105 | HY000 | could not parse value: '%s' | Tried parsing a value as a number but failed. |
| 1105 | HY000 | disallowed due to rule: %s | The query was not permitted to execute because the session was lacking permissions to do so. |
| 1105 | HY000 | invalid increment for sequence %s: %d | The given sequence increment is incorrect it should be equal or greater than zero. |
| 1105 | HY000 | invalid keyspace %v does not match expected %v | The given keyspace target does not match this tablet's keyspace name. |
| 1105 | HY000 | invalid shard %v does not match expected %v | The given shard target does not match this tablet's shard. |
| 1105 | HY000 | invalid table name: %s | The table name contains invalid characters. |
| 1105 | HY000 | [%d,'%s'] is not a boolean | This error will be returned if you try to set a variable to a value that can't be converted to a boolean value. |
| 1105 | HY000 | negative number cannot be converted to unsigned: %d | The column or variable is expecting an unsigned int, and negative numbers invalid here. |
| 1105 | HY000 | query arguments missing for %s | Argument expected but was missing. |
| 1105 | HY000 | require autocommit to be 1: got %s | Connection needs autocommit to be enabled, but it was not. |
| 1105 | HY000 | require sql_auto_is_null to be 0: got %s | Vitess requires the connection not use the auto_col functionality. |
| 1105 | HY000 | require sql_mode to be STRICT_TRANS_TABLES or STRICT_ALL_TABLES: got '%s' | Vitess requires the connection to be in STRICT mode; either or both of these settings need to be enabled. |
| 1105 | HY000 | unexpected rows from reading sequence %s (possible mis-route): %d | The sequence table used returned invalid results. |
| 1105 | HY000 | unsigned number overflows int64 value: %d | Tried to convert an unsigned integer into a signed integer, and the value overflows. |
