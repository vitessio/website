---
title: VDiff resume
series: vtctldclient
commit: 0f751fbb7c64ca5280c5d4f58d038e1df5477c67
---
## vtctldclient VDiff resume

Resume a VDiff.

```
vtctldclient VDiff resume
```

### Examples

```
vtctldclient --server localhost:15999 vdiff --workflow commerce2customer --target-keyspace resume a037a9e2-5628-11ee-8c99-0242ac120002
```

### Options

```
  -h, --help   help for resume
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

* [vtctldclient VDiff](../)	 - Perform commands related to diffing tables involved in a VReplication workflow between the source and target.

