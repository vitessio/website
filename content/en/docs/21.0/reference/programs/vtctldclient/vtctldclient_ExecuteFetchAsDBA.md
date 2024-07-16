---
title: ExecuteFetchAsDBA
series: vtctldclient
commit: cd0c2b594b2d5178a9c8ac081eaee7d1b7eef28a
---
## vtctldclient ExecuteFetchAsDBA

Executes the given query as the DBA user on the remote tablet.

```
vtctldclient ExecuteFetchAsDBA [--max-rows <max-rows>] [--json|-j] [--disable-binlogs] [--reload-schema] <tablet alias> <query>
```

### Options

```
      --disable-binlogs   Disables binary logging during the query.
  -h, --help              help for ExecuteFetchAsDBA
  -j, --json              Output the results in JSON instead of a human-readable table.
      --max-rows int      The maximum number of rows to fetch from the remote tablet. (default 10000)
      --reload-schema     Instructs the tablet to reload its schema after executing the query.
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

