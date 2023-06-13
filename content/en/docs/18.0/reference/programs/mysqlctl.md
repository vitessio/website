---
title: mysqlctl
---

`mysqlctl` is a command-line client used for managing `mysqld` instances. It is responsible for bootstrapping tasks such as generating a configuration file for `mysqld` and initializing the instance and its data directory.

The `mysqld_safe` watchdog is utilized when present. This helps ensure that `mysqld` is automatically restarted after failures.

## Commands

### init [--wait_time=5m] [--init_db_sql_file=(default)]

Bootstraps a new `mysqld` instance, initializes its data directory, and starts the instance. The MySQL version and flavor will be auto-detected, with a minimal configuration file applied. For example:

```bash
export VTDATAROOT=/tmp
mysqlctl \
 --alsologtostderr \
 --tablet_uid 101 \
 --mysql_port 12345 \
 init
```

### init_config

Bootstraps the configuration for a new `mysqld` instance and initializes its data directory. This command is the same as `init` except the `mysqld` server will not be started. For example:

```bash
export VTDATAROOT=/tmp
mysqlctl \
 --alsologtostderr \
 --tablet_uid 101 \
 --mysql_port 12345 \
 init_config
```

### reinit_config

Regenerate new configuration files for an existing `mysqld` instance (generating new server_id and server_uuid values). This could be helpful to revert configuration changes, or to pick up changes made to the bundled config in newer Vitess versions. For example:

```bash
export VTDATAROOT=/tmp
mysqlctl \
 --alsologtostderr \
 --tablet_uid 101 \
 --mysql_port 12345 \
 reinit_config
```

### teardown [--wait_time=5m] [--force]

{{< warning >}}
This is a destructive operation.
{{</ warning >}}

Shuts down a `mysqld` instance and removes its data directory. For example:

```bash
export VTDATAROOT=/tmp
mysqlctl --tablet_uid 101 --alsologtostderr teardown
```

### start [--wait_time=5m]

Resume an existing `mysqld` instance that was previously bootstrapped with `init` or `init_config`:

```bash
export VTDATAROOT=/tmp
mysqlctl --tablet_uid 101 --alsologtostderr start
```

### shutdown [--wait_time=5m]

Stop a `mysqld` instance that was previously started with `init` or `start`.

For large `mysqld` instances, you may need to extend the `wait_time` to shutdown cleanly.

```bash
export VTDATAROOT=/tmp
mysqlctl --tablet_uid 101 --alsologtostderr shutdown
```

## Options

The following global parameters apply to `mysqlctl`:

