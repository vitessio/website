---
title: MoveTables Show
series: vtctldclient
---
## vtctldclient MoveTables Show

Show the details for a moveTables VReplication workflow.

```
vtctldclient MoveTables Show
```

### Examples

```
vtctldclient --server localhost:15999 moveTables --workflow cust2cust --target-keyspace customer show
```

### Options

```
  -h, --help   help for Show
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient MoveTables](../)	 - Perform commands related to moving tables from a source keyspace to a target keyspace.

