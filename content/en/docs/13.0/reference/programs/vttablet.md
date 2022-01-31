---
title: vttablet
aliases: ['/docs/user-guides/vttablet-modes/','/docs/reference/vttablet-modes/']
---

A VTTablet server _controls_ a running MySQL server. VTTablet supports two primary types of deployments:

* Managed MySQL (most common)
* External MySQL

In addition to these deployment types, a partially managed VTTablet is also possible by setting `-disable_active_reparents`. 

## Example Usage

### Managed MySQL

In this mode, Vitess actively manages MySQL:

```bash
export TOPOLOGY_FLAGS="-topo_implementation etcd2 -topo_global_server_address localhost:2379 -topo_global_root /vitess/global"
export VTDATAROOT="/tmp"

vttablet \
$TOPOLOGY_FLAGS
-tablet-path $alias
-init_keyspace $keyspace
-init_shard $shard
-init_tablet_type $tablet_type
-port $port
-grpc_port $grpc_port
-service_map 'grpc-queryservice,grpc-tabletmanager,grpc-updatestream'
```

`$alias` needs to be of the form: `<cell>-id`, and the cell should match one of the local cells that was created in the topology. The id can be left padded with zeroes: `cell-100` and `cell-000000100` are synonymous.

### External MySQL

In this mode, an external MySQL can be used such as AWS RDS, AWS Aurora, Google CloudSQL; or just an existing (vanilla) MySQL installation.

See [Unmanaged Tablet](../../../user-guides/configuration-advanced/unmanaged-tablet) for the full guide.

Even if a MySQL is external, you can still make vttablet perform some management functions. They are as follows:

* `-disable_active_reparents`: If this flag is set, then any reparent or replica commands will not be allowed. These are InitShardMaster, PlannedReparent, PlannedReparent, EmergencyReparent, and ReparentTablet. In this mode, you should use the TabletExternallyReparented command to inform vitess of the current primary.
* `-replication_connect_retry`: This value is give to mysql when it connects a replica to the primary as the retry duration parameter.
* `-enable_replication_reporter`: If this flag is set, then vttablet will transmit replica lag related information to the vtgates, which will allow it to balance load better. Additionally, enabling this will also cause vttablet to restart replication if it was stopped. However, it will do this only if -disable_active_reparents was not turned on.
* `-enable_semi_sync`: This option will automatically enable semi-sync on new replicas as well as on any tablet that transitions into a replica type. This includes the demotion of a primary to a replica.
* `-heartbeat_enable` and `-heartbeat interval duration`: cause vttablet to write heartbeats to the sidecar database. This information is also used by the replication reporter to assess replica lag.

## Options

The following global options apply to `vttablet`:

