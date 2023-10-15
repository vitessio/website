---
title: OnlineDDL throttle
series: vtctldclient
commit: 476ca265d0583549c05a3ab88f76bc8d24174364
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
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient OnlineDDL](../)	 - Operates on online DDL (schema migrations).

