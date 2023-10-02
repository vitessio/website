---
title: OnlineDDL
series: vtctldclient
commit: 476ca265d0583549c05a3ab88f76bc8d24174364
---
## vtctldclient OnlineDDL

Operates on online DDL (schema migrations).

### Options

```
  -h, --help   help for OnlineDDL
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.
* [vtctldclient OnlineDDL cancel](./vtctldclient_onlineddl_cancel/)	 - Cancel one or all migrations, terminating any running ones as needed.
* [vtctldclient OnlineDDL cleanup](./vtctldclient_onlineddl_cleanup/)	 - Mark a given schema migration ready for artifact cleanup.
* [vtctldclient OnlineDDL complete](./vtctldclient_onlineddl_complete/)	 - Complete one or all migrations executed with --postpone-completion
* [vtctldclient OnlineDDL launch](./vtctldclient_onlineddl_launch/)	 - Launch one or all migrations executed with --postpone-launch
* [vtctldclient OnlineDDL retry](./vtctldclient_onlineddl_retry/)	 - Mark a given schema migration for retry.
* [vtctldclient OnlineDDL show](./vtctldclient_onlineddl_show/)	 - Display information about online DDL operations.
* [vtctldclient OnlineDDL throttle](./vtctldclient_onlineddl_throttle/)	 - Throttles one or all migrations
* [vtctldclient OnlineDDL unthrottle](./vtctldclient_onlineddl_unthrottle/)	 - Unthrottles one or all migrations

