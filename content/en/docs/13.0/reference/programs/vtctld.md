---
title: vtctld
description: The Vitess Admin GUI
---

`vtctld` is a webserver interface to administer a Vitess cluster. It is usually the first Vitess component to be started after a valid global topology service has been created.

## Example Usage

The following example launches the `vtctld` daemon on port 15000:

```bash
export TOPOLOGY_FLAGS="-topo_implementation etcd2 -topo_global_server_address localhost:2379 -topo_global_root /vitess/global"
export VTDATAROOT="/tmp"

vtctld \
 $TOPOLOGY_FLAGS \
 -workflow_manager_init \
 -workflow_manager_use_election \
 -service_map 'grpc-vtctl' \
 -backup_storage_implementation file \
 -file_backup_storage_root $VTDATAROOT/backups \
 -log_dir $VTDATAROOT/tmp \
 -port 15000 \
 -grpc_port 15999
```

## Options

| Name | Type     | Definition |
| :------------------------------------ |:---------| :----------------------------------------------------------------------------------------- |
| -action_timeout | duration | Time to wait for an action before resorting to force (default 2m0s) |
| -alsologtostderr | boolean  | Log to standard error as well as files |
| -app_idle_timeout | duration | Idle timeout for app connections (default 1m0s) |
| -app_pool_size | int      | Size of the connection pool for app connections (default 40) |
| -azblob_backup_account_key_file | string   | Path to a file containing the Azure Storage account key; if this flag is unset, the environment variable VT_AZBLOB_ACCOUNT_KEY will be used as the key itself (NOT a file path) |
| -azblob_backup_account_name | string   | Azure Storage Account name for backups; if this flag is unset, the environment variable VT_AZBLOB_ACCOUNT_NAME will be used |
| -azblob_backup_container_name | string   | Azure Blob Container Name |
| -azblob_backup_parallelism | int      | Azure Blob operation parallelism (requires extra memory when increased) (default 1) |
| -azblob_backup_storage_root | string   | Root prefix for all backup-related Azure Blobs; this should exclude both initial and trailing '/' (e.g. just 'a/b' not '/a/b/') |
| -backup_engine_implementation | string   | Specifies which implementation to use for creating new backups (builtin or xtrabackup). Restores will always be done with whichever engine created a given backup. (default "builtin") |
| -backup_storage_block_size | int      | If backup_storage_compress is true, backup_storage_block_size sets the byte size for each block while compressing (default is 250000) |
| -backup_storage_compress | boolean | If set, the backup files will be compressed. Set to false for instance if a backup_storage_hook is specified and it compresses the data (default true) |
| -backup_storage_hook | string   | If set, we send the contents of the backup files through this hook |
| -backup_storage_implementation | string   | Which implementation to use for the backup storage feature |
| -backup_storage_number_blocks | int      | If backup_storage_compress is true, backup_storage_number_blocks sets the number of blocks that can be processed at once, before the writer blocks, during compression. It should be equal to the number of CPUs available for compression (default 2) |
| -binlog_use_v3_resharding_mode | boolean | True if the binlog streamer should use V3-style sharding, which doesn't require a preset sharding key column (default true) |
| -catch-sigpipe | boolean | Catch and ignore SIGPIPE on stdout and stderr if specified |
| -cell | string   | Cell to use |
| -ceph_backup_storage_config | string   | Path to JSON config file for ceph backup storage (default "ceph_backup_config.json") |
| -consul_auth_static_file | string   | JSON File to read the topos/tokens from |
| -cpu_profile | string   | Deprecated: use '-pprof=cpu' instead |
| -datadog-agent-host | string   | Host to send spans to; if empty, no tracing will be done |
| -datadog-agent-port | string   | Port to send spans to; if empty, no tracing will be done |
| -durability_policy | string   | Type of durability to enforce. Other values are dictated by registered plugins (default "none") |
| -emit_stats | boolean | If set, emit stats to push-based monitoring and stats backends |
| -enable_realtime_stats | boolean | Required for the Realtime Stats view. If set, vtctld will maintain a streaming RPC to each tablet (in all cells) to gather the realtime health stats |
| -file_backup_storage_root | string   | Root directory for the file backup storage |
| -gcs_backup_storage_bucket | string   | Google Cloud Storage bucket to use for backups |
| -gcs_backup_storage_root | string   | Root prefix for all backup-related object names |
| -grpc_auth_mode | string   | Which auth plugin implementation to use (eg: static) |
| -grpc_auth_mtls_allowed_substrings | string   | List of substrings of at least one of the client certificate names (separated by colon) |
| -grpc_auth_static_client_creds | string   | When using grpc_static_auth in the server, this file provides the credentials to use to authenticate with the server |
| -grpc_auth_static_password_file | string   | JSON File to read the users/passwords from |
| -grpc_ca | string   | Server CA to use for gRPC connections, requires TLS, and enforces client certificate check |
| -grpc_cert | string   | Server certificate to use for gRPC connections, requires grpc_key, enables TLS |
| -grpc_compression | string   | Which protocol to use for compressing gRPC. Supported: snappy (default: nothing) |
| -grpc_crl | string   | Path to a certificate revocation list in PEM format, client certificates will be further verified against this file during TLS handshake |
| -grpc_enable_optional_tls | boolean | Enable optional TLS mode when a server accepts both TLS and plain-text connections on the same port |
| -grpc_enable_tracing | boolean | Enable gRPC tracing |
| -grpc_initial_conn_window_size | int      | gRPC initial connection window size |
| -grpc_initial_window_size | int      | gRPC initial window size |
| -grpc_keepalive_time | duration | After a duration of this time, if the client doesn't see any activity, it pings the server to see if the transport is still alive (default 10s) |
| -grpc_keepalive_timeout | duration | After having pinged for keepalive check, the client waits for a duration of Timeout and if no activity is seen even after that, the connection is closed (default 10s) |
| -grpc_key | string   | Server private key to use for gRPC connections, requires grpc_cert, enables TLS |
| -grpc_max_connection_age | duration | Maximum age of a client connection before GoAway is sent (default 2562047h47m16.854775807s) |
| -grpc_max_connection_age_grace | duration | Additional grace period after grpc_max_connection_age, after which connections are forcibly closed (default 2562047h47m16.854775807s) |
| -grpc_max_message_size | int      | Maximum allowed RPC message size. Larger messages will be rejected by gRPC with the error 'exceeding the max size' (default 16777216) |
| -grpc_port | int      | Port to listen on for gRPC calls |
| -grpc_prometheus | boolean | Enable gRPC monitoring with Prometheus |
| -grpc_server_ca | string   | Path to server CA in PEM format, which will be combine with server cert, return full certificate chain to clients |
| -grpc_server_initial_conn_window_size | int      | gRPC server initial connection window size |
| -grpc_server_initial_window_size | int      | gRPC server initial window size |
| -grpc_server_keepalive_enforcement_policy_min_time | duration | gRPC server minimum keepalive time (default 10s) |
| -grpc_server_keepalive_enforcement_policy_permit_without_stream | boolean | gRPC server permit client keepalive pings even when there are no active streams (RPCs) |
| -jaeger-agent-host | string   | Host and port to send spans to; if empty, no tracing will be done |
| -keep_logs | duration | Keep logs for this long (using ctime) (zero to keep forever) |
| -keep_logs_by_mtime | duration | Keep logs for this long (using mtime) (zero to keep forever) |
| -lameduck-period | duration | Keep running at least this long after SIGTERM before stopping (default 50ms) |
| -log_backtrace_at | value    | When logging hits line file:N, emit a stack trace |
| -log_dir | string   | If non-empty, write log files in this directory |
| -log_err_stacks | boolean | Log stack traces for errors |
| -log_rotate_max_size | uint     | Size in bytes at which logs are rotated (glog.MaxSize) (default 1887436800) |
| -logtostderr | boolean | Log to standard error instead of files |
| -mem-profile-rate | int      | Deprecated: use '-pprof=mem' instead (default 524288) |
| -mutex-profile-fraction | int      | Deprecated: use '-pprof=mutex' instead |
| -onclose_timeout | duration | Wait no more than this for OnClose handlers before stopping (default 1ns) |
| -online_ddl_check_interval | duration | Interval polling for new online DDL requests (default 1m0s) |
| -onterm_timeout | duration | Wait no more than this for OnTermSync handlers before stopping (default 10s) |
| -opentsdb_uri | string   | URI of opentsdb /api/put method |
| -pid_file | string   | If set, the process will write its pid to the named file, and delete it on graceful shutdown |
| -pool_hostname_resolve_interval | duration | If set force an update to all hostnames and reconnect if changed, defaults to 0 (disabled) |
| -port | int      | Port for the server |
| -pprof | string   | Enable profiling |
| -proxy_tablets | boolean | Setting this true will make vtctld proxy the tablet status instead of redirecting to them |
| -purge_logs_interval | duration | How often to try to remove old logs (default 1h0m0s) |
| -remote_operation_timeout | duration | Time to wait for a remote operation (default 30s) |
| -s3_backup_aws_endpoint | string   | Endpoint of the S3 backend (region must be provided) |
| -s3_backup_aws_region | string   | AWS region to use (default "us-east-1") |
| -s3_backup_aws_retries | int      | AWS request retries (default -1) |
| -s3_backup_force_path_style | boolean | Force the S3 path style |
| -s3_backup_log_level | string   | Determine the S3 loglevel to use from LogOff, LogDebug, LogDebugWithSigning, LogDebugWithHTTPBody, LogDebugWithRequestRetries, LogDebugWithRequestErrors (default "LogOff") |
| -s3_backup_server_side_encryption | string   | Server-side encryption algorithm (e.g., AES256, aws:kms, sse_c:/path/to/key/file) |
| -s3_backup_storage_bucket | string   | S3 bucket to use for backups |
| -s3_backup_storage_root | string   | Root prefix for all backup-related object names |
| -s3_backup_tls_skip_verify_cert | boolean | Skip the 'certificate is valid' check for SSL connections |
| -security_policy | string   | The name of a registered security policy to use for controlling access to URLs - empty means allow all for anyone (built-in policies: deny-all, read-only) |
| -service_map | value    | Comma separated list of services to enable (or disable if prefixed with '-') Example: grpc-vtworker |
| -stats_backend | string   | The name of the registered push-based monitoring/stats backend to use |
| -stats_combine_dimensions | string   | List of dimensions to be combined into a single "all" value in exported stats vars |
| -stats_common_tags | string   | Comma-separated list of common tags for the stats backend. It provides both label and values. Example: label1:value1,label2:value2 |
| -stats_drop_variables | string   | Variables to be dropped from the list of exported variables |
| -stats_emit_period | duration | Interval between emitting stats to all registered backends (default 1m0s) |
| -stderrthreshold | value    | Logs at or above this threshold go to stderr (default 1) |
| -tracer | string   | Tracing service to use (default "noop") |
| -tracing-enable-logging | boolean | Whether to enable logging in the tracing service |
| -tracing-sampling-rate | value    | Sampling rate for the probabilistic jaeger sampler (default 0.1) |
| -tracing-sampling-type | value    | Sampling strategy to use for jaeger. Possible values are 'const', 'probabilistic', 'rateLimiting', or 'remote' (default const) |
| -v | value    | Log level for V logs |
| -version | boolean | Print binary version |
| -vmodule | value    | Comma-separated list of pattern=N settings for file-filtered logging |
| -vstream_dynamic_packet_size | boolean | Enable dynamic packet sizing for VReplication. This will adjust the packet size during replication to improve performance (default true) |
| -vstream_packet_size | int      | Suggested packet size for VReplication streamer. This is used only as a recommendation. The actual packet size may be more or less than this amount (default 250000) |
| -vtctl_client_protocol | string   | The protocol to use to talk to the vtctl server (default "grpc") |
| -vtctl_healthcheck_retry_delay | duration | Delay before retrying a failed healthcheck (default 5s) |
| -vtctl_healthcheck_timeout | duration | The health check timeout period (default 1m0s) |
| -vtctl_healthcheck_topology_refresh | duration | Refresh interval for re-reading the topology (default 30s) |
| -vtctld_show_topology_crud | boolean | Controls the display of the CRUD topology actions in the vtctld UI (default true) |
| -vtworker_client_grpc_ca | string   | The server CA to use to validate servers when connecting |
| -vtworker_client_grpc_cert | string   | The cert to use to connect |
| -vtworker_client_grpc_crl | string   | The server crl to use to validate server certificates when connecting |
| -vtworker_client_grpc_key | string   | The key to use to connect |
| -vtworker_client_grpc_server_name | string   | The server name to use to validate server certificate |
| -vtworker_client_protocol | string   | The protocol to use to talk to the vtworker server (default "grpc") |
| -wait_for_drain_sleep_rdonly | duration | Time to wait before shutting the query service on old RDONLY tablets during MigrateServedTypes (default 5s) |
| -wait_for_drain_sleep_replica | duration | Time to wait before shutting the query service on old REPLICA tablets during MigrateServedTypes (default 15s) |
| -watch_replication_stream | boolean | When enabled, vttablet will stream the MySQL replication stream from the local server, and use it to update schema when it sees a DDL |
| -web_dir | string   | NOT USED, here for backward compatibility |
| -web_dir2 | string   | NOT USED, here for backward compatibility |
| -workflow_manager_disable | value    | Comma separated list of workflow types to disable |
| -workflow_manager_init | boolean | Initialize the workflow manager in this vtctld instance |
| -workflow_manager_use_election | boolean | If specified, will use a topology server-based master election to ensure only one workflow manager is active at a time |
| -xbstream_restore_flags | string   | Flags to pass to xbstream command during restore. These should be space separated and will be added to the end of the command. These need to match the ones used for backup e.g. --compress / --decompress, --encrypt / --decrypt |
| -xtrabackup_backup_flags | string   | Flags to pass to backup command. These should be space separated and will be added to the end of the command |
| -xtrabackup_prepare_flags | string   | Flags to pass to prepare command. These should be space separated and will be added to the end of the command |
| -xtrabackup_root_path | string   | Directory location of the xtrabackup and xbstream executables, e.g., /usr/bin |
| -xtrabackup_stream_mode | string   | Which mode to use if streaming, valid values are tar and xbstream (default "tar") |
| -xtrabackup_stripe_block_size | uint     | Size in bytes of each block that gets sent to a given stripe before rotating to the next stripe (default 102400) |
| -xtrabackup_stripes | uint     | If greater than 0, use data striping across this many destination files to parallelize data transfer and decompression |
| -xtrabackup_user | string   | User that xtrabackup will use to connect to the database server. This user must have all necessary privileges. For details, please refer to xtrabackup documentation |
