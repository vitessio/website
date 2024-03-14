---
title: RestoreFromBackup
series: vtctldclient
commit: a7f80a82e5d99cf00c253c3902367bec5fa40e5d
---
## vtctldclient RestoreFromBackup

Stops mysqld on the specified tablet and restores the data from either the latest backup or closest before `backup-timestamp`.

```
vtctldclient RestoreFromBackup [--backup-timestamp|-t <YYYY-mm-DD.HHMMSS>] <tablet_alias>
```

### Options

```
  -t, --backup-timestamp string   Use the backup taken at, or closest before, this timestamp. Omit to use the latest backup. Timestamp format is "YYYY-mm-DD.HHMMSS".
  -h, --help                      help for RestoreFromBackup
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

