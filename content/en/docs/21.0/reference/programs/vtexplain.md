---
title: vtexplain
aliases: ['/docs/reference/vtexplain/']
---

`vtexplain` is a command line tool which provides information on how Vitess plans to execute a particular query. It can
be used to validate queries for compatibility with Vitess.

For a user guide that describes how to use the `vtexplain` tool to explain how Vitess executes a particular SQL
statement, see [Analyzing a SQL statement](../../../user-guides/sql/vtexplain/).

## Example Usage

Explain how Vitess will execute the query `SELECT * FROM users` using the VSchema contained in `vschemas.json` and the
database schema `schema.sql`:

```bash
vtexplain -- --vschema-file vschema.json --schema-file schema.sql --sql "SELECT * FROM users"
```

Explain how the example will execute on 128 shards using Row-based replication:

```bash
vtexplain -- -shards 128 --vschema-file vschema.json --schema-file schema.sql --replication-mode "ROW" --output-mode text --sql "INSERT INTO users (user_id, name) VALUES(1, 'john')"
```

## Options

The following parameters apply to `mysqlctl`:

| Name                   | Type    | Definition                                                                                                                           |
|:-----------------------|:--------|:-------------------------------------------------------------------------------------------------------------------------------------|
| --dbname               | string  | Optional database target to override normal routing                                                                                  |
| --execution-mode       | string  | The execution mode to simulate -- must be set to multi, legacy-autocommit, or twopc (default "multi")                                |
| --ks-shard-map         | string  | JSON map of keyspace name -> shard name -> ShardReference object. The inner map is the same as the output of FindAllShardsInKeyspace |
| --ks-shard-map-file    | string  | File containing json blob of keyspace name -> shard name -> ShardReference object                                                    |
| --mysql_server_version | string  | MySQL server version to advertise. (default "8.0.30-Vitess")                                                                         |
| --normalize            | boolean | Whether to enable vtgate normalization                                                                                               |
| --output-mode          | string  | Output in human-friendly text or json (default "text")                                                                               |
| --planner-version      | string  | Sets the default planner to use. Valid values are: Gen4, Gen4Greedy, Gen4Left2Right                                                  |
| --replication-mode     | string  | The replication mode to simulate -- must be set to either ROW or STATEMENT (default "ROW")                                           |
| --schema               | string  | The SQL table schema                                                                                                                 |
| --schema-file          | string  | Identifies the file that contains the SQL table schema                                                                               |
| --shards               | int     | Number of shards per keyspace. Passing --ks-shard-map/--ks-shard-map-file causes this flag to be ignored. (default 2)                |
| --sql                  | string  | A list of semicolon-delimited SQL commands to analyze                                                                                |
| --sql-file             | string  | Identifies the file that contains the SQL commands to analyze                                                                        |
| --vschema              | string  | Identifies the VTGate routing schema                                                                                                 |
| --vschema-file         | string  | Identifies the VTGate routing schema file                                                                                            |

<br>

Please note that `-ks-shard-map` and `ks-shard-map-file` will supercede `--shards`.
If you attempt to `vtexplain` on a keyspace that is included in the keyspace shard map, the shards as defined in the
mapping will be used and `--shards` will be ignored.

## Limitations

### The VSchema must Use a Keyspace Name

VTExplain requires a keyspace name for each keyspace in an input VSchema:

```
"keyspace_name": {
    "_comment": "Keyspace definition goes here."
}
```

If no keyspace name is present, VTExplain will return the following error:

```
ERROR: initVtgateExecutor: json: cannot unmarshal bool into Go value of type map[string]json.RawMessage
```  
