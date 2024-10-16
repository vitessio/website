---
title: ExecuteFetchAsApp
series: vtctldclient
commit: 376c478ce7daca627d063f22af9121e173787e31
---
## vtctldclient ExecuteFetchAsApp

Executes the given query as the App user on the remote tablet.

```
vtctldclient ExecuteFetchAsApp [--max-rows <max-rows>] [--json|-j] [--use-pool] <tablet-alias> <query>
```

### Options

```
  -h, --help           help for ExecuteFetchAsApp
  -j, --json           Output the results in JSON instead of a human-readable table.
      --max-rows int   The maximum number of rows to fetch from the remote tablet. (default 10000)
      --use-pool       Use the tablet connection pool instead of creating a fresh connection.
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

