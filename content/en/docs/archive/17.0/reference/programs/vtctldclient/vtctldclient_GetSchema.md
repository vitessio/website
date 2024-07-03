---
title: GetSchema
series: vtctldclient
commit: 3ae5c005a75f782a004e8992be4a4fb95460458e
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
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

