---
title: RestoreFromBackup
series: vtctldclient
commit: cb5464edf5d7075feae744f3580f8bc626d185aa
---
## vtctldclient RestoreFromBackup

Stops mysqld on the specified tablet and restores the data from either the latest backup or closest before `backup-timestamp`.

```
vtctldclient RestoreFromBackup [--backup-timestamp|-t <YYYY-mm-DD.HHMMSS>] [--restore-to-pos <pos>] [--dry-run] <tablet_alias>
```

### Options

```
  -t, --backup-timestamp string                          Use the backup taken at, or closest before, this timestamp. Omit to use the latest backup. Timestamp format is "YYYY-mm-DD.HHMMSS".
      --dry-run                                          Only validate restore steps, do not actually restore data
  -h, --help                                             help for RestoreFromBackup
      --restore-to-pos string                            Run a point in time recovery that ends with the given position. This will attempt to use one full backup followed by zero or more incremental backups
      --restore-to-timestamp 2006-01-02T15:04:05Z07:00   Run a point in time recovery that restores up to, and excluding, given timestamp in RFC3339 format (2006-01-02T15:04:05Z07:00). This will attempt to use one full backup followed by zero or more incremental backups
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

