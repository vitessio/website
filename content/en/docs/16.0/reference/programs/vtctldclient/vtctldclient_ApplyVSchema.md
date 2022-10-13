---
title: ApplyVSchema
series: vtctldclient
---
## vtctldclient ApplyVSchema

Applies the VTGate routing schema to the provided keyspace. Shows the result after application.

```
vtctldclient ApplyVSchema {--vschema=<vschema> || --vschema-file=<vschema file> || --sql=<sql> || --sql-file=<sql file>} [--cells=c1,c2,...] [--skip-rebuild] [--dry-run] <keyspace>
```

### Options

```
      --cells strings                           Limits the rebuild to the specified cells, after application. Ignored if --skip-rebuild is set.
      --dry-run                                 If set, do not save the altered vschema, simply echo to console.
  -h, --help                                    help for ApplyVSchema
      --skip-rebuild                            Skip rebuilding the SrvSchema objects.
      --sql alter table t add vindex hash(id)   A VSchema DDL SQL statement, e.g. alter table t add vindex hash(id).
      --sql-file string                         Path to a file containing a VSchema DDL SQL.
      --vschema string                          VSchema to apply, in JSON form.
      --vschema-file string                     Path to a file containing the vschema to apply, in JSON form.
```

### Options inherited from parent commands

```
      --action_timeout duration           timeout for the total command (default 1h0m0s)
      --emit_stats                        If set, emit stats to push-based monitoring and stats backends
      --server string                     server to use for connection (required)
      --stats_backend string              The name of the registered push-based monitoring/stats backend to use
      --stats_combine_dimensions string   List of dimensions to be combined into a single "all" value in exported stats vars
      --stats_common_tags strings         Comma-separated list of common tags for the stats backend. It provides both label and values. Example: label1:value1,label2:value2
      --stats_drop_variables string       Variables to be dropped from the list of exported variables.
      --stats_emit_period duration        Interval between emitting stats to all registered backends (default 1m0s)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

