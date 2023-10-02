---
title: Reshard start
series: vtctldclient
commit: b089f78945653f6acd17c66f896820e36df49437
---
## vtctldclient Reshard start

Start a Reshard workflow.

```
vtctldclient Reshard start
```

### Examples

```
vtctldclient --server localhost:15999 Reshard --workflow cust2cust --target-keyspace customer start
```

### Options

```
  -h, --help   help for start
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --format string             The format of the output; supported formats are: text,json. (default "text")
      --server string             server to use for connection (required)
      --target-keyspace string    Target keyspace for this workflow.
  -w, --workflow string           The workflow you want to perform the command on.
```

### SEE ALSO

* [vtctldclient Reshard](../)	 - Perform commands related to resharding a keyspace.

