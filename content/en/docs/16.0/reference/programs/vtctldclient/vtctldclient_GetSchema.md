---
title: GetSchema
series: vtctldclient
---
## vtctldclient GetSchema

Displays the full schema for a tablet, optionally restricted to the specified tables/views.

```
vtctldclient GetSchema [--tables TABLES ...] [--exclude-tables EXCLUDE_TABLES ...] [{--table-names-only | --table-sizes-only}] [--include-views] alias
```

### Options

```
      --exclude-tables /regexp/   List of tables to exclude from the result. Each is either an exact match, or a regular expression of the form /regexp/.
  -h, --help                      help for GetSchema
      --include-views             Includes views in the output in addition to base tables.
  -n, --table-names-only          Display only table names in the result.
      --table-schema-only         Skip introspecting columns and fields metadata.
  -s, --table-sizes-only          Display only size information for matching tables. Ignored if --table-names-only is set.
      --tables /regexp/           List of tables to display the schema for. Each is either an exact match, or a regular expression of the form /regexp/.
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

