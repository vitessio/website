---
title: CheckThrottler
series: vtctldclient
commit: cd0c2b594b2d5178a9c8ac081eaee7d1b7eef28a
---
## vtctldclient CheckThrottler

Issue a throttler check on the given tablet.

```
vtctldclient CheckThrottler [--app-name <name>] <tablet alias>
```

### Examples

```
CheckThrottler --app-name online-ddl zone1-0000000101
```

### Options

```
      --app-name string      app name to check (default "vitess")
  -h, --help                 help for CheckThrottler
      --ok-if-not-exists     return OK even if metric does not exist
      --request-heartbeats   request heartbeat lease
      --scope string         check scope ('shard', 'self' or leave empty for per-metric defaults)
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

