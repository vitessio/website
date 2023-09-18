---
title: MoveTables start
series: vtctldclient
---
## vtctldclient MoveTables start

Start a MoveTables workflow.

```
vtctldclient MoveTables start
```

### Examples

```
vtctldclient --server localhost:15999 MoveTables --workflow commerce2customer --target-keyspace customer start
```

### Options

```
  -h, --help   help for start
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient MoveTables](../)	 - Perform commands related to moving tables from a source keyspace to a target keyspace.

