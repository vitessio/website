---
title: Workflow update
series: vtctldclient
commit: b5b3114ab9371f882762dd66ae0efc5af3a3dbc0
---
## vtctldclient Workflow update

Update the configuration parameters for a VReplication workflow.

```
vtctldclient Workflow update
```

### Examples

```
vtctldclient --server localhost:15999 workflow --keyspace customer update --workflow commerce2customer --cells zone1 --cells zone2 -c "zone3,zone4" -c zone5
```

### Options

```
  -c, --cells strings           New Cell(s) or CellAlias(es) (comma-separated) to replicate from.
  -h, --help                    help for update
      --on-ddl string           New instruction on what to do when DDL is encountered in the VReplication stream. Possible values are IGNORE, STOP, EXEC, and EXEC_IGNORE.
  -t, --tablet-types strings    New source tablet types to replicate from (e.g. PRIMARY,REPLICA,RDONLY).
      --tablet-types-in-order   When performing source tablet selection, look for candidates in the type order as they are listed in the tablet-types flag. (default true)
  -w, --workflow string         The workflow you want to update.
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
  -k, --keyspace string           Keyspace context for the workflow.
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient Workflow](../)	 - Administer VReplication workflows (Reshard, MoveTables, etc) in the given keyspace.

