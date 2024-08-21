---
title: GetSchema
series: vtctldclient
commit: 7e8f008834c0278b8df733d606940a629b67a9d9
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
      --action_timeout duration              timeout to use for the command (default 1h0m0s)
      --compact                              use compact format for otherwise verbose outputs
      --server string                        server to use for the connection (required)
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

