---
title: Reshard show
series: vtctldclient
---
## vtctldclient Reshard show

Show the details for a Reshard VReplication workflow.

```
vtctldclient Reshard show
```

### Examples

```
vtctldclient --server localhost:15999 Reshard --workflow cust2cust --target-keyspace customer show
```

### Options

```
  -h, --help   help for show
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient Reshard](../)	 - Perform commands related to resharding a keyspace.

