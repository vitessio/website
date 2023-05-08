---
title: vtgate
---

VTGate is a stateless proxy responsible for accepting requests from applications and routing them to the appropriate tablet server(s) for query execution. It speaks both the MySQL Protocol and a gRPC protocol.

## Example Usage

Start a vtgate proxy:

```bash
export TOPOLOGY_FLAGS="-topo_implementation etcd2 -topo_global_server_address localhost:2379 -topo_global_root /vitess/global"
export VTDATAROOT="/tmp"

vtgate \
  $TOPOLOGY_FLAGS \
  -log_dir $VTDATAROOT/tmp \
  -port 15001 \
  -grpc_port 15991 \
  -mysql_server_port 15306 \
  -cell test \
  -cells_to_watch test \
  -tablet_types_to_wait PRIMARY,REPLICA \
  -gateway_implementation tabletgateway \
  -service_map 'grpc-vtgateservice' \
  -pid_file $VTDATAROOT/tmp/vtgate.pid \
  -mysql_auth_server_impl none
```

## Options

The following global options apply to `vtgate`:

| Name | Type     | Definition |
| :------------------------------------ |:---------| :----------------------------------------------------------------------------------------- |
| -allowed_tablet_types | value    | Specifies the tablet types this vtgate is allowed to route queries to |
| -alsologtostderr | boolean  | Log to standard error as well as files |
| -buffer_drain_concurrency | int      | Maximum number of requests retried simultaneously. More concurrency will increase the load on the PRIMARY vttablet when draining the buffer (default 1) |
| -buffer_implementation | string   | The algorithm used for managing request buffering during cluster availability events (allowed values: "keyspace_events" (default), "healthcheck" (legacy value)) |
| -buffer_keyspace_shards | string   | If not empty, limit buffering to these entries (comma separated). Entry format: keyspace or keyspace/shard. Requires --enable_buffer=true |
| -buffer_max_failover_duration | duration | Stop buffering completely if a failover takes longer than this duration (default 20s) |
| -buffer_min_time_between_failovers | duration | Minimum time between the end of a failover and the start of the next one (tracked per shard). Faster consecutive failovers will not trigger buffering (default 1m0s) |
| -buffer_size | int      | Maximum number of buffered requests in flight (across all ongoing failovers) (default 1000) |
| -buffer_window | duration | Duration for at most how long a request should be buffered (default 10s) |
| -catch-sigpipe | boolean  | Catch and ignore SIGPIPE on stdout and stderr if specified |
| -cell | string   | Cell to use (default "test_nj") |
| -cells_to_watch | string   | Comma-separated list of cells for watching tablets |
| -consul_auth_static_file | string   | JSON File to read the topos/tokens from |
| -cpu_profile | string   | Deprecated: use '-pprof=cpu' instead |
| -datadog-agent-host | string   | Host to send spans to; if empty, no tracing will be done |
| -datadog-agent-port | string   | Port to send spans to; if empty, no tracing will be done |
| -dbddl_plugin | string   | Controls how to handle CREATE/DROP DATABASE. Add it if you are using your own database provisioning service (default "fail") |
| -ddl_strategy | string   | Set default strategy for DDL statements. Override with @@ddl_strategy session variable (default "direct") |
| -default_tablet_type | value    | The default tablet type to set for queries, when one is not explicitly selected (default PRIMARY) |
| -disable_local_gateway | boolean | Deprecated: if specified, this process will not route any queries to local tablets in the local cell |
| -discovery_high_replication_lag_minimum_serving | duration | The replication lag considered too high when applying the min_number_serving_vttablets threshold (default 2h0m0s) |
| -discovery_low_replication_lag | duration | The replication lag considered low enough to be healthy (default 30s) |
| -emit_stats | boolean | If set, emit stats to push-based monitoring and stats backends |
| -enable_buffer | boolean | Enable buffering (stalling) of primary traffic during failovers |
| -enable_buffer_dry_run | boolean | Detect and log failover events, but do not actually buffer requests |
| -enable_direct_ddl | boolean | Allow users to submit direct DDL statements (default true) |
| -enable_online_ddl | boolean | Allow users to submit, review and control Online DDL (default true) |
| -enable_system_settings | boolean | This will enable the system settings to be changed per session at the database connection level (default true) |
| -foreign_key_mode | string   | This allows users to provide a method to handle a foreign key constraint in create/alter table. Valid values are: allow, disallow (default "allow") |
| -gate_query_cache_lfu | boolean | Gate server cache algorithm. When set to true, a new cache algorithm based on a TinyLFU admission policy will be used to improve cache behavior and prevent pollution from sparse queries (default true) |
| -gate_query_cache_memory | int      | Gate server query cache size in bytes, maximum amount of memory to be cached. vtgate analyzes every incoming query and generate a query plan, these plans are being cached in a lru cache. This config controls the capacity of the lru cache (default 33554432) |
| -gate_query_cache_size | int      | Gate server query cache size, maximum number of queries to be cached. vtgate analyzes every incoming query and generate a query plan, these plans are being cached in a cache. This config controls the expected amount of unique entries in the cache (default 5000) |
| -gateway_implementation | string   | Deprecated: Only tabletgateway is now supported, discoverygateway is no longer available |
| -gateway_initial_tablet_timeout | duration | At startup, the gateway will wait up to that duration to get one tablet per keyspace/shard/tablettype (default 30s) |
| -grpc_auth_mode | string   | Which auth plugin implementation to use (eg: static) |
| -grpc_auth_mtls_allowed_substrings | string   | List of substrings of at least one of the client certificate names (separated by colon) |
| -grpc_auth_static_client_creds | string   | When using grpc_static_auth in the server, this file provides the credentials to use to authenticate with the server |
| -grpc_auth_static_password_file | string   | JSON File to read the users/passwords from |
| -grpc_ca | string   | Server CA to use for gRPC connections, requires TLS, and enforces client certificate check |
| -grpc_cert | string   | Server certificate to use for gRPC connections, requires grpc_key, enables TLS |
| -grpc_compression | string   | Which protocol to use for compressing gRPC. (Default: nothing) Supported: snappy |
| -grpc_crl | string   | Path to a certificate revocation list in PEM format, client certificates will be further verified against this file during TLS handshake |
| -grpc_enable_optional_tls | boolean | Enable optional TLS mode when a server accepts both TLS and plain-text connections on the same port |
| -grpc_enable_tracing | boolean | Enable GRPC tracing |
| -grpc_initial_conn_window_size | int      | gRPC initial connection window size |
| -grpc_initial_window_size | int      | gRPC initial window size |
| -grpc_keepalive_time | duration | After a duration of this time, if the client doesn't see any activity, it pings the server to see if the transport is still alive (default 10s) |
| -grpc_keepalive_timeout | duration | After having pinged for keepalive check, the client waits for a duration of Timeout and if no activity is seen even after that the connection is closed. (default 10s) |
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
| -grpc_use_effective_callerid | boolean | If set, and SSL is not used, will set the immediate caller id from the effective caller id's principal |
| -healthcheck_retry_delay | duration | Health check retry delay (default 2ms) |
| -healthcheck_timeout | duration | Health check timeout period (default 1m0s) |
| -jaeger-agent-host | string   | Host and port to send spans to; if empty, no tracing will be done |
| -keep_logs | duration | Keep logs for this long (using ctime) (zero to keep forever) |
| -keep_logs_by_mtime | duration | Keep logs for this long (using mtime) (zero to keep forever) |
| -keyspaces_to_watch | value    | Specifies which keyspaces this vtgate should have access to while routing queries or accessing the vschema |
| -lameduck-period | duration | Keep running at least this long after SIGTERM before stopping (default 50ms) |
| -legacy_replication_lag_algorithm | boolean | Use the legacy algorithm when selecting the vttablets for serving (default true) |
| -lock_heartbeat_time | duration | If there is lock function used, this will keep the lock connection active by using this heartbeat (default 5s) |
| -log_backtrace_at | value    | When logging hits line file:N, emit a stack trace |
| -log_dir | string   | If non-empty, write log files in this directory |
| -log_err_stacks | boolean | Log stack traces for errors |
| -log_queries_to_file | string   | Enable query logging to the specified file |
| -log_rotate_max_size | uint     | Size in bytes at which logs are rotated (glog.MaxSize) (default 1887436800) |
| -logtostderr | boolean | Log to standard error instead of files |
| -max_memory_rows | int      | Maximum number of rows that will be held in memory for intermediate results, as well as the final result (default 300000) |
| -max_payload_size | int      | The threshold for query payloads in bytes. A payload greater than this threshold will result in a failure to handle the query |
| -mem-profile-rate | int      | Deprecated: use '-pprof=mem' instead (default 524288) |
| -message_stream_grace_period | duration | The amount of time for a vttablet to resume if it ends a message stream, usually because of a reparent (default 30s) |
| -min_number_serving_vttablets | int      | The minimum number of vttablets for each replicating tablet_type (e.g. replica, rdonly) that will be continue to be used, even with replication lag above discovery_low_replication_lag, but still below discovery_high_replication_lag_minimum_serving (default 2) |
| -mutex-profile-fraction | int      | Deprecated: use '-pprof=mutex' instead |
| -mysql_allow_clear_text_without_tls | boolean | If set, the server will allow the use of a clear text password over non-SSL connections |
| -mysql_auth_server_impl | string   | Which auth server implementation to use. Options: none, ldap, clientcert, static, vault (default "static") |
| -mysql_auth_server_static_file | string   | JSON File to read the users/passwords from |
| -mysql_auth_server_static_string | string   | JSON representation of the users/passwords config |
| -mysql_auth_static_reload_interval | duration | Ticker to reload credentials |
| -mysql_auth_vault_addr | string   | URL to Vault server |
| -mysql_auth_vault_path | string   | Vault path to vtgate credentials JSON blob, e.g.: secret/data/prod/vtgatecreds |
| -mysql_auth_vault_role_mountpoint | string   | Vault AppRole mountpoint; can also be passed using VAULT_MOUNTPOINT environment variable (default "approle") |
| -mysql_auth_vault_role_secretidfile | string   | Path to file containing Vault AppRole secret_id; can also be passed using VAULT_SECRETID environment variable |
| -mysql_auth_vault_roleid | string   | Vault AppRole id; can also be passed using VAULT_ROLEID environment variable |
| -mysql_auth_vault_timeout | duration | Timeout for vault API operations (default 10s) |
| -mysql_auth_vault_tls_ca | string   | Path to CA PEM for validating Vault server certificate |
| -mysql_auth_vault_tokenfile | string   | Path to file containing Vault auth token; token can also be passed using VAULT_TOKEN environment variable |
| -mysql_auth_vault_ttl | duration | How long to cache vtgate credentials from the Vault server (default 30m0s) |
| -mysql_clientcert_auth_method | string   | Client-side authentication method to use. Supported values: mysql_clear_password, dialog (default "mysql_clear_password") |
| -mysql_default_workload | string   | Default session workload (OLTP, OLAP, DBA) (default "OLTP") |
| -mysql_ldap_auth_config_file | string   | JSON File from which to read LDAP server config |
| -mysql_ldap_auth_config_string | string   | JSON representation of LDAP server config |
| -mysql_ldap_auth_method | string   | Client-side authentication method to use. Supported values: mysql_clear_password, dialog (default "mysql_clear_password") |
| -mysql_server_bind_address | string   | Binds on this address when listening to MySQL binary protocol. Useful to restrict listening to 'localhost' only for instance |
| -mysql_server_flush_delay | duration | Delay after which buffered response will be flushed to the client (default 100ms) |
| -mysql_server_port | int      | If set, also listen for MySQL binary protocol connections on this port (default -1) |
| -mysql_server_query_timeout | duration | MySQL query timeout |
| -mysql_server_read_timeout | duration | Connection read timeout |
| -mysql_server_require_secure_transport | boolean | Reject insecure connections, but only if mysql_server_ssl_cert and mysql_server_ssl_key are provided |
| -mysql_server_socket_path | string   | This option specifies the Unix socket file to use when listening for local connections. By default it will be empty and it won't listen to a unix socket |
| -mysql_server_ssl_ca | string   | Path to SSL CA for mysql server plugin SSL. If specified, server will require and validate client certs. |
| -mysql_server_ssl_cert | string   | Path to the SSL cert for mysql server plugin SSL |
| -mysql_server_ssl_crl | string   | Path to SSL CRL for mysql server plugin SSL |
| -mysql_server_ssl_key | string   | Path to SSL key for mysql server plugin SSL |
| -mysql_server_ssl_server_ca | string   | Path to server CA in PEM format, which will be combine with server cert, and return full certificate chain to clients |
| -mysql_server_tls_min_version | string   | Configures the minimal TLS version negotiated when SSL is enabled. Options: TLSv1.0, TLSv1.1, TLSv1.2, TLSv1.3 (Defaults to TLSv1.2) |
| -mysql_server_version | string   | MySQL server version to advertise. |
| -mysql_server_write_timeout | duration | Connection write timeout |
| -mysql_slow_connect_warn_threshold | duration | Warn if it takes more than the given threshold for a MySQL connection to establish |
| -mysql_tcp_version | string   | Select tcp, tcp4, or tcp6 to control the socket type (default "tcp") |
| -no_scatter | boolean | When set to true, the planner will fail instead of producing a plan that includes scatter queries |
| -normalize_queries | boolean | Rewrite queries with bind vars. Turn this off if the app itself sends normalized queries with bind vars (default true) |
| -onclose_timeout | duration | Wait no more than this time for OnClose handlers before stopping (default 1ns) |
| -onterm_timeout | duration | Wait no more than this time for OnTermSync handlers before stopping (default 10s) |
| -opentsdb_uri | string   | URI of opentsdb /api/put method |
| -pid_file | string   | If set, the process will write its pid to the named file, and delete it on graceful shutdown |
| -planner_version | string   | Sets the default planner to use when the session has not changed it. Valid values are: V3, Gen4, Gen4Greedy and Gen4Fallback. Gen4Fallback tries the new gen4 planner and falls back to the V3 planner if the gen4 fails. All Gen4 versions should be considered experimental! (default "v3") |
| -port | int      | Port for the server |
| -pprof | string   | Enable profiling |
| -proxy_protocol | boolean | Enable HAProxy PROXY protocol on MySQL listener socket |
| -purge_logs_interval | duration | How often try to remove old logs (default 1h0m0s) |
| -querylog-filter-tag | string   | String that must be present in the query for it to be logged; if using a value as the tag, you need to disable query normalization |
| -querylog-format | string   | Format for query logs ("text" or "json") (default "text") |
| -querylog-row-threshold | uint     | Number of rows a query has to return or affect before being logged; not useful for streaming queries. 0 means all queries will be logged |
| -redact-debug-ui-queries | boolean | Redact full queries and bind variables from debug UI |
| -remote_operation_timeout | duration | Time to wait for a remote operation (default 30s) |
| -retry-count | int      | Retry count (default 2) |
| -schema_change_signal | boolean | Enable the schema tracker; requires queryserver-config-schema-change-signal to be enabled on the underlying vttablets |
| -schema_change_signal_user | string   | User to be used to send down query to vttablet to retrieve schema changes |
| -security_policy | string   | The name of a registered security policy to use for controlling access to URLs - empty means allow all for anyone (built-in policies: deny-all, read-only) |
| -service_map | value    | Comma separated list of services to enable (or disable if prefixed with '-') Example: grpc-vtworker |
| -sql-max-length-errors | int      | Truncate queries in error logs to the given length (default unlimited) |
| -sql-max-length-ui | int      | Truncate queries in debug UIs to the given length (default 512) |
| -srv_topo_cache_refresh | duration | How frequently to refresh the topology for cached entries (default 1s) |
| -srv_topo_cache_ttl | duration | How long to use cached entries for topology (default 1s) |
| -srv_topo_timeout | duration | Topo server timeout (default 5s) |
| -stats_backend | string   | The name of the registered push-based monitoring/stats backend to use |
| -stats_combine_dimensions | string   | List of dimensions to be combined into a single "all" value in exported stats vars |
| -stats_common_tags | string   | Comma-separated list of common tags for the stats backend. It provides both label and values. Example: label1:value1,label2:value2 |
| -stats_drop_variables | string   | Variables to be dropped from the list of exported variables |
| -stats_emit_period | duration | Interval between emitting stats to all registered backends (default 1m0s) |
| -statsd_address | string   | Address for statsd client |
| -statsd_sample_rate | float    |  (default 1) |
| -stderrthreshold | value    | Logs at or above this threshold go to stderr (default 1) |
| -stream_buffer_size | int      | The number of bytes sent from vtgate for each stream call. It's recommended to keep this value in sync with vttablet's query-server-config-stream-buffer-size (default 32768) |
| -tablet_filters | value    | Specifies a comma-separated list of 'keyspace |
| -tablet_grpc_ca | string   | The server CA to use to validate servers when connecting |
| -tablet_grpc_cert | string   | The cert to use to connect |
| -tablet_grpc_crl | string   | The server crl to use to validate server certificates when connecting |
| -tablet_grpc_key | string   | The key to use to connect |
| -tablet_grpc_server_name | string   | The server name to use to validate server certificate |
| -tablet_manager_protocol | string   | The protocol to use to talk to vttablet (default "grpc") |
| -tablet_protocol | string   | How to talk to the vttablets (default "grpc") |
| -tablet_refresh_interval | duration | Tablet refresh interval (default 1m0s) |
| -tablet_refresh_known_tablets | boolean | Tablet refresh reloads the tablet address/port map from topo in case it changes (default true) |
| -tablet_types_to_wait | string   | Wait till connected for specified tablet types during Gateway initialization |
| -tablet_url_template | string   | Format string describing debug tablet url formatting. See the Go code for getTabletDebugURL() how to customize this. (default "http://{{.GetTabletHostPort}}") |
| -topo_consul_lock_delay | duration | LockDelay for consul session (default 15s) |
| -topo_consul_lock_session_checks | string   | List of checks for consul session (default "serfHealth") |
| -topo_consul_lock_session_ttl | string   | TTL for consul session. |
| -topo_consul_watch_poll_duration | duration | Time of the long poll for watch queries (default 30s) |
| -topo_etcd_lease_ttl | int      | Lease TTL for locks and leader election. The client will use KeepAlive to keep the lease going (default 30) |
| -topo_etcd_tls_ca | string   | Path to the CA to use to validate the server cert when connecting to the etcd topo server |
| -topo_etcd_tls_cert | string   | Path to the client cert to use to connect to the etcd topo server, requires topo_etcd_tls_key, enables TLS |
| -topo_etcd_tls_key | string   | Path to the client key to use to connect to the etcd topo server, enables TLS |
| -topo_global_root | string   | Path of the global topology data in the global topology server |
| -topo_global_server_address | string   | Address of the global topology server |
| -topo_implementation | string   | Topology implementation to use |
| -topo_k8s_context | string   | The kubeconfig context to use, overrides the 'current-context' from the config |
| -topo_k8s_kubeconfig | string   | Path to a valid kubeconfig file. When running as a k8s pod inside the same cluster you wish to use as the topo, you may omit this and the below arguments, and Vitess is capable of auto-discovering the correct values. https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/#accessing-the-api-from-a-pod |
| -topo_k8s_namespace | string   | The kubernetes namespace to use for all objects. Default comes from the context or in-cluster config |
| -topo_read_concurrency | int      | Concurrent topo reads (default 32) |
| -topo_zk_auth_file | string   | Auth to use when connecting to the zk topo server, file contents should be <scheme>:<auth>, e.g., digest:user:pass |
| -topo_zk_base_timeout | duration | zk base timeout (see zk.Connect) (default 30s) |
| -topo_zk_max_concurrency | int      | Maximum number of pending requests to send to a Zookeeper server (default 64) |
| -topo_zk_tls_ca | string   | The server CA to use to validate servers when connecting to the zk topo server |
| -topo_zk_tls_cert | string   | The cert to use to connect to the zk topo server, requires topo_zk_tls_key, enables TLS |
| -topo_zk_tls_key | string   | The key to use to connect to the zk topo server, enables TLS |
| -tracer | string   | Tracing service to use (default "noop") |
| -tracing-enable-logging | boolean  | Whether to enable logging in the tracing service |
| -tracing-sampling-rate | value    | Sampling rate for the probabilistic jaeger sampler (default 0.1) |
| -tracing-sampling-type | value    | Sampling strategy to use for jaeger. possible values are 'const', 'probabilistic', 'rateLimiting', or 'remote' (default const) |
| -transaction_mode | string   | SINGLE: disallow multi-db transactions, MULTI: allow multi-db transactions with best effort commit, TWOPC: allow multi-db transactions with 2pc commit (default "MULTI") |
| -v | value    | Log level for V logs |
| -version | boolean | Print binary version |
| -vmodule | value    | Comma-separated list of pattern=N settings for file-filtered logging |
| -vschema_ddl_authorized_users | string   | List of users authorized to execute vschema ddl operations, or '%' to allow all users. |
| -vtctld_addr | string   | Address of a vtctld instance |
| -vtgate-config-terse-errors | boolean | Prevent bind vars from escaping in returned errors |
| -warn_memory_rows | int      | Warning threshold for in-memory results. A row count higher than this amount will cause the VtGateWarnings.ResultsExceeded counter to be incremented (default 30000) |
| -warn_payload_size | int      | The warning threshold for query payloads in bytes. A payload greater than this threshold will cause the VtGateWarnings.WarnPayloadSizeExceeded counter to be incremented. |
| -warn_sharded_only | boolean | If any features that are only available in unsharded mode are used, query execution warnings will be added to the session |

### Key Options

* -srv_topo_cache_ttl: There may be instances where you will need to increase the cached TTL from the default of 1 second to a higher number:
	* You may want to increase this option if you see that your topo leader goes down and keeps your queries waiting for a few seconds
