---
title: MoveTables create
series: vtctldclient
---
## vtctldclient MoveTables create

Create and optionally run a MoveTables VReplication workflow.

```
vtctldclient MoveTables create
```

### Examples

```
vtctldclient --server localhost:15999 movetables --workflow commerce2customer --target-keyspace customer create --source-keyspace commerce --cells zone1 --cells zone2 --tablet-types replica
```

### Options

```
      --all-tables                         Copy all tables from the source
      --auto-start                         Start the MoveTables workflow after creating it (default true)
  -c, --cells strings                      Cells and/or CellAliases to copy table data from
      --defer-secondary-keys               Defer secondary index creation for a table until after it has been copied
      --exclude-tables strings             Source tables to exclude from copying
  -h, --help                               help for create
      --no-routing-rules                   (Advanced) Do not create routing rules while creating the workflow. See the reference documentation for limitations if you use this flag.
      --on-ddl string                      What to do when DDL is encountered in the VReplication stream. Possible values are IGNORE, STOP, EXEC, and EXEC_IGNORE (default "IGNORE")
      --source-keyspace string             Keyspace where the tables are being moved from (required)
      --source-shards strings              Source shards to copy data from when performing a partial MoveTables (experimental)
      --source-time-zone string            Specifying this causes any DATETIME fields to be converted from the given time zone into UTC
      --stop-after-copy                    Stop the MoveTables workflow after it's finished copying the existing rows and before it starts replicating changes
      --tables strings                     Source tables to copy
      --tablet-types strings               Source tablet types to replicate table data from (e.g. PRIMARY,REPLICA,RDONLY)
      --tablet-types-in-preference-order   When performing source tablet selection, look for candidates in the type order as they are listed in the tablet-types flag (default true)
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
      --target-keyspace string    Keyspace where the tables are being moved to and where the workflow exists (required)
```

### SEE ALSO

* [vtctldclient MoveTables](../)	 - Perform commands related to moving tables from a source keyspace to a target keyspace.

