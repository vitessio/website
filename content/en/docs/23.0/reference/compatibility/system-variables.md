---
title: System Variables
description: How VTGate handles MySQL system variables and the Vitess-specific session variables
weight: 2
---

## Introduction

Applications connect to VTGate, not to MySQL, and VTGate shares pooled MySQL connections between sessions. So VTGate can't simply pass a `SET` statement on to MySQL. It handles every system variable itself, in one of these ways:

* [Vitess-aware](#vitess-aware-variables): the variable is Vitess-specific or changes how VTGate behaves, and VTGate keeps its value in the session. `SET` never reaches MySQL.
* [Connection setting](#connection-settings): VTGate applies the value to the MySQL connections that run the session's queries.
* [Ignored](#ignored-variables): VTGate accepts the `SET` but doesn't change anything.
* [Read-only](#read-only-variables): `SET` returns an error.
* [Not supported](#unsupported-variables): `SET` returns an error.

Setting a session variable that isn't in the [list of system variables](#list-of-system-variables) returns an error such as `VT05006: unknown system variable '@@foo = 1'`.

## Setting variables

`SET var = value`, `SET SESSION var = value`, `SET LOCAL var = value`, `SET @@var = value` and `SET @@session.var = value` all change the variable for the current session. VTGate handles them as described for each kind of variable below.

`SET var = DEFAULT` works only for the Vitess-aware variables `autocommit`, `charset`, `client_found_rows`, `enable_system_settings`, `names`, `skip_query_plan_cache`, `sql_select_limit`, `transaction_read_only` and `tx_read_only`. For any other variable it returns an error.

### Global variables

VTGate doesn't change global variables. It accepts `SET GLOBAL var = value` and `SET @@global.var = value` for any variable but doesn't apply the value anywhere. The statement doesn't return an error or a warning, unless the value is an [unsupported SQL mode](#sql-mode). To change a global variable, change it in the MySQL configuration of every tablet, or run the statement on each tablet with [`vtctldclient ExecuteFetchAsDBA`](../../programs/vtctldclient/vtctldclient_executefetchasdba/).

### Next-transaction scope

`SET TRANSACTION ISOLATION LEVEL ...` and `SET TRANSACTION READ ONLY`/`READ WRITE` change the `transaction_isolation` and `transaction_read_only` variables. In MySQL they apply only to the next transaction, but VTGate applies them to the session, as if they had the `SESSION` keyword, and returns warning 1235: `converted 'next transaction' scope to 'session' scope`. So the isolation level stays in effect for the rest of the session, like any other [connection setting](#connection-settings). `transaction_read_only` has [no effect](#vitess-aware-variables).

## Reading variables

VTGate fills in the value of `@@var` and `@@session.var` in a query itself, without reading it from MySQL, for:

* The Vitess-aware variables, except `transaction_read_only` and `tx_read_only`.
* The read-only variables `version`, `version_comment` and `socket`. `@@version` is the MySQL version that VTGate advertises, set with the VTGate `--mysql-server-version` flag, and `@@version_comment` is the Vitess version.
* Connection settings that the session has changed. VTGate returns the session's value.

Other variables, and every `@@global.var`, are read from the MySQL server of a tablet, so they return that server's value.

`SHOW VARIABLES` and `SHOW SESSION VARIABLES` also go to a tablet. VTGate replaces the values of `autocommit`, `sql_select_limit`, `version`, `version_comment` and `socket` in the output with its own, and does the same for some of the connection settings that the session has changed. Variables that MySQL doesn't have, such as `workload`, aren't in the output. Use `SELECT @@workload` to read them.

## Vitess-aware variables

VTGate keeps these variables in the session. Setting them never sends a statement to MySQL. The initial values are those of a session that connects with the MySQL protocol.

| Variable | Values | Initial value | Description |
|----------|--------|---------------|-------------|
| `autocommit` | `0` or `1`, also `OFF` or `ON` | `1` | Whether each statement outside an explicit transaction is committed on its own, as in MySQL. |
| `client_found_rows` | `0` or `1` | `1` if the client connected with the `CLIENT_FOUND_ROWS` capability flag, otherwise `0` | When `1`, the affected-rows count of an `UPDATE` is the number of rows it matched instead of the number of rows it changed. |
| `charset`, `names` | `utf8`, `utf8mb4`, `latin1` or `default` | | Set by `SET NAMES ...` and `SET CHARACTER SET ...`. VTGate accepts these values and rejects any other with `charset/name ... is not supported`, but the statement doesn't change the connection character set. See [Collations](../../../user-guides/configuration-basic/collations/#configuring-the-default-connection-charset-for-a-vitess-cluster). |
| `ddl_strategy` | A DDL strategy, such as `vitess --postpone-completion` | The VTGate `--ddl-strategy` flag, `direct` by default | The strategy for DDL statements in the session. See [DDL strategies](../../../user-guides/schema-changes/ddl-strategies/). |
| `enable_system_settings` | `0` or `1` | The VTGate `--enable-system-settings` flag, `true` by default | Whether VTGate applies [connection settings](#connection-settings) for the session. When `0`, it ignores them. |
| `migration_context` | Letters, digits, `_`, `-` and `:` | Empty | The migration context of Online DDL migrations that the session submits. When empty, VTGate uses `@@session_uuid`. See [Advanced usage](../../../user-guides/schema-changes/advanced-usage/#duplicate-migration-detection). |
| `query_timeout` | Milliseconds | `0` | The timeout for each query in the session. `0` means the VTGate `--query-timeout` flag applies. A [`QUERY_TIMEOUT_MS`](../../../user-guides/configuration-advanced/comment-directives/#query-timeouts-query_timeout_ms) comment directive overrides it for a single query. |
| `session_uuid` | | A random UUID | Identifies the VTGate session. It can be read but not set: `SET session_uuid` returns `unknown system variable 'session_uuid'`. |
| `skip_query_plan_cache` | `0` or `1` | `0` | When `1`, VTGate and VTTablet don't cache the query plans of the session's queries. The [`SKIP_QUERY_PLAN_CACHE`](../../../user-guides/configuration-advanced/comment-directives/#skip-query-plan-cache-skip_query_plan_cache) comment directive does the same for a single query. |
| `sql_select_limit` | A number of rows | `0` | When greater than `0`, VTGate adds `LIMIT` with this value to every top-level `SELECT` or `UNION` that doesn't have a `LIMIT`. `0` means no limit. Unlike in MySQL, `0` doesn't make `SELECT` return no rows. |
| `transaction_mode` | `SINGLE`, `MULTI`, `TWOPC` or `UNSPECIFIED`, in any case | `UNSPECIFIED`, which uses the VTGate `--transaction-mode` flag, `MULTI` by default | Whether a transaction can span shards and how it's committed. `SELECT @@transaction_mode` returns the mode in effect. See [Distributed transactions](../../features/distributed-transaction/). |
| `transaction_timeout` | Milliseconds | `0` | The maximum duration of the session's transactions. See [Transaction timeouts](../mysql-compatibility/#transaction-timeouts). |
| `workload` | `OLTP`, `OLAP`, `DBA` or `UNSPECIFIED`, in any case | The VTGate `--mysql-default-workload` flag, `OLTP` by default | The workload of the session. See [Workload](../mysql-compatibility/#workload). |
| `transaction_read_only`, `tx_read_only` | `0` or `1` | `0` | VTGate accepts these but ignores the value. Transactions aren't made read-only, and `SELECT @@transaction_read_only` returns the value from MySQL. |
| `read_after_write_gtid`, `read_after_write_timeout`, `session_track_gtids` | A string, a number, and `off` or `own_gtid` | Empty, `0` and `off` | VTGate stores these values and returns them from `SELECT`, but they don't change how it runs queries. |

An invalid value returns an error, for example `invalid transaction_mode: two_pc` or `invalid workload: batch`.

## Connection settings

Connection settings are MySQL session variables that change how MySQL runs a query, such as `sql_mode`, `time_zone`, `transaction_isolation`, `foreign_key_checks` or `sql_safe_updates`.

When a session sets one of them, VTGate first evaluates the new value on a tablet. If it's the same as the variable's current value in MySQL, nothing changes and the session keeps using shared connections as before. Otherwise VTGate stores the value in the session and applies it to every query that the session runs from then on:

* If MySQL supports the variable in a [`SET_VAR` optimizer hint](https://dev.mysql.com/doc/refman/8.4/en/optimizer-hints.html#optimizer-hints-set-var), VTGate adds the hint to each query, for example `select /*+ SET_VAR(sql_safe_updates = 1) */ ...`. The query runs on a shared connection as usual. VTGate uses the hint only with MySQL 8.0 and later, and not when the VTGate `--enable-set-var` flag is `false`. The flag is `true` by default.
* Otherwise VTTablet runs the session's queries on connections that have the setting applied. It keeps such connections in its connection pool and reuses them for any session with the same settings. See [Reserved connections](../../query-serving/reserved-conn/).

To keep connection pooling as effective as possible, set the global value in MySQL to the value that your application uses, so that its `SET` statements don't change anything.

If the VTGate `--enable-system-settings` flag is `false`, or the session has set `enable_system_settings` to `0`, VTGate [ignores](#ignored-variables) connection settings instead.

### SQL mode

VTGate rejects a `sql_mode` that includes a mode that changes how SQL text is parsed, because the Vitess parser doesn't support it: `ANSI`, `ANSI_QUOTES`, `HIGH_NOT_PRECEDENCE`, `IGNORE_SPACE`, `NO_BACKSLASH_ESCAPES`, `PIPES_AS_CONCAT` and `REAL_AS_FLOAT`. For example, `SET sql_mode = 'ANSI_QUOTES'` returns `setting the ANSI_QUOTES sql_mode is unsupported`. It does this even when connection settings are turned off, and for `SET GLOBAL sql_mode`.

## Ignored variables

VTGate accepts a `SET` of a variable listed as ignored with any value, but doesn't apply it and doesn't return an error or a warning. The session keeps using the value configured in MySQL.

`character_set_client`, `character_set_connection`, `character_set_results` and `collation_connection` are ignored too, but VTGate rejects a character set that Vitess can't handle safely. See [Collations](../../../user-guides/configuration-basic/collations/#configuring-the-default-connection-charset-for-a-vitess-cluster).

## Read-only variables

`version`, `version_comment` and `socket` can only be read. Setting them returns `VT03010: variable 'version' is a read only variable`.

## Unsupported variables

Setting one of the variables listed as not supported, such as `auto_increment_increment`, `auto_increment_offset` or `binlog_row_image`, returns an error such as `VT12001: unsupported: system setting: auto_increment_increment`.

## List of system variables

| Variable | Handling |
|----------|----------|
| `audit_log_read_buffer_size` | [Not supported](#unsupported-variables) |
| `auto_increment_increment` | [Not supported](#unsupported-variables) |
| `auto_increment_offset` | [Not supported](#unsupported-variables) |
| `autocommit` | [Vitess-aware](#vitess-aware-variables) |
| `big_tables` | [Ignored](#ignored-variables) |
| `binlog_direct_non_transactional_updates` | [Not supported](#unsupported-variables) |
| `binlog_format` | [Ignored](#ignored-variables) |
| `binlog_row_image` | [Not supported](#unsupported-variables) |
| `binlog_rows_query_log_events` | [Not supported](#unsupported-variables) |
| `block_encryption_mode` | [Ignored](#ignored-variables) |
| `bulk_insert_buffer_size` | [Ignored](#ignored-variables) |
| `character_set_client` | [Ignored](#ignored-variables) |
| `character_set_connection` | [Ignored](#ignored-variables) |
| `character_set_database` | [Ignored](#ignored-variables) |
| `character_set_filesystem` | [Ignored](#ignored-variables) |
| `character_set_results` | [Ignored](#ignored-variables) |
| `character_set_server` | [Ignored](#ignored-variables) |
| `charset` | [Vitess-aware](#vitess-aware-variables) |
| `client_found_rows` | [Vitess-aware](#vitess-aware-variables) |
| `collation_connection` | [Ignored](#ignored-variables) |
| `collation_database` | [Ignored](#ignored-variables) |
| `collation_server` | [Ignored](#ignored-variables) |
| `completion_type` | [Ignored](#ignored-variables) |
| `ddl_strategy` | [Vitess-aware](#vitess-aware-variables) |
| `debug` | [Ignored](#ignored-variables) |
| `default_storage_engine` | [Ignored](#ignored-variables) |
| `default_tmp_storage_engine` | [Ignored](#ignored-variables) |
| `default_week_format` | [Connection setting](#connection-settings) |
| `div_precision_increment` | [Ignored](#ignored-variables) |
| `enable_system_settings` | [Vitess-aware](#vitess-aware-variables) |
| `end_markers_in_json` | [Connection setting](#connection-settings) |
| `eq_range_index_dive_limit` | [Connection setting](#connection-settings) |
| `explicit_defaults_for_timestamp` | [Connection setting](#connection-settings) |
| `foreign_key_checks` | [Connection setting](#connection-settings) |
| `group_concat_max_len` | [Connection setting](#connection-settings) |
| `information_schema_stats_expiry` | [Connection setting](#connection-settings) |
| `innodb_ft_enable_stopword` | [Not supported](#unsupported-variables) |
| `innodb_ft_user_stopword_table` | [Not supported](#unsupported-variables) |
| `innodb_lock_wait_timeout` | [Connection setting](#connection-settings) |
| `innodb_strict_mode` | [Ignored](#ignored-variables) |
| `innodb_support_xa` | [Ignored](#ignored-variables) |
| `innodb_table_locks` | [Ignored](#ignored-variables) |
| `innodb_tmpdir` | [Ignored](#ignored-variables) |
| `interactive_timeout` | [Ignored](#ignored-variables) |
| `join_buffer_size` | [Ignored](#ignored-variables) |
| `keep_files_on_create` | [Ignored](#ignored-variables) |
| `lc_messages` | [Ignored](#ignored-variables) |
| `lc_time_names` | [Ignored](#ignored-variables) |
| `lock_wait_timeout` | [Ignored](#ignored-variables) |
| `long_query_time` | [Ignored](#ignored-variables) |
| `low_priority_updates` | [Ignored](#ignored-variables) |
| `max_allowed_packet` | [Ignored](#ignored-variables) |
| `max_delayed_threads` | [Ignored](#ignored-variables) |
| `max_error_count` | [Ignored](#ignored-variables) |
| `max_execution_time` | [Ignored](#ignored-variables) |
| `max_heap_table_size` | [Connection setting](#connection-settings) |
| `max_insert_delayed_threads` | [Ignored](#ignored-variables) |
| `max_join_size` | [Ignored](#ignored-variables) |
| `max_length_for_sort_data` | [Ignored](#ignored-variables) |
| `max_points_in_geometry` | [Not supported](#unsupported-variables) |
| `max_seeks_for_key` | [Connection setting](#connection-settings) |
| `max_sort_length` | [Ignored](#ignored-variables) |
| `max_sp_recursion_depth` | [Not supported](#unsupported-variables) |
| `max_tmp_tables` | [Connection setting](#connection-settings) |
| `max_user_connections` | [Ignored](#ignored-variables) |
| `migration_context` | [Vitess-aware](#vitess-aware-variables) |
| `min_examined_row_limit` | [Connection setting](#connection-settings) |
| `multi_range_count` | [Ignored](#ignored-variables) |
| `myisam_repair_threads` | [Not supported](#unsupported-variables) |
| `myisam_sort_buffer_size` | [Not supported](#unsupported-variables) |
| `myisam_stats_method` | [Not supported](#unsupported-variables) |
| `names` | [Vitess-aware](#vitess-aware-variables) |
| `ndb_allow_copying_alter_table` | [Not supported](#unsupported-variables) |
| `ndb_autoincrement_prefetch_sz` | [Not supported](#unsupported-variables) |
| `ndb_blob_read_batch_bytes` | [Not supported](#unsupported-variables) |
| `ndb_blob_write_batch_bytes` | [Not supported](#unsupported-variables) |
| `ndb_deferred_constraints` | [Not supported](#unsupported-variables) |
| `ndb_force_send` | [Not supported](#unsupported-variables) |
| `ndb_fully_replicated` | [Not supported](#unsupported-variables) |
| `ndb_index_stat_enable` | [Not supported](#unsupported-variables) |
| `ndb_index_stat_option` | [Not supported](#unsupported-variables) |
| `ndb_join_pushdown` | [Not supported](#unsupported-variables) |
| `ndb_log_bin` | [Not supported](#unsupported-variables) |
| `ndb_log_exclusive_reads` | [Not supported](#unsupported-variables) |
| `ndb_row_checksum` | [Not supported](#unsupported-variables) |
| `ndb_use_exact_count` | [Not supported](#unsupported-variables) |
| `ndb_use_transactions` | [Not supported](#unsupported-variables) |
| `ndbinfo_max_bytes` | [Not supported](#unsupported-variables) |
| `ndbinfo_max_rows` | [Not supported](#unsupported-variables) |
| `ndbinfo_show_hidden` | [Not supported](#unsupported-variables) |
| `ndbinfo_table_prefix` | [Not supported](#unsupported-variables) |
| `net_buffer_length` | [Ignored](#ignored-variables) |
| `net_read_timeout` | [Ignored](#ignored-variables) |
| `net_retry_count` | [Ignored](#ignored-variables) |
| `net_write_timeout` | [Ignored](#ignored-variables) |
| `new` | [Ignored](#ignored-variables) |
| `old_alter_table` | [Not supported](#unsupported-variables) |
| `old_passwords` | [Connection setting](#connection-settings) |
| `optimizer_prune_level` | [Connection setting](#connection-settings) |
| `optimizer_search_depth` | [Connection setting](#connection-settings) |
| `optimizer_switch` | [Connection setting](#connection-settings) |
| `optimizer_trace` | [Connection setting](#connection-settings) |
| `optimizer_trace_features` | [Connection setting](#connection-settings) |
| `optimizer_trace_limit` | [Connection setting](#connection-settings) |
| `optimizer_trace_max_mem_size` | [Connection setting](#connection-settings) |
| `optimizer_trace_offset` | [Connection setting](#connection-settings) |
| `parser_max_mem_size` | [Connection setting](#connection-settings) |
| `preload_buffer_size` | [Not supported](#unsupported-variables) |
| `profiling` | [Connection setting](#connection-settings) |
| `profiling_history_size` | [Connection setting](#connection-settings) |
| `query_alloc_block_size` | [Connection setting](#connection-settings) |
| `query_cache_type` | [Ignored](#ignored-variables) |
| `query_cache_wlock_invalidate` | [Ignored](#ignored-variables) |
| `query_prealloc_size` | [Ignored](#ignored-variables) |
| `query_timeout` | [Vitess-aware](#vitess-aware-variables) |
| `range_alloc_block_size` | [Connection setting](#connection-settings) |
| `range_optimizer_max_mem_size` | [Connection setting](#connection-settings) |
| `rbr_exec_mode` | [Not supported](#unsupported-variables) |
| `read_after_write_gtid` | [Vitess-aware](#vitess-aware-variables) |
| `read_after_write_timeout` | [Vitess-aware](#vitess-aware-variables) |
| `read_buffer_size` | [Connection setting](#connection-settings) |
| `read_rnd_buffer_size` | [Connection setting](#connection-settings) |
| `session_track_gtids` | [Vitess-aware](#vitess-aware-variables) |
| `session_track_schema` | [Ignored](#ignored-variables) |
| `session_track_state_change` | [Ignored](#ignored-variables) |
| `session_track_system_variables` | [Ignored](#ignored-variables) |
| `session_track_transaction_info` | [Ignored](#ignored-variables) |
| `session_uuid` | [Vitess-aware](#vitess-aware-variables) |
| `show_create_table_verbosity` | [Connection setting](#connection-settings) |
| `show_old_temporals` | [Connection setting](#connection-settings) |
| `skip_query_plan_cache` | [Vitess-aware](#vitess-aware-variables) |
| `socket` | [Read-only](#read-only-variables) |
| `sort_buffer_size` | [Connection setting](#connection-settings) |
| `sql_auto_is_null` | [Ignored](#ignored-variables) |
| `sql_big_selects` | [Connection setting](#connection-settings) |
| `sql_buffer_result` | [Ignored](#ignored-variables) |
| `sql_log_off` | [Not supported](#unsupported-variables) |
| `sql_mode` | [Connection setting](#connection-settings) |
| `sql_notes` | [Connection setting](#connection-settings) |
| `sql_quote_show_create` | [Connection setting](#connection-settings) |
| `sql_safe_updates` | [Connection setting](#connection-settings) |
| `sql_select_limit` | [Vitess-aware](#vitess-aware-variables) |
| `sql_warnings` | [Connection setting](#connection-settings) |
| `thread_pool_high_priority_connection` | [Not supported](#unsupported-variables) |
| `thread_pool_prio_kickup_timer` | [Not supported](#unsupported-variables) |
| `time_zone` | [Connection setting](#connection-settings) |
| `tmp_table_size` | [Connection setting](#connection-settings) |
| `transaction_alloc_block_size` | [Ignored](#ignored-variables) |
| `transaction_isolation` | [Connection setting](#connection-settings) |
| `transaction_mode` | [Vitess-aware](#vitess-aware-variables) |
| `transaction_prealloc_size` | [Connection setting](#connection-settings) |
| `transaction_read_only` | [Vitess-aware](#vitess-aware-variables) |
| `transaction_timeout` | [Vitess-aware](#vitess-aware-variables) |
| `transaction_write_set_extraction` | [Not supported](#unsupported-variables) |
| `tx_isolation` | [Connection setting](#connection-settings) |
| `tx_read_only` | [Vitess-aware](#vitess-aware-variables) |
| `unique_checks` | [Connection setting](#connection-settings) |
| `updatable_views_with_limit` | [Connection setting](#connection-settings) |
| `version` | [Read-only](#read-only-variables) |
| `version_comment` | [Read-only](#read-only-variables) |
| `version_tokens_session` | [Ignored](#ignored-variables) |
| `wait_timeout` | [Ignored](#ignored-variables) |
| `workload` | [Vitess-aware](#vitess-aware-variables) |
