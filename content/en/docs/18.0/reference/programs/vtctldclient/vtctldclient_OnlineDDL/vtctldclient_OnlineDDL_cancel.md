---
title: OnlineDDL cancel
series: vtctldclient
---
## vtctldclient OnlineDDL cancel

Cancel one or all pending migrations, terminating any actively running ones.

```
vtctldclient OnlineDDL cancel <keyspace> <uuid|all>
```

### Examples

```
OnlineDDL cancel test_keyspace 82fa54ac_e83e_11ea_96b7_f875a4d24e90
OnlineDDL cancel test_keyspace all
```

### Options

```
  -h, --help   help for cancel
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient OnlineDDL](../)	 - Operates on online DDL (schema migrations).

