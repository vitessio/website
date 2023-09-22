---
title: Reshard create
series: vtctldclient
---
## vtctldclient Reshard create

Create and optionally run a reshard VReplication workflow.

```
vtctldclient Reshard create
```

### Examples

```
vtctldclient --server localhost:15999 reshard --workflow customer2customer --target-keyspace customer create --source_shards="0" --target_shards="-80,80-" --cells zone1 --cells zone2 --tablet-types replica
```

### Options

```
      --auto-start                         Start the MoveTables workflow after creating it. (default true)
  -c, --cells strings                      Cells and/or CellAliases to copy table data from.
      --defer-secondary-keys               Defer secondary index creation for a table until after it has been copied.
  -h, --help                               help for create
      --on-ddl string                      What to do when DDL is encountered in the VReplication stream. Possible values are IGNORE, STOP, EXEC, and EXEC_IGNORE. (default "IGNORE")
      --skip-schema-copy                   Skip copying the schema from the source shards to the target shards.
      --source-shards strings              Source shards.
      --stop-after-copy                    Stop the MoveTables workflow after it's finished copying the existing rows and before it starts replicating changes.
      --tablet-types strings               Source tablet types to replicate table data from (e.g. PRIMARY,REPLICA,RDONLY).
      --tablet-types-in-preference-order   When performing source tablet selection, look for candidates in the type order as they are listed in the tablet-types flag. (default true)
      --target-shards strings              Target shards.
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

