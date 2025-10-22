---
title: VTTablet Connection Pools and Sizing
weight: 20
---

VTTablet uses a variety of connection pools to connect to MySQLd. 
Most of these can be controlled by vttablet options.  
Note that almost all of these pools are **not** fixed size connection pools, and will grow on demand to the maximum configured sizes.  
In older Vitess versions, v6.0 or before, some pools would eventually shrink again, but in recent Vitess versions a new pool connection is created when an old one reaches its idle timeout.  
As a result, pools will now effectively never shrink.

One thing to note is that each of these pools do not use unique MySQL usernames, so it can be hard from a MySQL process list to distinguish between different pool connections.  
Consult the `_active` pool metrics (e.g. `vttablet_dba_conn_pool_active`) as the authoritative resource on how many MySQL protocol connections are in use for each pool. 
In a similar fashion the `_exhausted` pool metrics (e.g. `vttablet_dba_conn_pool_exhausted`) can be used to see if a given pool has run out of connections (and how many times), since VTTablet startup.

Note that a connection pool running out of connections is not necessarily a bad thing, since it limits the concurrency in the database. 
As a result, connection pools should be sized mindful of the capacity of the underlying MySQL instance(s).

## Pools:

### transaction-pool and found-rows-pool

  * Max size (for each) controlled by:  `--queryserver-config-transaction-cap` (default 20)
  * metric:  `vttablet_transaction_pool_capacity`
  * metric:  `vttablet_found_rows_pool_capacity`
  * Used by transaction engine to manage transactions that require a dedicated connection. 
  The main pool for this use the **transaction_pool**. 
  The **found_rows_pool** is dedicated for connections where the client is using the `CLIENT_FOUND_ROWS` option. 
  For example, the `affected_rows` field return by the [MySQL protocol](https://dev.mysql.com/doc/internals/en/packet-OK_Packet.html) becomes the number of rows matched by the `WHERE` clause instead.

### conn-pool

  * Max size controlled controlled by:  `--queryserver-config-pool-size` (default 16)
  * metric:  `vttablet_conn_pool_capacity`
  * Potentially uses `--db-app-user`, `--db-dba-user` and `--db-appdebug-user` i.e. defaults 'vt_app', 'vt_dba' and 'vt_appdebug'
  * Used as the vttablet query engine "normal" (non-streaming) connections pool.

### stream-conn-pool

  * Max size controlled by:  `--queryserver-config-stream-pool-size` (default 200)
  * metric:  `vttablet_stream_conn_pool_capacity`
  * Potentially uses `--db-app-user`, `--db-dba-user` and `--db-appdebug-user`
    i.e. defaults 'vt_app', 'vt_dba' and 'vt_appdebug'
  * Used as vttablet query engine streaming connections pool. All streaming queries that are not transactional should use this pool.

### dba-conn-pool

  * Max size controlled by:  `--dba-pool-size` (default 20)
  * metric:  `vttablet_dba_conn_pool_capacity`
  * vttablet user flag:  `--db-dba-user` (default 'vt_dba')
  * Used by vttablet `ExecuteFetchAsDBA` RPC. This is used when using `vtctldclient ExecuteFetchAsDBA`
  Also used implicitly for various internal Vitess maintenance tasks (e.g. schema reloads, etc.)

### app-conn-pool

  * Max size controlled by:  `--app-pool-size` (default 40)
  * metric:  `vttablet_app_conn_pool_capacity`
  * vttablet user flag:  `--db-app-user` default 'vt_app')
  * Used by vttablet `ExecuteFetchAsApp` RPC. This is used when using `vtctldclient ExecuteFetchAsApp`

### tx-read-pool

 * Hardcoded (size 3)
 * metric:  `vttablet_tx_read_pool_capacity`
 * vttablet user flag:  `--db-dba-user` (default 'vt_dba')
 * Used in the (non-default) TWOPC `transaction_mode` for metadata state management.  
  This pool will always be empty unless TWOPC is used.

### Pools associated with online DDL
  
#### online-ddl-executor-pool

 * Hardcoded (size 3)
 * metric:  `vttablet_online_ddl_executor_pool_capacity`
 * Potentially uses `--db-app-user`, `--db-dba-user` and `--db-appdebug-user` i.e. defaults 'vt_app', 'vt_dba' and 'vt_appdebug'
 * Used in Online DDL to during the actual process of running migrations.

#### table-gc-pool

 * Hardcoded (default 2)
 * metric:  `vttablet_table_gc_pool_capacity`
 * Potentially uses `--db-app-user`, `--db-dba-user` and `--db-appdebug-user` i.e. defaults 'vt_app', 'vt_dba' and 'vt_appdebug'
 * Used in Online DDL to purge/evac/drop origin tables after Online DDL operations from them have been completed.

## Other DB connections used without pools:

### vttablet user flag:

#### `--db-allprivs-user`

 * (default 'vt_allprivs')

#### `--db-erepl-user`
                               
 * (default 'vt_erepl')
 * Used only if you setup replication explicitly from an external MySQL instance **without** front-ending that instance with a tablet. 
 This user is then used to login to the external MySQL.

#### `--db-repl-user`

 * (default 'vt_repl')
 * Used to setup MySQL replication between shard primary and replica instance types.

#### `--db-filtered-user`
                             
 * (default 'vt_filtered')
 * Used by VReplication on the source (vstreamer) and target (vplayer) side when copying data.

## Other relevant pool-related variables

### vttablet user limit
Flag: `--transaction-limit-per-user`

 * (default 0.4)
 * This flag determines the fraction of connections in the **transaction_pool** and **found_rows_pool** that can be used by a single user.
 The username is passed to vttablet from vtgate.
 If you are using a limited set of users, you may want to increase this limit.
 Or disable this limit feature by setting `--transaction-limit-by-username` to `false` as the default is `true`.
 This option only comes into play if the TX limiter is enabled by `--enable-transaction-limit`, which it is not by default.

### vtgate system settings
Flag: `--enable-system-settings`

This vtgate flag allows clients to modify a [subset of system settings](https://github.com/vitessio/vitess/blob/main/go/vt/sysvars/sysvars.go#L174-L217) on the MySQL.

## Calculating maximum db connections used by vttablet

You can use the following formula to approximate the maximum MySQL connections per vttablet instance:
```
    --queryserver-config-transaction-cap x 2  (transaction_pool and found_rows_pool)
  + --queryserver-config-pool-size            (conn_pool)
  + --queryserver-config-stream-pool-size     (stream_conn_pool)
  + --dba-pool-size                           (dba_conn_pool)
  + --app-pool-size                           (app_conn_pool)
  + 3                                        (tx_read_pool, hardcoded)
  + 7                                        (online DDL)
  + variable                                 (on demand:  for vreplication, MySQL replication, etc;  should < 10)
  + variable                                 (reserved connections used by `enable_system_settings`)
```

{{< info >}}
Note that most servers will not use this many connections, since most workloads do not exercise all the pools.
{{< /info >}}
   
