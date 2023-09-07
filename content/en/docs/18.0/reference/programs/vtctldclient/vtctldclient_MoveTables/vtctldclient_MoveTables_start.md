---
title: MoveTables Start
series: vtctldclient
---
## vtctldclient MoveTables Start

Start a moveTables workflow.

```
vtctldclient MoveTables Start
```

### Examples

```
vtctldclient --server localhost:15999 moveTables --workflow cust2cust --target-keyspace customer start
```

### Options

```
  -h, --help   help for Start
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient MoveTables](../)	 - Perform commands related to moving tables from a source keyspace to a target keyspace.

