---
title: OnlineDDL throttle
series: vtctldclient
commit: d3ff5982ddbbb04da1c9ac3c0bff9b09c904c749
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
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient OnlineDDL](../)	 - Operates on online DDL (schema migrations).

