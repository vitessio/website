---
title: MoveTables Cancel
series: vtctldclient
---
## vtctldclient MoveTables Cancel

Cancel a moveTables VReplication workflow.

```
vtctldclient MoveTables Cancel
```

### Examples

```
vtctldclient --server localhost:15999 moveTables --workflow cust2cust --target-keyspace customer cancel
```

### Options

```
  -h, --help   help for Cancel
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient MoveTables](../)	 - Perform commands related to moving tables from a source keyspace to a target keyspace.