| Name | Type | Definition |
| :-------------------------------- | :--------- | :--------- |
| --alsologtostderr | boolean | log to standard error as well as files |
| --app_idle_timeout | duration | Idle timeout for app connections (default 1m0s) |
| --app_pool_size | int | Size of the connection pool for app connections (default 40) |
| --catch-sigpipe | boolean | catch and ignore SIGPIPE on stdout and stderr if specified |
| --db-credentials-file | string | db credentials file; send SIGHUP to reload this file |
| --db-credentials-server | string | db credentials server type (use 'file' for the file implementation) (default "file") |
| --db-credentials-vault-addr | string | URL to Vault server |
| --db-credentials-vault-path | string | Vault path to credentials JSON blob, e.g.: secret/data/prod/dbcreds |
| --db-credentials-vault-role-mountpoint | string | Vault AppRole mountpoint; can also be passed using VAULT_MOUNTPOINT environment variable (default "approle") |
| --db-credentials-vault-role-secretidfile | string | Path to file containing Vault AppRole secret_id; can also be passed using VAULT_SECRETID environment variable |
| --db-credentials-vault-roleid | string | Vault AppRole id; can also be passed using VAULT_ROLEID environment variable |
| --db-credentials-vault-timeout | duration | Timeout for vault API operations (default 10s) |
| --db-credentials-vault-tls-ca | string | Path to CA PEM for validating Vault server certificate |
| --db-credentials-vault-tokenfile | string | Path to file containing Vault auth token; token can also be passed using VAULT_TOKEN environment variable |
| --db-credentials-vault-ttl | duration | How long to cache DB credentials from the Vault server (default 30m0s) |
| --db_charset | string | Character set. Only utf8 or latin1 based character sets are supported. |
| --db_conn_query_info | boolean | enable parsing and processing of QUERY_OK info fields |
| --db_connect_timeout_ms | int | connection timeout to mysqld in milliseconds (0 for no timeout) |
| --db_dba_password | string | db dba password |
| --db_dba_use_ssl | boolean | Set this flag to false to make the dba connection not use ssl (default true) |
| --db_dba_user | string | db dba user userKey (default "vt_dba") |
| --db_flags | uint | Flag values as defined by MySQL. |
| --db_flavor | string | Flavor overrid. Valid value is FilePos. |
| --db_host | string | The host name for the tcp connection. |
| --db_port | int | tcp port |
| --db_server_name | string | server name of the DB we are connecting to. |
| --db_socket | string | The unix socket to connect on. If this is specified, host and port will not be used. |
| --db_ssl_ca | string | connection ssl ca |
| --db_ssl_ca_path | string | connection ssl ca path |
| --db_ssl_cert | string | connection ssl certificate |
| --db_ssl_key | string | connection ssl key |
| --db_ssl_mode | string | SSL mode to connect with. One of disabled, preferred, required, verify_ca & verify_identity. |
| --db_tls_min_version | string | Configures the minimal TLS version negotiated when SSL is enabled. Defaults to TLSv1.2.  Options: TLSv1.0, TLSv1.1, TLSv1.2, TLSv1.3. |
| --dba_idle_timeout | duration | Idle timeout for dba connections (default 1m0s) |
| --dba_pool_size | int | Size of the connection pool for dba connections (default 20) |
| -h, --help | display usage and exit |
| --keep_logs | duration | keep logs for this long (using ctime) (zero to keep forever) |
| --keep_logs_by_mtime | duration | keep logs for this long (using mtime) (zero to keep forever) |
| --lameduck-period | duration | keep running at least this long after SIGTERM before stopping (default 50ms) |
| --log_backtrace_at | value | when logging hits line file:N, emit a stack trace |
| --log_dir | string | If non-empty, write log files in this directory |
| --log_err_stacks | boolean | log stack traces for errors |
| --log_rotate_max_size | uint | size in bytes at which logs are rotated (glog.MaxSize) (default 1887436800) |
| --logtostderr | boolean | log to standard error instead of files |
| --max-stack-size | int | configure the maximum stack size in bytes (default 67108864) |
| --mysql_port | int | mysql port (default 3306) |
| --mysql_server_version | string | MySQL server version to advertise. |
| --mysql_server_flush_delay | duration | Delay after which buffered response will be flushed to the client. (default 100ms) |
| --mysql_socket | string | path to the mysql socket |
| --mysqlctl_client_protocol | string | the protocol to use to talk to the mysqlctl server (default "grpc") |
| --mysqlctl_mycnf_template | string | template file to use for generating the my.cnf file during server init |
| --mysqlctl_socket | string | socket file to use for remote mysqlctl actions (empty for local actions) | 
| --mysqlctl_client_protocol | string | the protocol to use to talk to the mysqlctl server (default "grpc") |
| --mysqlctl_mycnf_template | string | template file to use for generating the my.cnf file during server init |
| --mysqlctl_socket | string | socket file to use for remote mysqlctl actions (empty for local actions) |
| --onterm_timeout | duration | wait no more than this for OnTermSync handlers before stopping (default 10s) |
| --pid_file | string | If set, the process will write its pid to the named file, and delete it on graceful shutdown. |
| --pool_hostname_resolve_interval | duration | if set force an update to all hostnames and reconnect if changed, defaults to 0 (disabled) |
| --pprof | strings | enable profiling |
| --purge_logs_interval | duration | how often try to remove old logs (default 1h0m0s) |
| --replication_connect_retry | duration | how long to wait in between replica reconnect attempts. Only precise to the second. (default 10s) |
| --security_policy | string | the name of a registered security policy to use for controlling access to URLs - empty means allow all for anyone (built-in policies: deny-all, read-only) |
| --service_map | value | comma separated list of services to enable (or disable if prefixed with '-') Example: grpc-queryservice |
| --socket_file | string | Local unix socket file to listen on |
| --stderrthreshold | value | logs at or above this threshold go to stderr (default 1) |
| --tablet_dir | string | The directory within the vtdataroot to store vttablet/mysql files. Defaults to being generated by the tablet uid. |
| --tablet_uid | uint | Tablet UID (default 41983) |
| --v | value | log level for V logs |
| -v, --version | boolean | print binary version |
| --vmodule | string | comma-separated list of pattern=N settings for file-filtered logging |