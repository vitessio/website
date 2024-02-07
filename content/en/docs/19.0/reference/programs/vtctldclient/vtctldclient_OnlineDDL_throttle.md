---
title: OnlineDDL throttle
series: vtctldclient
commit: 574162f4cad770c19a20a28526fe46f7de24b999
---
## vtctldclient OnlineDDL throttle

Throttles one or all migrations

```
vtctldclient OnlineDDL throttle <keyspace> <uuid|all>
```

### Examples

```
OnlineDDL throttle all
```

### Options

```
  -h, --help   help for throttle
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

