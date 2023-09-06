---
title: OnlineDDL throttle
series: vtctldclient
---
## vtctldclient OnlineDDL throttle

Throttle one or all migrations.

```
vtctldclient OnlineDDL throttle <keyspace> <uuid|all>
```

When using `all`, throttling applies not only for existing migrations but also for any other future migration. It is the equivalent of running `UpdateThrottlerConfig --throttled-app=online-ddl`.

Note that this command runs successfully whether the throttler is enabled or not. If the throttler is disabled, then migrations are not throttled, but the rule is still there. If the throttler is then enabled, the rule will apply.

### Examples

```
OnlineDDL throttle test_keyspace 82fa54ac_e83e_11ea_96b7_f875a4d24e90
OnlineDDL throttle test_keyspace all
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

