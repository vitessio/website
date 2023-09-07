---
title: Reshard Stop
series: vtctldclient
---
## vtctldclient Reshard Stop

Stop a reshard workflow.

```
vtctldclient Reshard Stop
```

### Examples

```
vtctldclient --server localhost:15999 reshard --workflow cust2cust --target-keyspace customer stop
```

### Options

```
  -h, --help   help for Stop
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient Reshard](../)	 - Perform commands related to resharding a keyspace.