| Name | Type | Definition |
| :------------------------------------ | :--------- | :----------------------------------------------------------------------------------------- |
| -allowed_tablet_types | value | Specifies the tablet types this vtgate is allowed to route queries to |
| -alsologtostderr |  | log to standard error as well as files |
| -app_idle_timeout | duration | Idle timeout for app connections (default 1m0s) |
| -app_pool_size | int | Size of the connection pool for app connections (default 40) |
| -azblob_backup_account_key_file | string | Path to a file containing the Azure Storage account key; if this flag is unset, the environment variable VT_AZBLOB_ACCOUNT_KEY will be used as the key itself (NOT a file path) |
| -azblob_backup_account_name | string | Azure Storage Account name for backups; if this flag is unset, the environment variable VT_AZBLOB_ACCOUNT_NAME will be used |
| -azblob_backup_container_name | string | Azure Blob Container Name |
| -azblob_backup_parallelism | int | Azure Blob operation parallelism (requires extra memory when increased) (default 1) |
| -azblob_backup_storage_root | string | Root prefix for all backup-related Azure Blobs; this should exclude both initial and trailing '/' (e.g. just 'a/b' not '/a/b/') |
| -backup_engine_implementation | string | Specifies which implementation to use for creating new backups (builtin or xtrabackup). Restores will always be done with whichever engine created a given backup. (default "builtin") |
| -backup_storage_block_size | int | if backup_storage_compress is true, backup_storage_block_size sets the byte size for each block while compressing (default is 250000). (default 250000) |
| -backup_storage_compress |  | if set, the backup files will be compressed (default is true). Set to false for instance if a backup_storage_hook is specified and it compresses the data. (default true) |
| -backup_storage_hook | string | if set, we send the contents of the backup files through this hook. |
| -backup_storage_implementation | string | which implementation to use for the backup storage feature |
| -backup_storage_number_blocks | int | if backup_storage_compress is true, backup_storage_number_blocks sets the number of blocks that can be processed, at once, before the writer blocks, during compression (default is 2). It should be equal to the number of CPUs available for compression (default 2) |
| -binlog_host | string | PITR restore parameter: hostname/IP of binlog server. |
| -binlog_password | string | PITR restore parameter: password of binlog server. |
| -binlog_player_grpc_ca | string | the server ca to use to validate servers when connecting |
| -binlog_player_grpc_cert | string | the cert to use to connect |
| -binlog_player_grpc_crl | string | the server crl to use to validate server certificates when connecting |
| -binlog_player_grpc_key | string | the key to use to connect |
| -binlog_player_grpc_server_name | string | the server name to use to validate server certificate |
| -binlog_player_protocol | string | the protocol to download binlogs from a vttablet (default "grpc") |
| -binlog_port | int | PITR restore parameter: port of binlog server. |
| -binlog_ssl_ca | string | PITR restore parameter: Filename containing TLS CA certificate to verify binlog server TLS certificate against. |
| -binlog_ssl_cert | string | PITR restore parameter: Filename containing mTLS client certificate to present to binlog server as authentication. |
| -binlog_ssl_key | string | PITR restore parameter: Filename containing mTLS client private key for use in binlog server authentication. |
| -binlog_ssl_server_name | string | PITR restore parameter: TLS server name (common name) to verify against for the binlog server we are connecting to (If not set: use the hostname or IP supplied in -binlog_host). |
| -binlog_use_v3_resharding_mode |  | True iff the binlog streamer should use V3-style sharding, which doesn't require a preset sharding key column. (default true) |
| -binlog_user | string | PITR restore parameter: username of binlog server. |
| -builtinbackup_mysqld_timeout | duration | how long to wait for mysqld to shutdown at the start of the backup (default 10m0s) |
| -builtinbackup_progress | duration | how often to send progress updates when backing up large files (default 5s) |
| -catch-sigpipe |  | catch and ignore SIGPIPE on stdout and stderr if specified |
| -ceph_backup_storage_config | string | Path to JSON config file for ceph backup storage (default "ceph_backup_config.json") |
| -client-found-rows-pool-size | int | DEPRECATED: queryserver-config-transaction-cap will be used instead. |
| -consul_auth_static_file | string | JSON File to read the topos/tokens from. |
| -cpu_profile | string | deprecated: use '-pprof=cpu' instead |
| -datadog-agent-host | string | host to send spans to. if empty, no tracing will be done |
| -datadog-agent-port | string | port to send spans to. if empty, no tracing will be done |
| -db-config-allprivs-charset | string | deprecated: use db_charset (default "utf8mb4") |
| -db-config-allprivs-flags | uint | deprecated: use db_flags |
| -db-config-allprivs-flavor | string | deprecated: use db_flavor |
| -db-config-allprivs-host | string | deprecated: use db_host |
| -db-config-allprivs-pass | string | db allprivs deprecated: use db_allprivs_password |
| -db-config-allprivs-port | int | deprecated: use db_port |
| -db-config-allprivs-server_name | string | deprecated: use db_server_name |
| -db-config-allprivs-ssl-ca | string | deprecated: use db_ssl_ca |
| -db-config-allprivs-ssl-ca-path | string | deprecated: use db_ssl_ca_path |
| -db-config-allprivs-ssl-cert | string | deprecated: use db_ssl_cert |
| -db-config-allprivs-ssl-key | string | deprecated: use db_ssl_key |
| -db-config-allprivs-uname | string | deprecated: use db_allprivs_user (default "vt_allprivs") |
| -db-config-allprivs-unixsocket | string | deprecated: use db_socket |
| -db-config-app-charset | string | deprecated: use db_charset (default "utf8mb4") |
| -db-config-app-flags | uint | deprecated: use db_flags |
| -db-config-app-flavor | string | deprecated: use db_flavor |
| -db-config-app-host | string | deprecated: use db_host |
| -db-config-app-pass | string | db app deprecated: use db_app_password |
| -db-config-app-port | int | deprecated: use db_port |
| -db-config-app-server_name | string | deprecated: use db_server_name |
| -db-config-app-ssl-ca | string | deprecated: use db_ssl_ca |
| -db-config-app-ssl-ca-path | string | deprecated: use db_ssl_ca_path |
| -db-config-app-ssl-cert | string | deprecated: use db_ssl_cert |
| -db-config-app-ssl-key | string | deprecated: use db_ssl_key |
| -db-config-app-uname | string | deprecated: use db_app_user (default "vt_app") |
| -db-config-app-unixsocket | string | deprecated: use db_socket |
| -db-config-appdebug-charset | string | deprecated: use db_charset (default "utf8mb4") |
| -db-config-appdebug-flags | uint | deprecated: use db_flags |
| -db-config-appdebug-flavor | string | deprecated: use db_flavor |
| -db-config-appdebug-host | string | deprecated: use db_host |
| -db-config-appdebug-pass | string | db appdebug deprecated: use db_appdebug_password |
| -db-config-appdebug-port | int | deprecated: use db_port |
| -db-config-appdebug-server_name | string | deprecated: use db_server_name |
| -db-config-appdebug-ssl-ca | string | deprecated: use db_ssl_ca |
| -db-config-appdebug-ssl-ca-path | string | deprecated: use db_ssl_ca_path |
| -db-config-appdebug-ssl-cert | string | deprecated: use db_ssl_cert |
| -db-config-appdebug-ssl-key | string | deprecated: use db_ssl_key |
| -db-config-appdebug-uname | string | deprecated: use db_appdebug_user (default "vt_appdebug") |
| -db-config-appdebug-unixsocket | string | deprecated: use db_socket |
| -db-config-dba-charset | string | deprecated: use db_charset (default "utf8mb4") |
| -db-config-dba-flags | uint | deprecated: use db_flags |
| -db-config-dba-flavor | string | deprecated: use db_flavor |
| -db-config-dba-host | string | deprecated: use db_host |
| -db-config-dba-pass | string | db dba deprecated: use db_dba_password |
| -db-config-dba-port | int | deprecated: use db_port |
| -db-config-dba-server_name | string | deprecated: use db_server_name |
| -db-config-dba-ssl-ca | string | deprecated: use db_ssl_ca |
| -db-config-dba-ssl-ca-path | string | deprecated: use db_ssl_ca_path |
| -db-config-dba-ssl-cert | string | deprecated: use db_ssl_cert |
| -db-config-dba-ssl-key | string | deprecated: use db_ssl_key |
| -db-config-dba-uname | string | deprecated: use db_dba_user (default "vt_dba") |
| -db-config-dba-unixsocket | string | deprecated: use db_socket |
| -db-config-erepl-charset | string | deprecated: use db_charset (default "utf8mb4") |
| -db-config-erepl-dbname | string | deprecated: dbname does not need to be explicitly configured |
| -db-config-erepl-flags | uint | deprecated: use db_flags |
| -db-config-erepl-flavor | string | deprecated: use db_flavor |
| -db-config-erepl-host | string | deprecated: use db_host |
| -db-config-erepl-pass | string | db erepl deprecated: use db_erepl_password |
| -db-config-erepl-port | int | deprecated: use db_port |
| -db-config-erepl-server_name | string | deprecated: use db_server_name |
| -db-config-erepl-ssl-ca | string | deprecated: use db_ssl_ca |
| -db-config-erepl-ssl-ca-path | string | deprecated: use db_ssl_ca_path |
| -db-config-erepl-ssl-cert | string | deprecated: use db_ssl_cert |
| -db-config-erepl-ssl-key | string | deprecated: use db_ssl_key |
| -db-config-erepl-uname | string | deprecated: use db_erepl_user (default "vt_erepl") |
| -db-config-erepl-unixsocket | string | deprecated: use db_socket |
| -db-config-filtered-charset | string | deprecated: use db_charset (default "utf8mb4") |
| -db-config-filtered-flags | uint | deprecated: use db_flags |
| -db-config-filtered-flavor | string | deprecated: use db_flavor |
| -db-config-filtered-host | string | deprecated: use db_host |
| -db-config-filtered-pass | string | db filtered deprecated: use db_filtered_password |
| -db-config-filtered-port | int | deprecated: use db_port |
| -db-config-filtered-server_name | string | deprecated: use db_server_name |
| -db-config-filtered-ssl-ca | string | deprecated: use db_ssl_ca |
| -db-config-filtered-ssl-ca-path | string | deprecated: use db_ssl_ca_path |
| -db-config-filtered-ssl-cert | string | deprecated: use db_ssl_cert |
| -db-config-filtered-ssl-key | string | deprecated: use db_ssl_key |
| -db-config-filtered-uname | string | deprecated: use db_filtered_user (default "vt_filtered") |
| -db-config-filtered-unixsocket | string | deprecated: use db_socket |
| -db-config-repl-charset | string | deprecated: use db_charset (default "utf8mb4") |
| -db-config-repl-flags | uint | deprecated: use db_flags |
| -db-config-repl-flavor | string | deprecated: use db_flavor |
| -db-config-repl-host | string | deprecated: use db_host |
| -db-config-repl-pass | string | db repl deprecated: use db_repl_password |
| -db-config-repl-port | int | deprecated: use db_port |
| -db-config-repl-server_name | string | deprecated: use db_server_name |
| -db-config-repl-ssl-ca | string | deprecated: use db_ssl_ca |
| -db-config-repl-ssl-ca-path | string | deprecated: use db_ssl_ca_path |
| -db-config-repl-ssl-cert | string | deprecated: use db_ssl_cert |
| -db-config-repl-ssl-key | string | deprecated: use db_ssl_key |
| -db-config-repl-uname | string | deprecated: use db_repl_user (default "vt_repl") |
| -db-config-repl-unixsocket | string | deprecated: use db_socket |
| -db-credentials-file | string | db credentials file; send SIGHUP to reload this file |
| -db-credentials-server | string | db credentials server type ('file' - file implementation; 'vault' - HashiCorp Vault implementation) (default "file") |
| -db-credentials-vault-addr | string | URL to Vault server |
| -db-credentials-vault-path | string | Vault path to credentials JSON blob, e.g.: secret/data/prod/dbcreds |
| -db-credentials-vault-role-mountpoint | string | Vault AppRole mountpoint; can also be passed using VAULT_MOUNTPOINT environment variable (default "approle") |
| -db-credentials-vault-role-secretidfile | string | Path to file containing Vault AppRole secret_id; can also be passed using VAULT_SECRETID environment variable |
| -db-credentials-vault-roleid | string | Vault AppRole id; can also be passed using VAULT_ROLEID environment variable |
| -db-credentials-vault-timeout | duration | Timeout for vault API operations (default 10s) |
| -db-credentials-vault-tls-ca | string | Path to CA PEM for validating Vault server certificate |
| -db-credentials-vault-tokenfile | string | Path to file containing Vault auth token; token can also be passed using VAULT_TOKEN environment variable |
| -db-credentials-vault-ttl | duration | How long to cache DB credentials from the Vault server (default 30m0s) |
| -db_allprivs_password | string | db allprivs password |
| -db_allprivs_use_ssl |  | Set this flag to false to make the allprivs connection to not use ssl (default true) |
| -db_allprivs_user | string | db allprivs user userKey (default "vt_allprivs") |
| -db_app_password | string | db app password |
| -db_app_use_ssl |  | Set this flag to false to make the app connection to not use ssl (default true) |
| -db_app_user | string | db app user userKey (default "vt_app") |
| -db_appdebug_password | string | db appdebug password |
| -db_appdebug_use_ssl |  | Set this flag to false to make the appdebug connection to not use ssl (default true) |
| -db_appdebug_user | string | db appdebug user userKey (default "vt_appdebug") |
| -db_charset | string | Character set used for this tablet. (default "utf8mb4") |
| -db_connect_timeout_ms | int | connection timeout to mysqld in milliseconds (0 for no timeout) |
| -db_dba_password | string | db dba password |
| -db_dba_use_ssl |  | Set this flag to false to make the dba connection to not use ssl (default true) |
| -db_dba_user | string | db dba user userKey (default "vt_dba") |
| -db_erepl_password | string | db erepl password |
| -db_erepl_use_ssl |  | Set this flag to false to make the erepl connection to not use ssl (default true) |
| -db_erepl_user | string | db erepl user userKey (default "vt_erepl") |
| -db_filtered_password | string | db filtered password |
| -db_filtered_use_ssl |  | Set this flag to false to make the filtered connection to not use ssl (default true) |
| -db_filtered_user | string | db filtered user userKey (default "vt_filtered") |
| -db_flags | uint | Flag values as defined by MySQL. |
| -db_flavor | string | Flavor overrid. Valid value is FilePos. |
| -db_host | string | The host name for the tcp connection. |
| -db_port | int | tcp port |
| -db_repl_password | string | db repl password |
| -db_repl_use_ssl |  | Set this flag to false to make the repl connection to not use ssl (default true) |
| -db_repl_user | string | db repl user userKey (default "vt_repl") |
| -db_server_name | string | server name of the DB we are connecting to. |
| -db_socket | string | The unix socket to connect on. If this is specified, host and port will not be used. |
| -db_ssl_ca | string | connection ssl ca |
| -db_ssl_ca_path | string | connection ssl ca path |
| -db_ssl_cert | string | connection ssl certificate |
| -db_ssl_key | string | connection ssl key |
| -db_ssl_mode | value | SSL mode to connect with. One of disabled, preferred, required, verify_ca & verify_identity. |
| -db_tls_min_version | string | Configures the minimal TLS version negotiated when SSL is enabled. Defaults to TLSv1.2. Options: TLSv1.0, TLSv1.1, TLSv1.2, TLSv1.3. |
| -dba_idle_timeout | duration | Idle timeout for dba connections (default 1m0s) |
| -dba_pool_size | int | Size of the connection pool for dba connections (default 20) |
| -degraded_threshold | duration | replication lag after which a replica is considered degraded (default 30s) |
| -disable_active_reparents |  | if set, do not allow active reparents. Use this to protect a cluster using external reparents. |
| -discovery_high_replication_lag_minimum_serving | duration | the replication lag that is considered too high when applying the min_number_serving_vttablets threshold (default 2h0m0s) |
| -discovery_low_replication_lag | duration | the replication lag that is considered low enough to be healthy (default 30s) |
| -emit_stats |  | If set, emit stats to push-based monitoring and stats backends |
| -enable-autocommit |  | This flag is deprecated. Autocommit is always allowed. (default true) |
| -enable-consolidator |  | Synonym to -enable_consolidator (default true) |
| -enable-consolidator-replicas |  | Synonym to -enable_consolidator_replicas |
| -enable-lag-throttler |  | Synonym to -enable_lag_throttler |
| -enable-query-plan-field-caching |  | Synonym to -enable_query_plan_field_caching (default true) |
| -enable-tx-throttler |  | Synonym to -enable_tx_throttler |
| -enable_consolidator |  | This option enables the query consolidator. (default true) |
| -enable_consolidator_replicas |  | This option enables the query consolidator only on replicas. |
| -enable_hot_row_protection |  | If true, incoming transactions for the same row (range) will be queued and cannot consume all txpool slots. |
| -enable_hot_row_protection_dry_run |  | If true, hot row protection is not enforced but logs if transactions would have been queued. |
| -enable_lag_throttler |  | If true, vttablet will run a throttler service, and will implicitly enable heartbeats |
| -enable_query_plan_field_caching |  | This option fetches & caches fields (columns) when storing query plans (default true) |
| -enable_replication_reporter |  | Use polling to track replication lag. |
| -enable_semi_sync |  | Enable semi-sync when configuring replication, on primary and replica tablets only (rdonly tablets will not ack). |
| -enable_transaction_limit |  | If true, limit on number of transactions open at the same time will be enforced for all users. User trying to open a new transaction after exhausting their limit will receive an error immediately, regardless of whether there are available slots or not. |

### Key Options

* -restore_from_backup: The default value for this flag is false. If set to true, and the my.cnf file was successfully loaded, then vttablet can perform automatic restores as follows:

	* If started against a mysql instance that has no data files, it will search the list of backups for the latest one, and initiate a restore. After this, it will point the mysql to the current primary and wait for replication to catch up. Once replication is caught up to the specified tolerance limit, it will advertise itself as serving. This will cause the vtgates to add it to the list of healthy tablets to serve queries from.
	* If this flag is true, but my.cnf was not loaded, then vttablet will fatally exit with an error message.
	* You can additionally control the level of concurrency for a restore with the `-restore_concurrency` flag. This is typically useful in cloud environments to prevent the restore process from becoming a 'noisy' neighbor by consuming all available disk IOPS.

