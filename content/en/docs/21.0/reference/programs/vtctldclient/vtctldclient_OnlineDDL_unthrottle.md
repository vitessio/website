---
title: OnlineDDL unthrottle
series: vtctldclient
commit: 5cb66a1797a17c05b447acda5f923c62e5912b27
---
## vtctldclient OnlineDDL unthrottle

Unthrottles one or all migrations

```
vtctldclient OnlineDDL unthrottle <keyspace> <uuid|all>
```

### Examples

```
OnlineDDL unthrottle all
```

### Options

```
  -h, --help   help for unthrottle
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

* [vtctldclient OnlineDDL](./vtctldclient_onlineddl/)	 - Operates on online DDL (schema migrations).

