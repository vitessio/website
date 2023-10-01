---
title: Reshard complete
series: vtctldclient
---
## vtctldclient Reshard complete

Complete a MoveTables VReplication workflow.

```
vtctldclient Reshard complete
```

### Examples

```
vtctldclient --server localhost:15999 movetables --workflow commerce2customer --target-keyspace customer complete
```

### Options

```
  -h, --help   help for complete
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient Reshard](../)	 - Perform commands related to resharding a keyspace.

