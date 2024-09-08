---
title: OnlineDDL cancel
series: vtctldclient
commit: f52a0b141fd20db5af050f5d0e2d8724597b60c0
---
## vtctldclient OnlineDDL cancel

Cancel one or all migrations, terminating any running ones as needed.

```
vtctldclient OnlineDDL cancel <keyspace> <uuid|all>
```

### Examples

```
OnlineDDL cancel test_keyspace 82fa54ac_e83e_11ea_96b7_f875a4d24e90
```

### Options

```
  -h, --help   help for cancel
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

