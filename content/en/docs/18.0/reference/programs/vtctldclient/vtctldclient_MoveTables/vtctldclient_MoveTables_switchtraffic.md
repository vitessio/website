---
title: MoveTables switchtraffic
series: vtctldclient
---
## vtctldclient MoveTables switchtraffic

Switch traffic for a MoveTables VReplication workflow.

```
vtctldclient MoveTables switchtraffic
```

### Examples

```
vtctldclient --server localhost:15999 movetables --workflow commerce2customer --target-keyspace customer switchtraffic --tablet-types "replica,rdonly"
```

### Options

```
  -c, --cells strings                          Cells and/or CellAliases to switch traffic in
      --dry-run                                Print the actions that would be taken and report any known errors that would have occurred
  -h, --help                                   help for switchtraffic
      --max-replication-lag-allowed duration   Allow traffic to be switched only if VReplication lag is below this (default 30s)
      --tablet-types strings                   Tablet types to switch traffic for
      --timeout duration                       Specifies the maximum time to wait, in seconds, for VReplication to catch up on primary tablets. The traffic switch will be cancelled on timeout. (default 30s)
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
      --target-keyspace string    Keyspace where the tables are being moved to and where the workflow exists (required)
```

### SEE ALSO

* [vtctldclient MoveTables](../)	 - Perform commands related to moving tables from a source keyspace to a target keyspace.

