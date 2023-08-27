---
title: OnlineDDL
series: vtctldclient
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
* [vtctldclient OnlineDDL cleanup](./vtctldclient_onlineddl_cleanup/)	 - Mark a given schema migration ready for artifact cleanup.
* [vtctldclient OnlineDDL retry](./vtctldclient_onlineddl_retry/)	 - Mark a given schema migration for retry.
* [vtctldclient OnlineDDL show](./vtctldclient_onlineddl_show/)	 - Display information about online DDL operations.
