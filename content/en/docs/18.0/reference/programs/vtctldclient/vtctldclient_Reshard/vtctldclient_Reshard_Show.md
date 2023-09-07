---
title: Reshard Show
series: vtctldclient
---
## vtctldclient Reshard Show

Show the details for a reshard VReplication workflow.

```
vtctldclient Reshard Show
```

### Examples

```
vtctldclient --server localhost:15999 reshard --workflow cust2cust --target-keyspace customer show
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

* [vtctldclient Reshard](../)	 - Perform commands related to resharding a keyspace.

