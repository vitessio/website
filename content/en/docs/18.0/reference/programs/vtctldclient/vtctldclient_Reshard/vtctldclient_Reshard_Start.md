---
title: Reshard Start
series: vtctldclient
---
## vtctldclient Reshard Start

Start a reshard workflow.

```
vtctldclient Reshard Start
```

### Examples

```
vtctldclient --server localhost:15999 reshard --workflow cust2cust --target-keyspace customer start
```

### Options

```
  -h, --help   help for Start
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient Reshard](../)	 - Perform commands related to resharding a keyspace.

