---
title: OnlineDDL cancel
series: vtctldclient
commit: d3012c188ea0cfc6837917fc6642ea23be9bb1ff
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
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient OnlineDDL](./vtctldclient_onlineddl/)	 - Operates on online DDL (schema migrations).

