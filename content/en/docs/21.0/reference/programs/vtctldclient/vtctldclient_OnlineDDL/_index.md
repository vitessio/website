---
title: OnlineDDL
series: vtctldclient
commit: cd0c2b594b2d5178a9c8ac081eaee7d1b7eef28a
---

## vtctldclient OnlineDDL

Operates on online DDL (schema migrations).

### Options

```
  -h, --help   help for OnlineDDL
```

### Options Inherited from Parent Commands

```
      --action_timeout duration              timeout to use for the command (default 1h0m0s)
      --compact                              use compact format for otherwise verbose outputs
      --server string                        server to use for the connection (required)
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
```

### See Also

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.
* [vtctldclient OnlineDDL cancel](./vtctldclient_onlineddl_cancel/)	 - Cancel one or all migrations, terminating any running ones as needed.
* [vtctldclient OnlineDDL cleanup](./vtctldclient_onlineddl_cleanup/)	 - Mark a given schema migration ready for artifact cleanup.
* [vtctldclient OnlineDDL complete](./vtctldclient_onlineddl_complete/)	 - Complete one or all migrations executed with --postpone-completion
* [vtctldclient OnlineDDL force-cutover](./vtctldclient_onlineddl_force-cutover/)	 - Mark a given schema migration, or all pending migrations, for forced cut over.
* [vtctldclient OnlineDDL launch](./vtctldclient_onlineddl_launch/)	 - Launch one or all migrations executed with --postpone-launch
* [vtctldclient OnlineDDL retry](./vtctldclient_onlineddl_retry/)	 - Mark a given schema migration for retry.
* [vtctldclient OnlineDDL show](./vtctldclient_onlineddl_show/)	 - Display information about online DDL operations.
* [vtctldclient OnlineDDL throttle](./vtctldclient_onlineddl_throttle/)	 - Throttles one or all migrations
* [vtctldclient OnlineDDL unthrottle](./vtctldclient_onlineddl_unthrottle/)	 - Unthrottles one or all migrations

