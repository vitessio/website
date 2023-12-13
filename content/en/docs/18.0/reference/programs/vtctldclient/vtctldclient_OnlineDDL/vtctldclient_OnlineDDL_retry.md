---
title: OnlineDDL retry
series: vtctldclient
commit: 9a6f5262f7707ff80ce85c111d2ff686d85d29cc
---
## vtctldclient OnlineDDL retry

Mark a given schema migration for retry.

```
vtctldclient OnlineDDL retry <keyspace> <uuid>
```

### Examples

```
vtctl OnlineDDL retry test_keyspace 82fa54ac_e83e_11ea_96b7_f875a4d24e90
```

### Options

```
  -h, --help   help for retry
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient OnlineDDL](../)	 - Operates on online DDL (schema migrations).

