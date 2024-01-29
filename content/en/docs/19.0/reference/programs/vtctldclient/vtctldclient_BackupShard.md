---
title: BackupShard
series: vtctldclient
commit: deed3a9a6422022a5f3d8241384919238e069e8c
---
## vtctldclient BackupShard

Finds the most up-to-date REPLICA, RDONLY, or SPARE tablet in the given shard and uses the BackupStorage service on that tablet to create and store a new backup.

### Synopsis

Finds the most up-to-date REPLICA, RDONLY, or SPARE tablet in the given shard and uses the BackupStorage service on that tablet to create and store a new backup.

If no replica-type tablet can be found, the backup can be taken on the primary if --allow-primary is specified.

```
vtctldclient BackupShard [--concurrency <concurrency>] [--allow-primary] [--incremental-from-pos=<pos>|auto] [--upgrade-safe] <keyspace/shard>
```

### Options

```
      --allow-primary                 Allow the primary of a shard to be used for the backup. WARNING: If using the builtin backup engine, this will shutdown mysqld on the primary and stop writes for the duration of the backup.
      --concurrency int32             Specifies the number of compression/checksum jobs to run simultaneously. (default 4)
  -h, --help                          help for BackupShard
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

