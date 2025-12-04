---
title: Reshard status
series: vtctldclient
---
## vtctldclient Reshard status

Show the current status for a Reshard VReplication workflow.

```
vtctldclient Reshard status
```

### Examples

```
vtctldclient --server localhost:15999 Reshard --workflow cust2cust --target-keyspace customer status
```

#### Text Output

```
The following vreplication streams exist for workflow customer.cust2cust:

id=1 on customer/-80: Status: Copying. VStream Lag: 0s; ; Tx time: Thu Oct 30 14:22:45 2025..

Table Copy Status:
	customer: RowsCopied:1500, RowsTotal:5000, RowsPercentage:30.00, BytesCopied:150000, BytesTotal:500000, BytesPercentage:30.00, Phase:IN_PROGRESS
	orders: RowsCopied:0, RowsTotal:0, RowsPercentage:100.00, BytesCopied:16384, BytesTotal:16384, BytesPercentage:100.00, Phase:COMPLETE

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
vtctldclient --server localhost:15999 Reshard --workflow cust2cust --target-keyspace customer status --format=json
```

```json
{
  "table_copy_state": {
    "customer": {
      "rows_copied": "1500",
      "rows_total": "5000",
      "rows_percentage": 30,
      "bytes_copied": "150000",
      "bytes_total": "500000",
      "bytes_percentage": 30,
      "phase": "IN_PROGRESS"
    },
    "orders": {
      "rows_copied": "0",
      "rows_total": "0",
      "rows_percentage": 100,
      "bytes_copied": "16384",
      "bytes_total": "16384",
      "bytes_percentage": 100,
      "phase": "COMPLETE"
    }
  },
  "shard_streams": {
    "customer/-80": {
      "streams": [
        {
          "id": 1,
          "tablet": {
            "cell": "zone1",
            "uid": 200
          },
          "source_shard": "customer/0",
          "position": "a1234567-b58f-11f0-9085-360472309971:1-15432",
          "status": "Copying",
          "info": "VStream Lag: 0s; ; Tx time: Thu Oct 30 14:22:45 2025."
        }
      ]
    }
  },
  "traffic_state": "Reads Not Switched. Writes Not Switched"
}
```

### Options

```
  -h, --help   help for status
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

* [vtctldclient Reshard](../)	 - Perform commands related to resharding a keyspace.

