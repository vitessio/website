---
title: Query Serving
weight: 1
description: Errors a users might encounter while querying Vitess
---

{{< info >}}
These error messages are internal to Vitess. If you are getting other errors from MySQL you can check them on this MySQL error [page](https://dev.mysql.com/doc/mysql-errors/5.7/en/server-error-reference.html).
{{< /info >}}

<!-- start -->
## Errors

| ID | Description | Error | MySQL Error Code | SQL State |
| --- | --- | --- | --- | --- |
| VT03001 | The planner only accepts aggregate functions that take a single argument. | aggregate functions take a single argument '%s' | 1149 | 42000 |
| VT03002 | This schema change is not allowed. You cannot change the keyspace of a table. | changing schema from '%s' to '%s' is not allowed | 1450 | HY000 |
| VT03003 | The specified table in this DELETE statement is unknown. | unknown table '%s' in MULTI DELETE | 1109 | 42S02 |
| VT03004 | You cannot delete something that is not a real MySQL table. | the target table %s of the DELETE is not updatable | 1288 | HY000 |
| VT03005 | The planner does not allow grouping on certain field. For instance, aggregation function. | cannot group on '%s' | 1056 | 42000 |
| VT03006 | The number of columns you want to insert do not match the number of columns of your SELECT query. | column count does not match value count at row 1 | 1136 | 21S01 |
| VT03007 | You need to add a keyspace qualifier. | keyspace not specified | 0 |  |
| VT03008 | The given token is not usable in this situation. Please refer to the MySQL documentation to learn more about your token's syntax. | incorrect usage/placement of '%s' | 1234 | 42000 |
| VT03009 | You cannot assign this type to the given variable. | unexpected value type for '%s': %v | 1231 | 42000 |
| VT03010 | You cannot set the given variable as it is a read-only variable. | variable '%s' is a read only variable | 1238 | HY000 |
| VT03011 | The given value type is not accepted. | invalid value type: %v | 0 |  |
| VT03012 | The syntax is invalid. Please refer to the MySQL documentation for the proper syntax. | invalid syntax: %s | 0 |  |
| VT03013 | This table or alias name is already use. Please use another one that is unique. | not unique table/alias: '%s' | 1066 | 42000 |
| VT03014 | The given column is unknown. | unknown column '%d' in '%s' | 1054 | 42S22 |
| VT03015 | You cannot assign more than one value to the same vindex. | column has duplicate set values: '%v' | 0 |  |
| VT03016 | The given column is unknown in the vindex table. | unknown vindex column: '%s' | 0 |  |
| VT03017 | This vstream where clause can only be a greater than filter. | where clause can only be of the type 'pos > <value>' | 1149 | 42000 |
| VT03018 | You cannot use the NEXT syntax on a table that is not a sequence table. | NEXT used on a non-sequence table | 0 |  |
| VT03019 | The given symbol was not found or is not available. | symbol %s not found | 0 |  |
| VT03020 | The given symbol was not found in the subquery. | symbol %s not found in subquery | 0 |  |
| VT03021 | The given symbol is ambiguous. You can use a table qualifier to make it unambiguous. | ambiguous symbol reference: %v | 0 |  |
| VT03022 | The given column cannot be found. | column %v not found in %v | 0 |  |
| VT03023 | INSERTs are not supported with key range targets. | INSERT not supported when targeting a key range: %s | 0 |  |
| VT05001 | The given database does not exist; Vitess cannot drop it. | cannot drop database '%s'; database does not exists | 1008 | HY000 |
| VT05002 | The given database does not exist; Vitess cannot alter it. | cannot alter database '%s'; unknown database | 1049 | 42000 |
| VT05003 | The given database does not exist in the VSchema. | unknown database '%s' in vschema | 1049 | 42000 |
| VT05004 | The given table is unknown. | table '%s' does not exist | 1109 | 42S02 |
| VT05005 | The given table does not exist in this keyspace. | table '%s' does not exist in keyspace '%s' | 1146 | 42S02 |
| VT05006 | The given system variable is unknown. | unknown system variable '%s' | 1193 | HY000 |
| VT05007 | Table information is not available. | no table info | 0 |  |
| VT06001 | The given database name already exists. | cannot create database '%s'; database exists | 1007 | HY000 |
| VT09001 | the table does not have a primary vindex, the operation is impossible. | table '%s' does not have a primary vindex | 1173 | 42000 |
| VT09002 | This type of DML statement is not allowed on a replica target. | %s statement with a replica target | 1874 | HY000 |
| VT09003 | A sharding column is mandatory for the insert, please provide one. | INSERT query does not have sharding column '%v' in the column list | 0 |  |
| VT09004 | You need to provide the list of columns you want to insert, or provide a VSchema with authoritative columns. If schema tracking is disabled you can enable it to automatically have authoritative columns. | INSERT should contain column list or the table should have authoritative columns in vschema | 0 |  |
| VT09005 | A database must be selected. | no database selected: use keyspace<:shard><@type> or keyspace<[range]><@type> (<> are optional) | 1046 | 3D000 |
| VT09006 | VITESS_MIGRATION commands work only on primary tablets, you must send such commands to a primary tablet. | %s VITESS_MIGRATION works only on primary tablet | 0 |  |
| VT09007 | VITESS_THROTTLED_APPS commands work only on primary tablet, you must send such commands to a primary tablet. | %s VITESS_THROTTLED_APPS works only on primary tablet | 0 |  |
| VT09008 | explain format = vtexplain will actually run queries. `/*vt+ EXECUTE_DML_QUERIES */` must be set to run DML queries in vtexplain. Example: `explain /*vt+ EXECUTE_DML_QUERIES */ format = vtexplain delete from t1`. | explain format = vtexplain will actually run queries | 0 |  |
| VT09009 | Stream is only supported for primary tablets, please use a stream on those tablets. | stream is supported only for primary tablet type, current type: %v | 0 |  |
| VT09010 | SHOW VITESS_THROTTLER STATUS works only on primary tablet. | SHOW VITESS_THROTTLER STATUS works only on primary tablet | 0 |  |
| VT10001 | Foreign key constraints are not allowed, see https://vitess.io/blog/2021-06-15-online-ddl-why-no-fk/. | foreign key constraints are not allowed | 0 |  |
| VT12001 | This statement is unsupported by Vitess. Please rewrite your query to use supported syntax. | unsupported: %s | 0 |  |
| VT13001 | This error should not happen and is a bug. Please file an issue on GitHub: https://github.com/vitessio/vitess/issues/new/choose. | [BUG] %s | 0 |  |
| VT13002 | This error should not happen and is a bug. Please file an issue on GitHub: https://github.com/vitessio/vitess/issues/new/choose. | unexpected AST struct for query: %s | 0 |  |
| VT14001 | The connection failed. | connection error | 0 |  |
| VT14002 | No available connection. | no available connection | 0 |  |
| VT14003 | No connection for the given tablet. | no connection for tablet %v | 0 |  |
| VT14004 | The specified keyspace could not be found. | cannot find keyspace for: %s | 0 |  |
<!-- end -->
