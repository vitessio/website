---
title: OnlineDDL unthrottle
series: vtctldclient
---
## vtctldclient OnlineDDL unthrottle

Unthrottle one or all migrations.

```
vtctldclient OnlineDDL unthrottle <keyspace> <uuid|all>
```

Note that if you issue a `vtctldclient OnlineDDL throttle my_keyspace all`, then throttling applies to all migrations, current and future. It is then impossible to exclude a specific migration via `vtctldclient OnlineDDL unthrottle my_keyspace 82fa54ac_e83e_11ea_96b7_f875a4d24e90`.

This command is the equivalent of `UpdateThrottlerConfig --unthrottled-app=online-ddl`.

### Examples

```
OnlineDDL unthrottle test_keyspace 82fa54ac_e83e_11ea_96b7_f875a4d24e90
OnlineDDL unthrottle test_keyspace all
```

### Options

```
  -h, --help   help for unthrottle
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient OnlineDDL](../)	 - Operates on online DDL (schema migrations).

