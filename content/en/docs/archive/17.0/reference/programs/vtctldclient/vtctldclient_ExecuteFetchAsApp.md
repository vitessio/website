---
title: ExecuteFetchAsApp
series: vtctldclient
commit: 3ae5c005a75f782a004e8992be4a4fb95460458e
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
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

