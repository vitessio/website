---
title: OnlineDDL cleanup
series: vtctldclient
commit: 476ca265d0583549c05a3ab88f76bc8d24174364
---
## vtctldclient OnlineDDL cleanup

Mark a given schema migration ready for artifact cleanup.

```
vtctldclient OnlineDDL cleanup <keyspace> <uuid>
```

### Examples

```
OnlineDDL cleanup test_keyspace 82fa54ac_e83e_11ea_96b7_f875a4d24e90
```

### Options

```
  -h, --help   help for cleanup
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient OnlineDDL](../)	 - Operates on online DDL (schema migrations).

