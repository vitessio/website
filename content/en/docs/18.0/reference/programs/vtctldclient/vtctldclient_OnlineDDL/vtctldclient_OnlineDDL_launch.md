---
title: OnlineDDL launch
series: vtctldclient
---
## vtctldclient OnlineDDL launch

launch one or all migrations executed with --postpone-launch

```
vtctldclient OnlineDDL launch <keyspace> <uuid|all>
```

### Examples

```
OnlineDDL launch test_keyspace 82fa54ac_e83e_11ea_96b7_f875a4d24e90
```

### Options

```
  -h, --help   help for launch
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient OnlineDDL](../)	 - Operates on online DDL (schema migrations).

