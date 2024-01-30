---
title: OnlineDDL complete
series: vtctldclient
commit: f4d1487c72392cec566ed9ab39a00c7d027cc8ee
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
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient OnlineDDL](./vtctldclient_onlineddl/)	 - Operates on online DDL (schema migrations).

