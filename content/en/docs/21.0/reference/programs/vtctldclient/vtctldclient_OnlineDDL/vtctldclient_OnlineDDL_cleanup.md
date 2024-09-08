---
title: OnlineDDL cleanup
series: vtctldclient
commit: f52a0b141fd20db5af050f5d0e2d8724597b60c0
---
## vtctldclient OnlineDDL cleanup

Mark a given schema migration, or all complete/failed/cancelled migrations, ready for artifact cleanup.

```
vtctldclient OnlineDDL cleanup <keyspace> <uuid|all>
```

### Examples

```
OnlineDDL cleanup test_keyspace 82fa54ac_e83e_11ea_96b7_f875a4d24e90
```

### Options

```
  -h, --help   help for cleanup
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

* [vtctldclient OnlineDDL](../)	 - Operates on online DDL (schema migrations).

