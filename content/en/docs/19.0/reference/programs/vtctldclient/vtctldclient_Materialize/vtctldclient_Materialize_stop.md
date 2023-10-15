---
title: Materialize stop
series: vtctldclient
commit: 314ebcf13923f98945595208d5099eca4a7184ea
---
## vtctldclient Materialize stop

Stop a Materialize workflow.

```
vtctldclient Materialize stop
```

### Examples

```
vtctldclient --server localhost:15999 Materialize --workflow product_sales --target-keyspace customer stop
```

### Options

```
  -h, --help   help for stop
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

* [vtctldclient Materialize](../)	 - Perform commands related to materializing query results from the source keyspace into tables in the target keyspace.

