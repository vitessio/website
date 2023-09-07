---
title: Reshard Cancel
series: vtctldclient
---
## vtctldclient Reshard Cancel

Cancel a reshard VReplication workflow.

```
vtctldclient Reshard Cancel
```

### Examples

```
vtctldclient --server localhost:15999 reshard --workflow cust2cust --target-keyspace customer cancel
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

* [vtctldclient Reshard](../)	 - Perform commands related to resharding a keyspace.

