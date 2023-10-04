---
title: MoveTables status
series: vtctldclient
commit: b089f78945653f6acd17c66f896820e36df49437
---
## vtctldclient MoveTables status

Show the current status for a MoveTables VReplication workflow.

```
vtctldclient MoveTables status
```

### Examples

```
vtctldclient --server localhost:15999 MoveTables --workflow commerce2customer --target-keyspace customer status
```

### Options

```
  -h, --help   help for status
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

* [vtctldclient MoveTables](../)	 - Perform commands related to moving tables from a source keyspace to a target keyspace.

