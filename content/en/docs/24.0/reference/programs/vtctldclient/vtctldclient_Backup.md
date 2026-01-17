---
title: Backup
series: vtctldclient
---
## vtctldclient Backup

Uses the BackupStorage service on the given tablet to create and store a new backup.

```
vtctldclient Backup [--concurrency <concurrency>] [--allow-primary] [--incremental-from-pos=<pos>|<backup-name>|auto] [--upgrade-safe] [--backup-engine=enginename] <tablet_alias>
```

### Options

```
      --allow-primary                      Allow the primary of a shard to be used for the backup. WARNING: If using the builtin backup engine, this will shutdown mysqld on the primary and stop writes for the duration of the backup.
      --backup-engine string               Request a specific backup engine for this backup request. Defaults to the preferred backup engine of the target vttablet
      --concurrency int32                  Specifies the number of compression/checksum jobs to run simultaneously. (default 4)
  -h, --help                               help for Backup
      --incremental-from-pos string        Position, or name of backup from which to create an incremental backup. Default: empty. If given, then this backup becomes an incremental backup from given position or given backup. If value is 'auto', this backup will be taken from the last successful backup position.
      --init-backup-sql-fail-on-error      Whether or not to fail the backup if the init SQL queries (--init-backup-sql-queries) fail, which includes if they fail to complete before the specified timeout (--init-backup-sql-timeout)
      --init-backup-sql-queries strings    Queries to execute before initializing the backup
      --init-backup-sql-timeout duration   At what point should we time out the init SQL query (--init-backup-sql-queries) work and either fail the backup job (--init-backup-sql-fail-on-error) or continue on with the backup
      --init-backup-tablet-types strings   Tablet types used for the backup where the init SQL queries (--init-backup-sql-queries) will be executed before initializing the backup
      --mysql-shutdown-timeout duration    Timeout to use when MySQL is being shut down. (default 5m0s)
      --upgrade-safe                       Whether to use innodb_fast_shutdown=0 for the backup so it is safe to use for MySQL upgrades.
```

### Options inherited from parent commands

```
      --action-timeout duration              timeout to use for the command (default 1h0m0s)
      --compact                              use compact format for otherwise verbose outputs
      --server string                        server to use for the connection (required)
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server or alternatively as a standalone binary using --server=internal.

