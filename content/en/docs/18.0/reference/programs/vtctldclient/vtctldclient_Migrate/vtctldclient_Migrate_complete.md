---
title: Migrate complete
series: vtctldclient
commit: b5b3114ab9371f882762dd66ae0efc5af3a3dbc0
---
## vtctldclient Migrate complete

Complete a Migrate VReplication workflow.

```
vtctldclient Migrate complete
```

### Examples

```
vtctldclient --server localhost:15999 Migrate --workflow import --target-keyspace customer complete
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

* [vtctldclient Migrate](../)	 - Migrate is used to import data from an external cluster into the current cluster.

