---
title: MoveTables show
series: vtctldclient
---
## vtctldclient MoveTables show

Show the details for a MoveTables VReplication workflow.

```
vtctldclient MoveTables show
```

### Examples

```
vtctldclient --server localhost:15999 movetables --workflow commerce2customer --target-keyspace customer show
```

### Options

```
  -h, --help   help for show
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
      --target-keyspace string    Keyspace where the tables are being moved to and where the workflow exists (required)
```

### SEE ALSO

* [vtctldclient MoveTables](../)	 - Perform commands related to moving tables from a source keyspace to a target keyspace.

