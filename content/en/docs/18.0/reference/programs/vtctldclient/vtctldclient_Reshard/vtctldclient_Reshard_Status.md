---
title: Reshard Status
series: vtctldclient
---
## vtctldclient Reshard Status

Show the current status for a reshard VReplication workflow.

```
vtctldclient Reshard Status
```

### Examples

```
vtctldclient --server localhost:15999 reshard --workflow cust2cust --target-keyspace customer status
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

* [vtctldclient Reshard](../)	 - Perform commands related to resharding a keyspace.

