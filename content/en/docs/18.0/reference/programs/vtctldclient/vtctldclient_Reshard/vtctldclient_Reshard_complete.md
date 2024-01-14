---
title: Reshard complete
series: vtctldclient
commit: d3012c188ea0cfc6837917fc6642ea23be9bb1ff
---
## vtctldclient Reshard complete

Complete a Reshard VReplication workflow.

```
vtctldclient Reshard complete
```

### Examples

```
vtctldclient --server localhost:15999 Reshard --workflow cust2cust --target-keyspace customer complete
```

### Options

```
  -h, --help   help for complete
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --format string             The format of the output; supported formats are: text,json. (default "text")
      --server string             server to use for the connection (required)
      --target-keyspace string    Target keyspace for this workflow.
  -w, --workflow string           The workflow you want to perform the command on.
```

### SEE ALSO

* [vtctldclient Reshard](../)	 - Perform commands related to resharding a keyspace.

