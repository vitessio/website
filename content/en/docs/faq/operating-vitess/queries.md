---
title: Queries
description: Frequently Asked Questions about Vitess
weight: 3
---

## How can I perform a full table scan without the row limit per query?

Vitess supports different modes. In OLTP mode, the result size is typically limited to a preset number (10,000 rows by default). This limit can be adjusted based on your needs.

However, OLAP mode has no limit to the number of rows returned. In order to change to this mode, you may issue the following command before executing your query:

```sql
set workload='olap'
```

You can also set the workload to `dba mode`, which allows you to override the implicit timeouts that exist in vttablet. However, this mode should be used judiciously as it supersedes shutdown and reparent commands.

The general convention is to send OLTP queries to `REPLICA` tablet types, and OLAP queries to `RDONLY`.

## Can I choose between primary and replica for query routing?

You can qualify the keyspace name with the desired tablet type using the @ suffix. This can be specified as part of the connection as the database name, or can be changed on the fly through the USE command.

For example, `ks@primary` will select `ks` as the default keyspace with all queries being sent to the primary. Consequently `ks@replica` will load balance requests across all `REPLICA` tablet types, and `ks@rdonly` will choose `RDONLY`.

You can also specify the database name as `@primary`, etc, which instructs Vitess that no default keyspace was specified, but that the requests are for the specified tablet type.

If no tablet type was specified, then VTGate chooses its default, which can be overridden with the `-default_tablet_type` command line argument.

## Can I address a specific shard if I want to?

If necessary, you can access a specific shard by connecting to it using the shard-specific database name, or issuing a USE statement to switch to it if already connected to vtgate. 

For a keyspace ks and shard -80, you would use the database name ks:-80. This is called manual shard targeting.

## Can I set a session variable query timeout?

If you would like something similar to `[max_execution_time]`(https://dev.mysql.com/blog-archive/server-side-select-statement-timeouts/) you can set the vttablet command line flag as follows: `-queryserver-config-query-timeout=15`. This is set in seconds.

You can also specify a query comment like `select /*vt+ QUERY_TIMEOUT_MS=1000 */ `... 

If you choose to set the vttablet command line flag the time you choose will set the absolute max time. The query comment can only override the timeout to a lower value. 

This timeout via SQL query comments has the following limitations/caveats:

- You need to prevent your SQL client from stripping the comments before sending to the server (the MySQL CLI strips comments by default)
- You need to disable query normalization in vtgate (-normalize_queries false);  to allow the comment to reach vttablet.
- It only works for SELECT statements today, this might change in the future.

{{< info >}}
Note that streaming queries are not affected by either of these timeouts.
{{< /info >}}

## Can I increase the resource pool timeout for streaming requests?

Yes. You can adjust the flag `-queryserver-config-stream-pool-size=100`.