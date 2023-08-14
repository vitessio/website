---
title: vtctl
description: vtctl Command Index
aliases: ['/docs/reference/vitess-api/','/docs/reference/vtctl/']
---

`vtctl` is a command-line tool used to administer a Vitess cluster. It is available as both a standalone tool (`vtctl`) and client-server (`vtctlclient` in combination with `vtctld`). Using client-server is recommended, as it provides an additional layer of security when using the client remotely.

Note that wherever `vtctl` commands produced master or MASTER for tablet type, they now produce primary or PRIMARY. Scripts and tools that depend on parsing command output will need to be updated.

## Commands

### Tablets

| Name | Example Usage |
| :-------- | :--------------- |
| (DEPRECATED) [InitTablet](../vtctl/tablets#inittablet) DEPRECATED | `InitTablet  -- [--allow_update] [--allow_different_shard] [--allow_master_override] [--parent] [--db_name_override=<db name>] [--hostname=<hostname>] [--mysql_port=<port>] [--port=<port>] [--grpc_port=<port>] [--tags=tag1:value1,tag2:value2] -keyspace=<keyspace> -shard=<shard> <tablet alias> <tablet type>` |
| [GetTablet](../vtctl/tablets#gettablet) | `GetTablet <tablet alias>` |
| (DEPRECATED) [UpdateTabletAddrs](../vtctl/tablets#updatetabletaddrs) DEPRECATED | `UpdateTabletAddrs  -- [--hostname <hostname>] [--ip-addr <ip addr>] [--mysql-port <mysql port>] [--vt-port <vt port>] [--grpc-port <grpc port>] <tablet alias>` |
| [DeleteTablet](../vtctl/tablets#deletetablet) | `DeleteTablet  -- [--allow_primary=false] <tablet alias> ...` |
| [SetReadOnly](../vtctl/tablets#setreadonly) | `SetReadOnly <tablet alias>` |
| [SetReadWrite](../vtctl/tablets#setreadwrite) | `SetReadWrite <tablet alias>` |
| [StartReplication](../vtctl/tablets#startreplication) | `StartReplication <tablet alias>` |
| [StopReplication](../vtctl/tablets#stopreplication) | `StopReplication <tablet alias>` |
| [ChangeTabletType](../vtctl/tablets#changetablettype) | `ChangeTabletType  -- [--dry-run] <tablet alias> <tablet type>` |
| [Ping](../vtctl/tablets#ping) | `Ping <tablet alias>` |
| [RefreshState](../vtctl/tablets#refreshstate) | `RefreshState <tablet alias>` |
| [RefreshStateByShard](../vtctl/tablets#refreshstatebyshard) | `RefreshStateByShard  -- [--cells=c1,c2,...] <keyspace/shard>` |
| [RunHealthCheck](../vtctl/tablets#runhealthcheck) | `RunHealthCheck <tablet alias>` |
| [Sleep](../vtctl/tablets#sleep) | `Sleep <tablet alias> <duration>` |
| [ExecuteHook](../vtctl/tablets#executehook) | `ExecuteHook <tablet alias> <hook name> [<param1=value1> <param2=value2> ...]` |
| [ExecuteFetchAsApp](../vtctl/tablets#executefetchasapp) | `ExecuteFetchAsApp  -- [--max_rows=10000] [--json] [--use_pool] <tablet alias> <sql command>` |
| [ExecuteFetchAsDba](../vtctl/tablets#executefetchasdba) | `ExecuteFetchAsDba  -- [--max_rows=10000] [--disable_binlogs] [--json] <tablet alias> <sql command>` |
| [VReplicationExec](../vtctl/tablets#vreplicationexec) | `VReplicationExec  -- [--json] <tablet alias> <sql command>` |
| [Backup](../vtctl/tablets#backup) | `Backup  -- [--concurrency=4] [--allow_primary=false] <tablet alias>` |
| [RestoreFromBackup](../vtctl/tablets#restorefrombackup) | `RestoreFromBackup <tablet alias>` |
| [ReparentTablet](../vtctl/tablets#reparenttablet) | `ReparentTablet <tablet alias>` |

### Shards

| Name | Example Usage |
| :-------- | :--------------- |
| [CreateShard](../vtctl/shards#createshard) | `CreateShard  -- [--force] [--parent] <keyspace/shard>` |
| [GetShard](../vtctl/shards#getshard) | `GetShard <keyspace/shard>` |
| [ValidateShard](../vtctl/shards#validateshard) | `ValidateShard  -- [--ping-tablets] <keyspace/shard>` |
| [ShardReplicationPositions](../vtctl/shards#shardreplicationpositions) | `ShardReplicationPositions <keyspace/shard>` |
| [ListShardTablets](../vtctl/shards#listshardtablets) | `ListShardTablets <keyspace/shard>` |
| [SetShardIsPrimaryServing](../vtctl/shards#setshardisprimaryserving) | `SetShardIsPrimaryServing <keyspace/shard> <is_serving>` |
| [SetShardTabletControl](../vtctl/shards#setshardtabletcontrol) | `SetShardTabletControl  -- [--cells=c1,c2,...] [--denied_tables=t1,t2,...] [--remove] [--disable_query_service] <keyspace/shard> <tablet type>` |
| [UpdateSrvKeyspacePartition](../vtctl/shards#updatesrvkeyspacepartition)| `UpdateSrvKeyspacePartition -- [--cells=c1,c2,...] [--remove] <keyspace/shard> <tablet type>` |
| [SourceShardDelete](../vtctl/shards#sourcesharddelete) | `SourceShardDelete <keyspace/shard> <uid>` |
| [SourceShardAdd](../vtctl/shards#sourceshardadd) | `SourceShardAdd  -- [--key_range=<keyrange>] [--tables=<table1,table2,...>] <keyspace/shard> <uid> <source keyspace/shard>` |
| [ShardReplicationFix](../vtctl/shards#shardreplicationfix) | `ShardReplicationFix <cell> <keyspace/shard>` |
| [WaitForFilteredReplication](../vtctl/shards#waitforfilteredreplication) | `WaitForFilteredReplication  -- [--max_delay <max_delay, default 30s>] <keyspace/shard>` |
| [RemoveShardCell](../vtctl/shards#removeshardcell) | `RemoveShardCell  -- [--force] [--recursive] <keyspace/shard> <cell>` |
| [DeleteShard](../vtctl/shards#deleteshard) | `DeleteShard  -- [--recursive] [--even_if_serving] <keyspace/shard> ...` |
| [ListBackups](../vtctl/shards#listbackups) | `ListBackups <keyspace/shard>` |
| [BackupShard](../vtctl/shards#backupshard) | `BackupShard  -- [--allow_primary=false] <keyspace/shard>` |
| [RemoveBackup](../vtctl/shards#removebackup) | `RemoveBackup <keyspace/shard> <backup name>` |
| (DEPRECATED) [InitShardPrimary](../vtctl/shards#initshardprimary) | `InitShardPrimary  -- [--force] [--wait_replicas_timeout=<duration>] <keyspace/shard> <tablet alias>` |
| [PlannedReparentShard](../vtctl/shards#plannedreparentshard) | `PlannedReparentShard  -- --keyspace_shard=<keyspace/shard> [--new_primary=<tablet alias>] [--avoid_tablet=<tablet alias>] [--wait_replicas_timeout=<duration>]` |
| [EmergencyReparentShard](../vtctl/shards#emergencyreparentshard) | `EmergencyReparentShard  -- --keyspace_shard=<keyspace/shard> [--new_primary=<tablet alias>] [--wait_replicas_timeout=<duration>] [--ignore_replicas=<tablet alias list>] [--prevent_cross_cell_promotion=<true/false>]`
| [TabletExternallyReparented](../vtctl/shards#tabletexternallyreparented) | `TabletExternallyReparented <tablet alias>` |
| [GenerateShardRanges](../vtctl/shards#generateshardranges) | `GenerateShardRanges <num shards>` |

### Keyspaces

| Name | Example Usage |
| :-------- | :--------------- |
| [CreateKeyspace](../vtctl/keyspaces#createkeyspace) | `CreateKeyspace  -- [--sharding_column_name=name] [--sharding_column_type=type] [--served_from=tablettype1:ks1,tablettype2:ks2,...] [--force] [--keyspace_type=type] [--base_keyspace=base_keyspace] [--snapshot_time=time] [--durability-policy=policy_name] <keyspace name>` |
| [DeleteKeyspace](../vtctl/keyspaces#deletekeyspace) | `DeleteKeyspace  -- [--recursive] <keyspace>` |
| [RemoveKeyspaceCell](../vtctl/keyspaces#removekeyspacecell) | `RemoveKeyspaceCell  -- [--force] [--recursive] <keyspace> <cell>` |
| [GetKeyspace](../vtctl/keyspaces#getkeyspace) | `GetKeyspace  <keyspace>` |
| [GetKeyspaces](../vtctl/keyspaces#getkeyspaces) | `GetKeyspaces  ` |
| [RebuildKeyspaceGraph](../vtctl/keyspaces#rebuildkeyspacegraph) | `RebuildKeyspaceGraph  -- [--cells=c1,c2,...] <keyspace> ...` |
| [ValidateKeyspace](../vtctl/keyspaces#validatekeyspace) | `ValidateKeyspace  -- [--ping-tablets] <keyspace name>` |
| [CreateLookupVindex](../vtctl/keyspaces#createlookupvindex) | `CreateLookupVindex  -- [--cell=<cell>] [--tablet_types=<source_tablet_types>] <keyspace> <json_spec>` |
| [ExternalizeVindex](../vtctl/keyspaces#externalizevindex) | `ExternalizeVindex  <keyspace>.<vindex>` |
| [Materialize](../vtctl/keyspaces#materialize) | `Materialize  <json_spec>, example : '{"workflow": "aaa", "source_keyspace": "source", "target_keyspace": "target", "table_settings": [{"target_table": "customer", "source_expression": "select * from customer", "create_ddl": "copy"}]}'` |
| [VDiff](../vtctl/keyspaces#vdiff) | `VDiff -- [--source_cell=<cell>] [--target_cell=<cell>] [--tablet_types=in_order:RDONLY,REPLICA,PRIMARY] [--limit=<max rows to diff>] [--tables=<table list>] [--format=json] [--auto-retry] [--verbose] [--max_extra_rows_to_compare=1000] [--filtered_replication_wait_time=30s] [--debug_query] [--only_pks] [--wait] [--wait-update-interval=1m] <keyspace.workflow> [<action>] [<UUID>]` |
| [FindAllShardsInKeyspace](../vtctl/keyspaces#findallshardsinkeyspace) | `FindAllShardsInKeyspace  <keyspace>` |

### Generic

| Name | Example Usage |
| :-------- | :--------------- |
| [Validate](../vtctl/generic#validate) | `Validate  -- [--ping-tablets]` |
| [ListAllTablets](../vtctl/generic#listalltablets) | `ListAllTablets  -- [--keyspace=''] [--tablet_type=<PRIMARY,REPLICA,RDONLY,SPARE>] [<cell_name1>,<cell_name2>,...]` |
| [ListTablets](../vtctl/generic#listtablets) | `ListTablets <tablet alias> ...` |
| [Help](../vtctl/generic#help) | `Help [command name]` |

### Schema, Version, Permissions

| Name | Example Usage |
| :-------- | :--------------- |
| [GetSchema](../vtctl/schema-version-permissions#getschema) | `GetSchema  -- [--tables=<table1>,<table2>,...] [--exclude_tables=<table1>,<table2>,...] [--include-views] <tablet alias>` |
| [ReloadSchema](../vtctl/schema-version-permissions#reloadschema) | `ReloadSchema  <tablet alias>` |
| [ReloadSchemaShard](../vtctl/schema-version-permissions#reloadschemashard) | `ReloadSchemaShard  -- [--concurrency=10] [--include_primary=false] <keyspace/shard>` |
| [ReloadSchemaKeyspace](../vtctl/schema-version-permissions#reloadschemakeyspace) | `ReloadSchemaKeyspace  -- [--concurrency=10] [--include_primary=false] <keyspace>` |
| [ValidateSchemaShard](../vtctl/schema-version-permissions#validateschemashard) | `ValidateSchemaShard  -- [--exclude_tables=''] [--include-views] <keyspace/shard>` |
| [ValidateSchemaKeyspace](../vtctl/schema-version-permissions#validateschemakeyspace) | `ValidateSchemaKeyspace  -- [--exclude_tables=''] [--include-views] <keyspace name>` |
| [ApplySchema](../vtctl/schema-version-permissions#applyschema) | `ApplySchema  -- [--allow_long_unavailability] [--wait_replicas_timeout=10s] {--sql=<sql> \|\| --sql-file=<filename>} <keyspace>` |
| [CopySchemaShard](../vtctl/schema-version-permissions#copyschemashard) | `CopySchemaShard  -- [--tables=<table1>,<table2>,...] [--exclude_tables=<table1>,<table2>,...] [--include-views] [--skip-verify] [--wait_replicas_timeout=10s] {<source keyspace/shard> \|\| <source tablet alias>} <destination keyspace/shard>` |
| [ValidateVersionShard](../vtctl/schema-version-permissions#validateversionshard) | `ValidateVersionShard  <keyspace/shard>` |
| [ValidateVersionKeyspace](../vtctl/schema-version-permissions#validateversionkeyspace) | `ValidateVersionKeyspace  <keyspace name>` |
| [GetPermissions](../vtctl/schema-version-permissions#getpermissions) | `GetPermissions  <tablet alias>` |
| [ValidatePermissionsShard](../vtctl/schema-version-permissions#validatepermissionsshard) | `ValidatePermissionsShard  <keyspace/shard>` |
| [ValidatePermissionsKeyspace](../vtctl/schema-version-permissions#validatepermissionskeyspace) | `ValidatePermissionsKeyspace  <keyspace name>` |
| [GetVSchema](../vtctl/schema-version-permissions#getvschema) | `GetVSchema  <keyspace>` |
| [ApplyVSchema](../vtctl/schema-version-permissions#applyvschema) | `ApplyVSchema  -- {--vschema=<vschema> \|\| --vschema_file=<vschema file> \|\| --sql=<sql> \|\| --sql_file=<sql file>} [--cells=c1,c2,...] [--skip_rebuild] [--dry-run] <keyspace>` |
| [GetRoutingRules](../vtctl/schema-version-permissions#getroutingrules) | `GetRoutingRules  ` |
| [ApplyRoutingRules](../vtctl/schema-version-permissions#applyroutingrules) | `ApplyRoutingRules  -- {--rules=<rules> \|\| --rules_file=<rules_file>} [--cells=c1,c2,...] [--skip_rebuild] [--dry-run]` |
| [RebuildVSchemaGraph](../vtctl/schema-version-permissions#rebuildvschemagraph) | `RebuildVSchemaGraph  -- [--cells=c1,c2,...]` |

### Serving Graph

| Name | Example Usage |
| :-------- | :--------------- |
| [GetSrvKeyspaceNames](../vtctl/serving-graph#getsrvkeyspacenames) | `GetSrvKeyspaceNames  <cell>` |
| [GetSrvKeyspace](../vtctl/serving-graph#getsrvkeyspace) | `GetSrvKeyspace  <cell> <keyspace>` |
| [GetSrvVSchema](../vtctl/serving-graph#getsrvvsvchema) | `GetSrvVSchema  <cell>` |
| [DeleteSrvVSchema](../vtctl/serving-graph#deletesrvvschema) | `DeleteSrvVSchema  <cell>` |

### Replication Graph

| Name | Example Usage |
| :-------- | :--------------- |
| [GetShardReplication](../vtctl/replication-graph#getshardreplication) | `GetShardReplication  <cell> <keyspace/shard>` |

### Cells

| Name | Example Usage |
| :-------- | :--------------- |
| [AddCellInfo](../vtctl/cells#addcellinfo) | `AddCellInfo  -- [--server_address <addr>] [--root <root>] <cell>` |
| [UpdateCellInfo](../vtctl/cells#updatecellinfo) | `UpdateCellInfo  -- [--server_address <addr>] [--root <root>] <cell>` |
| [DeleteCellInfo](../vtctl/cells#deletecellinfo) | `DeleteCellInfo  -- [--force] <cell>` |
| [GetCellInfoNames](../vtctl/cells#getcellinfonames) | `GetCellInfoNames  ` |
| [GetCellInfo](../vtctl/cells#getcellinfo) | `GetCellInfo  <cell>` |

### CellsAliases

| Name | Example Usage |
| :-------- | :--------------- |
| [AddCellsAlias](../vtctl/cell-aliases#addcellsalias) | `AddCellsAlias  -- [--cells <cell,cell2...>] <alias>` |
| [UpdateCellsAlias](../vtctl/cell-aliases#updatecellsalias) | `UpdateCellsAlias  -- [--cells <cell,cell2,...>] <alias>` |
| [DeleteCellsAlias](../vtctl/cell-aliases#deletecellsalias) | `DeleteCellsAlias  <alias>` |
| [GetCellsAliases](../vtctl/cell-aliases#getcellsaliases) | `GetCellsAliases  ` |

### Topo

| Name | Example Usage |
| :-------- | :--------------- |
| [TopoCat](../vtctl/topo#topocat) | `TopoCat  -- [--cell <cell>] [--decode_proto] [--decode_proto_json] [--long] <path> [<path>...]` |
| [TopoCp](../vtctl/topo#topocp) | `TopoCp  -- [--cell <cell>] [--to_topo] <src> <dst>` |

### Throttler

| Name | Example Usage |
| :-------- | :--------------- |
| [UpdateThrottlerConfig](../vtctl/throttler#updatethrottlerconfig) | `UpdateThrottlerConfig  -- [--enable\|--disable] [--threshold=<float64>] [--custom-query=<query>] [--check-as-check-self\|--check-as-check-shard] <keyspace>`

## Options

The following global options apply to `vtctl`:


| Name | Type | Definition |
| :------------------------------------ | :--------- | :----------------------------------------------------------------------------------------- |
| --alsologtostderr | | log to standard error as well as files |
| --azblob_backup_account_key_file | string | Path to a file containing the Azure Storage account key; if this flag is unset, the environment variable VT_AZBLOB_ACCOUNT_KEY will be used as the key itself (NOT a file path) |
| --azblob_backup_account_name | string | Azure Storage Account name for backups; if this flag is unset, the environment variable VT_AZBLOB_ACCOUNT_NAME will be used |
| --azblob_backup_buffer_size | int | The memory buffer size to use in bytes, per file or stripe, when streaming to Azure Blob Service. (default 104857600) |
| --azblob_backup_container_name | string | Azure Blob Container Name |
| --azblob_backup_parallelism | int | Azure Blob operation parallelism (requires extra memory when increased) (default 1) |
| --azblob_backup_storage_root | string | Root prefix for all backup-related Azure Blobs; this should exclude both initial and trailing '/' (e.g. just 'a/b' not '/a/b/') |
| --backup_engine_implementation | string | Specifies which implementation to use for creating new backups (builtin or xtrabackup). Restores will always be done with whichever engine created a given backup. (default "builtin") |
| --backup_storage_block_size | int | if backup_storage_compress is true, backup_storage_block_size sets the byte size for each block while compressing (default is 250000). (default 250000) |
| --backup_storage_compress | | if set, the backup files will be compressed (default is true). |
| --backup_storage_implementation | string | which implementation to use for the backup storage feature |
| --backup_storage_number_blocks | int | if backup_storage_compress is true, backup_storage_number_blocks sets the number of blocks that can be processed, at once, before the writer blocks, during compression (default is 2). It should be equal to the number of CPUs available for compression (default 2) |
| --ceph_backup_storage_config | string | Path to JSON config file for ceph backup storage (default "ceph_backup_config.json") |
| --consul_auth_static_file | string | JSON File to read the topos/tokens from. |
| --datadog-agent-host | string | host to send spans to. if empty, no tracing will be done |
| --datadog-agent-port | string | port to send spans to. if empty, no tracing will be done |
| --detach | | detached mode - run vtcl detached from the terminal |
|-file_backup_storage_root | string | root directory for the file backup storage -- this path must be on shared storage to provide a global view of backups to all vitess components |
| --gcs_backup_storage_bucket | string | Google Cloud Storage bucket to use for backups |
| --gcs_backup_storage_root | string | root prefix for all backup-related object names |
| --grpc_auth_static_client_creds | string | when using grpc_static_auth in the server, this file provides the credentials to use to authenticate with server |
| --grpc_compression | string | how to compress gRPC, default: nothing, supported: snappy |
| --grpc_enable_tracing | | Enable GRPC tracing |
| --grpc_initial_conn_window_size | int | grpc initial connection window size |
| --grpc_initial_window_size | int | grpc initial window size |
| --grpc_keepalive_time | duration | After a duration of this time if the client doesn't see any activity it pings the server to see if the transport is still alive. (default 10s) |
| --grpc_keepalive_timeout | duration | After having pinged for keepalive check, the client waits for a duration of Timeout and if no activity is seen even after that the connection is closed. (default 10s) |
| --grpc_max_message_size | int | Maximum allowed RPC message size. Larger messages will be rejected by gRPC with the error 'exceeding the max size'. (default 16777216) |
| --grpc_prometheus | | Enable gRPC monitoring with Prometheus |
| --jaeger-agent-host | string | host and port to send spans to. if empty, no tracing will be done |
| --keep_logs | duration | keep logs for this long (using ctime) (zero to keep forever) |
| --keep_logs_by_mtime | duration | keep logs for this long (using mtime) (zero to keep forever) |
| --log_backtrace_at | value | when logging hits line file:N, emit a stack trace |
| --log_dir | string | If non-empty, write log files in this directory |
| --log_err_stacks | | log stack traces for errors |
| --log_rotate_max_size | uint | size in bytes at which logs are rotated (glog.MaxSize) (default 1887436800) |
| --logtostderr | | log to standard error instead of files |
| --mysql_server_version | string | MySQL server version to advertise. |
| --pprof | strings | enable profiling |
| --purge_logs_interval | duration | how often try to remove old logs (default 1h0m0s) |
| --remote_operation_timeout | duration | time to wait for a remote operation (default 30s) |
| --s3_backup_aws_endpoint | string | endpoint of the S3 backend (region must be provided) |
| --s3_backup_aws_region | string | AWS region to use (default "us-east-1") |
| --s3_backup_aws_retries | int | AWS request retries (default -1) |
| --s3_backup_force_path_style | | force the s3 path style |
| --s3_backup_log_level | string | determine the S3 loglevel to use from LogOff, LogDebug, LogDebugWithSigning, LogDebugWithHTTPBody, LogDebugWithRequestRetries, LogDebugWithRequestErrors (default "LogOff") |
| --s3_backup_server_side_encryption | string | server-side encryption algorithm (e.g., AES256, aws:kms) |
| --s3_backup_storage_bucket | string | S3 bucket to use for backups |
| --s3_backup_storage_root | string | root prefix for all backup-related object names |
| --s3_backup_tls_skip_verify_cert | | skip the 'certificate is valid' check for SSL connections |
| --security_policy | string | the name of a registered security policy to use for controlling access to URLs - empty means allow all for anyone (built-in policies: deny-all, read-only) |
| --service_map | value | comma separated list of services to enable (or disable if prefixed with '-') Example: grpc-queryservice |
| --sql-max-length-errors | int | truncate queries in error logs to the given length (default unlimited) |
| --sql-max-length-ui | int | truncate queries in debug UIs to the given length (default 512) (default 512) |
| --stderrthreshold | value | logs at or above this threshold go to stderr (default 1) |
| --tablet_grpc_ca | string | the server ca to use to validate servers when connecting |
| --tablet_grpc_cert | string | the cert to use to connect |
| --tablet_grpc_crl | string | the server crl to use to validate server certificates when connecting |
| --tablet_grpc_key | string | the key to use to connect |
| --tablet_grpc_server_name | string | the server name to use to validate server certificate |
| --tablet_manager_grpc_ca | string | the server ca to use to validate servers when connecting |
| --tablet_manager_grpc_cert | string | the cert to use to connect |
| --tablet_manager_grpc_concurrency | int | concurrency to use to talk to a vttablet server for performance-sensitive RPCs (like ExecuteFetchAs{Dba,AllPrivs,App}) (default 8) |
| --tablet_manager_grpc_connpool_size | int | number of tablets to keep tmclient connections open to (default 100) |
| --tablet_manager_grpc_crl | string | the server crl to use to validate server certificates when connecting |
| --tablet_manager_grpc_key | string | the key to use to connect |
| --tablet_manager_grpc_server_name | string | the server name to use to validate server certificate |
| --tablet_manager_protocol | string | the protocol to use to talk to vttablet (default "grpc") |
| --tablet_protocol | string | how to talk to the vttablets (default "grpc") |
| --topo_consul_lock_session_ttl | string | TTL for consul session. |
| --topo_consul_watch_poll_duration | duration | time of the long poll for watch queries. (default 30s) |
| --topo_etcd_lease_ttl | int | Lease TTL for locks and leader election. The client will use KeepAlive to keep the lease going. (default 30) |
| --topo_etcd_tls_ca | string | path to the ca to use to validate the server cert when connecting to the etcd topo server |
| --topo_etcd_tls_cert | string | path to the client cert to use to connect to the etcd topo server, requires topo_etcd_tls_key, enables TLS |
| --topo_etcd_tls_key | string | path to the client key to use to connect to the etcd topo server, enables TLS |
| --topo_global_root | string | the path of the global topology data in the global topology server |
| --topo_global_server_address | string | the address of the global topology server |
| --topo_implementation | string | the topology implementation to use |
| --topo_k8s_context | string | The kubeconfig context to use, overrides the 'current-context' from the config |
| --topo_k8s_kubeconfig | string | Path to a valid kubeconfig file. |
| --topo_k8s_namespace | string | The kubernetes namespace to use for all objects. Default comes from the context or in-cluster config |
| --topo_zk_auth_file | string | auth to use when connecting to the zk topo server, file contents should be <scheme>:<auth>, e.g., digest:user:pass |
| --topo_zk_base_timeout | duration | zk base timeout (see zk.Connect) (default 30s) |
| --topo_zk_max_concurrency | int | maximum number of pending requests to send to a Zookeeper server. (default 64) |
| --topo_zk_tls_ca | string | the server ca to use to validate servers when connecting to the zk topo server |
| --topo_zk_tls_cert | string | the cert to use to connect to the zk topo server, requires topo_zk_tls_key, enables TLS |
| --topo_zk_tls_key | string | the key to use to connect to the zk topo server, enables TLS |
| --tracer | string | tracing service to use (default "noop") |
| --tracing-enable-logging | | whether to enable logging in the tracing service |
| --tracing-sampling-rate | float | sampling rate for the probabilistic jaeger sampler (default 0.1) |
| --tracing-sampling-type | string | sampling strategy to use for |
| --v | value | log level for V logs |
| --version | | print binary version |
| --vmodule | value | comma-separated list of pattern=N settings for file-filtered logging |
| --vtctl_healthcheck_retry_delay | duration | delay before retrying a failed healthcheck (default 5s) |
| --vtctl_healthcheck_timeout | duration | the health check timeout period (default 1m0s) |
| --vtctl_healthcheck_topology_refresh | duration | refresh interval for re-reading the topology (default 30s) |
| --vtgate_grpc_ca | string | the server ca to use to validate servers when connecting |
| --vtgate_grpc_cert | string | the cert to use to connect |
| --vtgate_grpc_crl | string | the server crl to use to validate server certificates when connecting |
| --vtgate_grpc_key | string | the key to use to connect |
| --vtgate_grpc_server_name | string | the server name to use to validate server certificate |
| --wait-time | duration | time to wait on an action (default 24h0m0s) |
