---
title: MoveTables complete
series: vtctldclient
commit: b5b3114ab9371f882762dd66ae0efc5af3a3dbc0
---
## vtctldclient MoveTables complete

Complete a MoveTables VReplication workflow.

```
vtctldclient MoveTables complete
```

### Examples

```
vtctldclient --server localhost:15999 MoveTables --workflow commerce2customer --target-keyspace customer complete
```

### Options

```
      --dry-run              Print the actions that would be taken and report any known errors that would have occurred.
  -h, --help                 help for complete
      --keep-data            Keep the original source table data that was copied by the MoveTables workflow.
      --keep-routing-rules   Keep the routing rules in place that direct table traffic from the source keyspace to the target keyspace of the MoveTables workflow.
      --rename-tables        Keep the original source table data that was copied by the MoveTables workflow, but rename each table to '_<tablename>_old'.
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

* [vtctldclient MoveTables](../)	 - Perform commands related to moving tables from a source keyspace to a target keyspace.

