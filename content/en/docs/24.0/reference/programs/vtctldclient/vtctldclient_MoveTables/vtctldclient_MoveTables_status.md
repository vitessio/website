---
title: MoveTables status
series: vtctldclient
---
## vtctldclient MoveTables status

Show the current status for a MoveTables VReplication workflow.

```
vtctldclient MoveTables status
```

### Examples

```
vtctldclient --server localhost:15999 MoveTables --workflow commerce2customer --target-keyspace customer status
```

#### Text Output

```
The following vreplication streams exist for workflow customer.commerce2customer:

id=1 on customer/zone1-200: Status: Copying. VStream Lag: -1s; ; Tx time: Thu Oct 30 13:04:18 2025..

Table Copy Status:
	corder: RowsCopied:0, RowsTotal:0, RowsPercentage:100.00, BytesCopied:16384, BytesTotal:16384, BytesPercentage:100.00, Phase:COMPLETE
	customer: RowsCopied:0, RowsTotal:47609, RowsPercentage:0.00, BytesCopied:16384, BytesTotal:4734976, BytesPercentage:0.35, Phase:NOT_STARTED

Traffic State: Reads Not Switched. Writes Not Switched
```

The Table Copy Status section shows detailed progress for all tables in the workflow:
- **Phase**: Current copy phase - `COMPLETE`, `IN_PROGRESS`, or `NOT_STARTED`
- **RowsCopied/RowsTotal**: Number of rows copied and total rows to copy
- **RowsPercentage**: Percentage of rows copied
- **BytesCopied/BytesTotal**: Number of bytes copied and total bytes to copy
- **BytesPercentage**: Percentage of bytes copied

#### JSON Output

```
vtctldclient --server localhost:15999 MoveTables --workflow commerce2customer --target-keyspace customer status --format=json
```

```json
{
  "table_copy_state": {
    "corder": {
      "rows_copied": "11",
      "rows_total": "11",
      "rows_percentage": 100,
      "bytes_copied": "16384",
      "bytes_total": "16384",
      "bytes_percentage": 100,
      "phase": "COMPLETE"
    },
    "customer": {
      "rows_copied": "0",
      "rows_total": "47609",
      "rows_percentage": 0,
      "bytes_copied": "16384",
      "bytes_total": "4734976",
      "bytes_percentage": 0.34602076,
      "phase": "NOT_STARTED"
    }
  },
  "shard_streams": {
    "customer/0": {
      "streams": [
        {
          "id": 1,
          "tablet": {
            "cell": "zone1",
            "uid": 200
          },
          "source_shard": "commerce/0",
          "position": "f3918180-b58f-11f0-9085-360472309971:1-29655",
          "status": "Copying",
          "info": "VStream Lag: -1s; ; Tx time: Thu Oct 30 13:04:18 2025."
        }
      ]
    }
  },
  "traffic_state": "Reads Not Switched. Writes Not Switched"
}
```

### Options

```
  -h, --help             help for status
      --shards strings   (Optional) Specifies a comma-separated list of shards to operate on.
```

### Options inherited from parent commands

```
      --action-timeout duration              timeout to use for the command (default 1h0m0s)
      --compact                              use compact format for otherwise verbose outputs
      --format string                        The format of the output; supported formats are: text,json. (default "text")
      --server string                        server to use for the connection (required)
      --target-keyspace string               Target keyspace for this workflow.
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
  -w, --workflow string                      The workflow you want to perform the command on.
```

### SEE ALSO

* [vtctldclient MoveTables](../)	 - Perform commands related to moving tables from a source keyspace to a target keyspace.

