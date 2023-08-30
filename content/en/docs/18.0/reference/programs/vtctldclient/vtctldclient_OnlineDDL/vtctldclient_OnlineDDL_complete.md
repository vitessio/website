---
title: OnlineDDL complete
series: vtctldclient
---
## vtctldclient OnlineDDL complete

Complete one or all migrations executed with `--postpone-completion`.

```
vtctldclient OnlineDDL complete <keyspace> <uuid|all>
```

### Examples

```
OnlineDDL complete test_keyspace 82fa54ac_e83e_11ea_96b7_f875a4d24e90
OnlineDDL complete test_keyspace all
```

### Options

```
  -h, --help   help for complete
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient OnlineDDL](../)	 - Operates on online DDL (schema migrations).

