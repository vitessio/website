---
title: Query Serving
weight: 1
description: Errors a users might encounter while querying Vitess
---

{{< info >}}
These error messages are internal to Vitess. If you are getting other errors from MySQL you can check them on this MySQL error [page](https://dev.mysql.com/doc/mysql-errors/5.7/en/server-error-reference.html).
{{< /info >}}

| Error Number | Error State |  Message | Meaning |
| :--: |:--: | :-- | -- |
| 1105 | HY000 | INSERT not supported when targeting a key range: %s | When targeting a range of shards, Vitess doesn't know which shard to send the INSERT to, so this is not supported.  |
| 1450 | HY000 | Changing schema from '%s' to '%s' is not allowed | Changing schema from rename command is not valid |
| 1149 | 42000 | aggregate functions take a single argument '%s' | This function only takes a single argument. |
| 1238 | HY000 | Variable '%s' is a read only variable | Tried changing a read-only system variable |
| 1105 | HY000 | column has duplicate set values: '%v' | Cannot assign multiple values to a column in an update statement |
| 1231 | 42000 | unexpected value type for '%s': %v | Some system variables require a specific type to be used |
| 1192 | HY000 | Can't execute the given command because you have an active transaction | The provided statement cannot be executed inside a transaction. |
| 1231 | 42000 | invalid transaction_mode: %s | Valid transaction_mode values are 'SINGLE', 'MULTI' or 'TWOPC' |
| 1231 | 42000 | invalid workload: %s | Valid workload values are 'OLTP', 'OLAP' or 'DBA' |
| 1231 | 42000 | invalid DDL strategy: %s | Valid DDL strategies are gh-ost, pt-osc |
| 1690 | 22003 | %s value is out of range in %v [+,-,*,/] %v | Arithmetic operation lead to out of range value for the type |
| 1047 | 42000 | connection ID and transaction ID do not exist | The session is pointing to a transaction and/or reserved connection that is not valid |
| 1105 | HY000 | %d is not a boolean | Tried setting a system variable to a value that could not be converted a boolean value  |
| 1105 | HY000 | %s is not a sequence | The given table is not a sequence table |
| 1105 | HY000 | %s: system setting is not supported | Tried reading or setting a system variable that is not supported |
| 1105 | HY000 | %v cannot be converted to a go type | This type can't be represented as a golang value |
| 1105 | HY000 | 2pc is not enabled | This functionality requires 2PC. Read more about 'transaction_mode' to learn how to enable it. |
| 1105 | HY000 | Destination can only be a single shard for statement: %s, got: %v | This statement type can only be executed against a single shard. You need to change the target string so a single shard in targeted.|
| 1105 | HY000 | GTIDSet Mismatch: requested source position:%v, current target vrep position: %v | The requested GTIDSet does not exist in the vrep stream.  |
| 1105 | HY000 | No target | TODO https://github.com/vitessio/vitess/blob/9542883311c0849c645cfb1b5c77ac761990b31b/go/vt/vttablet/tabletserver/state_manager.go#L376 |
| 1105 | HY000 | Unexpected error, DestinationKeyspaceID mapping to multiple shards | This is an internal error. If you see this error, please report it as a bug. |
| 1105 | HY000 | auto sequence generation can happen through single shard only, it is getting routed to %d shards | A sequence query has to be routed to a single shard, but this query was not. |
| 1105 | HY000 | cannot mix scope and user defined variables | If you use the `SET GLOBAL` form, specify the variable without any `@` symbols |
| 1105 | HY000 | cannot use scope and @@ | If you use the `SET GLOBAL` form, specify the variable without any `@` symbols |
| 1105 | HY000 | column has duplicate set values: '%v' | An UPDATE query should only list a column to be updated once |
| 1105 | HY000 | could not parse value: '%s' | Tried parsing a value as a number but failed |
| 1105 | HY000 | disallowed due to rule: %s | The query was not permitted to execute because the session was lacking permissions to do so |
| 1105 | HY000 | expression is too complex '%v' | An expression was used that is not recognized by Vitess. Arithmetics and function calls are examples of expressions that are too complex in this context.|
| 1105 | HY000 | invalid increment for sequence %s: %d | TODO |
| 1105 | HY000 | invalid keyspace %v does not match expected %v | TODO |
| 1105 | HY000 | invalid shard %v does not match expected %v | TODO |
| 1105 | HY000 | invalid table name: %s | The table name contains invalid characters |
| 1105 | HY000 | is not a boolean | This error will be returned if you try to set a variable to a value that can't be converted to a boolean value. |
| 1105 | HY000 | negative number cannot be converted to unsigned: %d | The column or variable is expecting an unsigned int, and negative numbers invalid here. |
| 1105 | HY000 | query arguments missing for %s | Argument expected but was missing. |
| 1105 | HY000 | require autocommit to be 1: got %s | Connection needs autocommit to be enabled, but it was not. |
| 1105 | HY000 | require sql_auto_is_null to be 0: got %s | Vitess requires the connection not use the auto_col functionality |
| 1105 | HY000 | require sql_mode to be STRICT_TRANS_TABLES or STRICT_ALL_TABLES: got '%s' | Vitess requires the connection to be in STRICT mode; either or both of these settings need to be enabled. |
| 1105 | HY000 | unexpected rows from reading sequence %s (possible mis-route): %d | The sequence table used returned invalid results. |
| 1105 | HY000 | unsigned number overflows int64 value: %d | Tried to convert an unsigned integer into a signed integer, and the value overflows |
