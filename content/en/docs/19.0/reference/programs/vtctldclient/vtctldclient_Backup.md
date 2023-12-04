---
title: Backup
series: vtctldclient
commit: cd9693c40a7965e7aebaf8c749e9742c6dca0729
---
## vtctldclient Backup

Uses the BackupStorage service on the given tablet to create and store a new backup.

```
vtctldclient Backup [--concurrency <concurrency>] [--allow-primary] [--incremental-from-pos=<pos>|auto] [--upgrade-safe] <tablet_alias>
```

### Options

```
      --allow-primary                 Allow the primary of a shard to be used for the backup. WARNING: If using the builtin backup engine, this will shutdown mysqld on the primary and stop writes for the duration of the backup.
      --concurrency uint              Specifies the number of compression/checksum jobs to run simultaneously. (default 4)
  -h, --help                          help for Backup
      --incremental-from-pos string   Position of previous backup. Default: empty. If given, then this backup becomes an incremental backup from given position. If value is 'auto', backup taken from last successful backup position
      --upgrade-safe                  Whether to use innodb_fast_shutdown=0 for the backup so it is safe to use for MySQL upgrades.
```

### Options inherited from parent commands

```
      --action_timeout duration              timeout to use for the command (default 1h0m0s)
      --compact                              use compact format for otherwise verbose outputs
      --server string                        server to use for the connection (required)
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

