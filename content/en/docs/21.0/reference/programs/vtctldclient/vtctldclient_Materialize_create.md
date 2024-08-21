---
title: Materialize create
series: vtctldclient
commit: 5cb66a1797a17c05b447acda5f923c62e5912b27
---
## vtctldclient Materialize create

Create and run a Materialize VReplication workflow.

### Synopsis

Materialize is a lower level VReplication command that allows for generalized materialization
of tables. The target tables can be copies, aggregations, or views. The target tables are kept
in sync in near-realtime. The primary flag used to define the materializations (you can have
multiple per workflow) is table-settings which is a JSON array where each value must contain
two key/value pairs. The first required key is 'target_table' and it is the name of the table
in the target-keyspace to store the results in. The second required key is 'source_expression'
and its value is the select query to run against the source table. An optional key/value pair
can also be specified for 'create_ddl' which provides the DDL to create the target table if it
does not exist -- you can alternatively specify a value of 'copy' if the target table schema
should be copied as-is from the source keyspace. Here's an example value for table-settings:
[
  {
    "target_table": "customer_one_email",
    "source_expression": "select email from customer where customer_id = 1"
  },
  {
    "target_table": "states",
    "source_expression": "select * from states",
    "create_ddl": "copy"
  },
  {
    "target_table": "sales_by_sku",
    "source_expression": "select sku, count(*) as orders, sum(price) as revenue from corder group by sku",
    "create_ddl": "create table sales_by_sku (sku varbinary(128) not null primary key, orders bigint, revenue bigint)"
  }
]


```
vtctldclient Materialize create
```

### Examples

```
vtctldclient --server localhost:15999 materialize --workflow product_sales --target-keyspace commerce create --source-keyspace commerce --table-settings '[{"target_table": "sales_by_sku", "create_ddl": "create table sales_by_sku (sku varbinary(128) not null primary key, orders bigint, revenue bigint)", "source_expression": "select sku, count(*) as orders, sum(price) as revenue from corder group by sku"}]' --cells zone1 --cells zone2 --tablet-types replica
```

### Options

```
  -c, --cells strings                      Cells and/or CellAliases to copy table data from.
  -h, --help                               help for create
      --mysql_server_version string        Configure the MySQL version to use for example for the parser. (default "8.0.30-Vitess")
      --source-keyspace string             Keyspace where the tables queried in the 'source_expression' values within table-settings live.
      --sql-max-length-errors int          truncate queries in error logs to the given length (default unlimited)
      --sql-max-length-ui int              truncate queries in debug UIs to the given length (default 512) (default 512)
      --stop-after-copy                    Stop the workflow after it's finished copying the existing rows and before it starts replicating changes.
      --table-settings JSON                A JSON array defining what tables to materialize using what select statements. See the --help output for more details. (default null)
      --tablet-types strings               Source tablet types to replicate table data from (e.g. PRIMARY,REPLICA,RDONLY).
      --tablet-types-in-preference-order   When performing source tablet selection, look for candidates in the type order as they are listed in the tablet-types flag. (default true)
```

### Options inherited from parent commands

```
      --action_timeout duration              timeout to use for the command (default 1h0m0s)
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

* [vtctldclient Materialize](./vtctldclient_materialize/)	 - Perform commands related to materializing query results from the source keyspace into tables in the target keyspace.

