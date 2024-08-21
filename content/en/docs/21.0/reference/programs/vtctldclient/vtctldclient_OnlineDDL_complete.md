---
title: OnlineDDL complete
series: vtctldclient
commit: 471ab1a20a1f7f1f333ddd378b3edc71ad6de7a3
---
## vtctldclient OnlineDDL complete

Complete one or all migrations executed with --postpone-completion

```
vtctldclient OnlineDDL complete <keyspace> <uuid|all>
```

### Examples

```
OnlineDDL complete test_keyspace 82fa54ac_e83e_11ea_96b7_f875a4d24e90
```

### Options

```
  -h, --help   help for complete
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

