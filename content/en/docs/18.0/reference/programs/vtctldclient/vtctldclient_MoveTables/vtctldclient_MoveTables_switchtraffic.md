---
title: MoveTables SwitchTraffic
series: vtctldclient
---
## vtctldclient MoveTables SwitchTraffic

Switch traffic for a moveTables VReplication workflow.

```
vtctldclient MoveTables SwitchTraffic
```

### Examples

```
vtctldclient --server localhost:15999 moveTables --workflow cust2cust --target-keyspace customer switchtraffic --tablet-types "replica,rdonly"
```

### Options

```
  -c, --cells strings                          Cells and/or CellAliases to switch traffic in
      --dry-run                                Print the actions that would be taken and report any known errors that would have occurred
      --enable-reverse-replication             Setup replication going back to the original source keyspace to support rolling back the traffic cutover (default true)
  -h, --help                                   help for SwitchTraffic
      --initialize-target-sequences            When moving tables from an unsharded keyspace to a sharded keyspace, initialize any sequences that are being used on the target when switching writes.
      --max-replication-lag-allowed duration   Allow traffic to be switched only if VReplication lag is below this (default 30s)
      --tablet-types strings                   Tablet types to switch traffic for
      --timeout duration                       Specifies the maximum time to wait, in seconds, for VReplication to catch up on primary tablets. The traffic switch will be cancelled on timeout. (default 30s)
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient MoveTables](../)	 - Perform commands related to moving tables from a source keyspace to a target keyspace.

