---
title: OnlineDDL unthrottle
series: vtctldclient
commit: f4d1487c72392cec566ed9ab39a00c7d027cc8ee
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
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient OnlineDDL](./vtctldclient_onlineddl/)	 - Operates on online DDL (schema migrations).

