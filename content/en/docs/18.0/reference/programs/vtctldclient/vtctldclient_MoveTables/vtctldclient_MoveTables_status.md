---
title: MoveTables Status
series: vtctldclient
---
## vtctldclient MoveTables Status

Show the current status for a moveTables VReplication workflow.

```
vtctldclient MoveTables Status
```

### Examples

```
vtctldclient --server localhost:15999 moveTables --workflow cust2cust --target-keyspace customer status
```

### Options

```
  -h, --help   help for Status
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient MoveTables](../)	 - Perform commands related to moving tables from a source keyspace to a target keyspace.

