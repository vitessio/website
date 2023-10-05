---
title: VDiff show
series: vtctldclient
commit: b089f78945653f6acd17c66f896820e36df49437
---
## vtctldclient VDiff show

Show the status of a VDiff.

```
vtctldclient VDiff show
```

### Examples

```
vtctldclient --server localhost:15999 vdiff --workflow commerce2customer --target-keyspace show last
vtctldclient --server localhost:15999 vdiff --workflow commerce2customer --target-keyspace show a037a9e2-5628-11ee-8c99-0242ac120002
vtctldclient --server localhost:15999 vdiff --workflow commerce2customer --target-keyspace show all
```

### Options

```
  -h, --help      help for show
      --verbose   Show verbose output in summaries
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

* [vtctldclient VDiff](../)	 - Perform commands related to diffing tables involved in a VReplication workflow between the source and target.

