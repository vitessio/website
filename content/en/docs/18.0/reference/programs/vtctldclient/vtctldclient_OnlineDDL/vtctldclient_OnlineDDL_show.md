---
title: OnlineDDL show
series: vtctldclient
commit: 476ca265d0583549c05a3ab88f76bc8d24174364
---
## vtctldclient OnlineDDL show

Display information about online DDL operations.

```
vtctldclient OnlineDDL show
```

### Examples

```
OnlineDDL show test_keyspace 82fa54ac_e83e_11ea_96b7_f875a4d24e90
OnlineDDL show test_keyspace all
OnlineDDL show --order descending test_keyspace all
OnlineDDL show --limit 10 test_keyspace all
OnlineDDL show --skip 5 --limit 10 test_keyspace all
OnlineDDL show test_keyspace running
OnlineDDL show test_keyspace complete
OnlineDDL show test_keyspace failed
```

### Options

```
  -h, --help         help for show
      --json         Output JSON instead of human-readable table.
      --limit uint   Limit number of rows returned in output.
      --order id     Sort the results by id property of the Schema migration. (default "asc")
      --skip uint    Skip specified number of rows returned in output.
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient OnlineDDL](../)	 - Operates on online DDL (schema migrations).

