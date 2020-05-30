---
title: VTExplain command line tool 
---

# Overview

This document provides information about the options and syntax of the `VTExplain` tool.

To learn more about the way Vitess executes a particular SQL statement using the `VTexplain` tool, see the doument [Explaining how Vitess executes a SQL statement](../../user-guides/vtexplain).

## About VTExplain

The `VTExplain` tool provides information about how Vitess will execute a particular SQL statement. `VTExplain` is analagous to the MySQL [`EXPLAIN`](https://dev.mysql.com/doc/refman/8.0/en/explain.html) tool.

## Syntax

```
> vtexplain {-vschema|vschema-file} {-schema|-schema-file} -sql
```

## Options

The `vtexplain` command takes the following options:

-dbname string
: Optional database target to override normal routing (default "")
 
-output-mode string
: Output in human-friendly text or json (default "text")

-normalize
: Whether to enable vtgate normalization (default false)

-shards int
: Number of shards to simulate per keyspace (default 2).`vtexplain` will always allocate an evenly divided key range to each.

-replication-mode string
: The replication mode to simulate: either ROW or STATEMENT (default "ROW"). 

-schema string
: The SQL table schema (default ""). Either `schema` or `schema-file` is required.

-schema-file string
: Identifies the file that contains the SQL table schema (default ""). Either `schema` or `schema-file` is required.

-sql string
: A list of semicolon-delimited SQL commands to analyze (default ""). Required.

-sql-file string
: Identifies the file that contains the SQL commands to analyze (default "")

-vschema string
: Identifies the VTGate routing schema (default ""). Either `-vschema` or `-vschema-file` is required.

-vschema-file string
: Identifies the VTGate routing schema file (default "")

-queryserver-config-passthrough-dmls
: query server pass through all dml statements without rewriting (default false)

To view a list of these options, execute the following command:

```
vtexplain --help
```

## Examples

```
vtexplain -vschema-file vschema.json -schema-file schema.sql  -sql "SELECT * FROM users"
```

The example above explains how Vitess would execute the query `SELECT * FROM users` using the VSchema contained in `vschema.json` and the database schema contained in `schema.sql`.

```
vtexplain -shards 128 -vschema-file /tmp/vschema.json -schema-file /tmp/schema.sql -replication-mode "ROW" -output-mode text -sql "INSERT INTO users (user_id, name) VALUES(1, 'john')"
```

The example above explains how Vitess would execute the query `INSERT INTO users (user_id, name) VALUES(1, 'john')`, simulating 128 shards and row-based replication, and specifying text-based output.

## Limitations

### The VSchema must use a keyspace name.

VTExplain requires a keyspace name for each keyspace in an input VSChema:

```
"keyspace_name": {
    "_comment": "Keyspace definition goes here."
}
```

If no keyspace name is present, VTExplain will return the following error:

```
ERROR: initVtgateExecutor: json: cannot unmarshal bool into Go value of type map[string]json.RawMessage
```

## See also

+  [Explaining how Vitess executes a SQL statement](../../user-guides/vtexplain)    

