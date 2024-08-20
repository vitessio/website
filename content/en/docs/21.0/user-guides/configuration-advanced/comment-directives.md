---
title: Comment Directives
weight: 35
---

Vitess supports a small set of meta-directives that can be passed from the application to Vitess as SQL comments in the application. These directives can be used to alter the behavior of Vitess on a per-query basis. This is often used by advanced Vitess users to obtain finely granular control over the behavior of Vitess, often for the purposes of optimizing performance.

All the comment directives, included as part of the query, take the form:

```sh
/*vt+ comment_directive_name_plus_argument */
```

One thing to note when experimenting with query comments is that various MySQL clients can strip comments by default before sending the query to the server. You will need to make sure your query comments are not being stripped. For example, the MySQL CLI (`mysql`) will do this unless you pass it the -c (or --comments) parameter.

## Query timeouts (`QUERY_TIMEOUT_MS`)

In Vitess, individual non-streaming queries are subject to query timeouts. This are typically set by the vttablet option `--queryserver-config-query-timeout`. Whole transactions are also subject to the vttablet timeout setting `--queryserver-config-transaction-timeout`.

However, for read (`SELECT`) queries, it is also possible to use a special Vitess query comment format to set a lower timeout for certain queries, e.g.:

```sh
mysql> select /*vt+ QUERY_TIMEOUT_MS=1 */ sleep(1);
ERROR 1317 (70100): target: keyspace1.0.primary: vttablet: rpc error: code = DeadlineExceeded desc = context deadline exceeded
```

As indicated by the comment name (QUERY_TIMEOUT_MS), this timeout is in milliseconds.

### Limitation and Caveats:

- Only works for `SELECT` (read) queries.
- Does not work when doing manual shard-targeting. See [this issue](https://github.com/vitessio/vitess/issues/7031).
- Cannot set a higher limit to evade the settings for `--queryserver-config-query-timeout` and/or `--queryserver-config-transaction-timeout`.

## Multi-shard Autocommit (`MULTI_SHARD_AUTOCOMMIT`)

Using this in, for example, an insert statement will cause individual shard autocommit to be used for the shards where the rows for the insert are routed. This means that if one of the individual shard inserts fails, it will not be possible to roll back the inserts on all the other shards. This is the default behavior. A helpful way to think of this is as best-effort cross-shard writes, with the application being responsible for repairs in the case of errors. For an example, read our [Shard Isolation and Atomicity guide](../../configuration-advanced/shard-isolation-atomicity/#method-1--the-naive-way).

## Skip Query Plan Cache (`SKIP_QUERY_PLAN_CACHE`)

Vitess maintains a query/plan cache in both `vtgate` and `vttablet`. These caches serve different purposes:

- `vtgate`: overall targeting of queries against backend shard tablets
- `vttablet`: shard-specific details like field definitions/types, etc.

The `SKIP_QUERY_PLAN_CACHE` comment directive tells `vttablet` to skip caching this query in its query cache. This can be used by a Vitess-aware application to avoid polluting the cache with things like bulk insert plans, etc.

Since vttablet places a memory size limit on the query cache, it is much less likely for this cache to get overrun by queries like bulk inserts. As a result, it should be less necessary to use this comment directive, other than as a performance optimization.  Previously, it was unbounded in memory, or in other words it was only bounded by number of entries. At that point it might have been necessary to use to avoid vttablet out-of-memory (OOM) situations.

## Scatter Errors as Warnings (`SCATTER_ERRORS_AS_WARNINGS`)

Vitess will, by default, return only an error if any of the shards involved in a scatter query reports an error. This is important for strong correctness, however, in some cases it may be necessary or desirable to have Vitess return partial results from the available shards anyway. The application can then act accordingly based on the results.

The `SCATTER_ERRORS_AS_WARNINGS` comment directive enables exactly this, by returning the partial results from the healthy shards in the scatter query, and returning the error(s) from the unhealthy shard(s) as warnings. The application can then potentially use the warning information to guide its subsequent action.

## Ignore Max Payload Size (`IGNORE_MAX_PAYLOAD_SIZE`)

By default, Vitess will try to handle queries of any size. It is possible to use the `vtgate` parameter `--max_payload_size` (default unlimited) to limit the size of an incoming query to a certain number of bytes. Queries larger than this limit will then be rejected by `vtgate`.

The `IGNORE_MAX_PAYLOAD_SIZE` comment directive allows a Vitess-aware application to bypass this limit, essentially setting it to the default of unlimited for that query.

## Ignore Max Memory Rows (`IGNORE_MAX_MEMORY_ROWS`)

By default, `vtgate` will allow intermediate results for things like in-vtgate sorting and joining, up to a maximum of number of rows per query. This is to avoid using massive amounts of memory in `vtgate`. This limit is set using the `vtgate` parameter `--max_memory_rows`, which defaults to 300,000. Note that this limit is not a direct memory usage limit, since 300,000 very large rows could still be a huge amount of memory.

The `IGNORE_MAX_MEMORY_ROWS` comment directive allows a Vitess-aware application to bypass this limit, essentially setting it to an unlimited number of rows for that query. Since this override can result in very large, and even potentially effectively unbounded, amounts of memory being used by `vtgate`, it should be used with extreme caution.

## Allow Scatter (`ALLOW_SCATTER`)

In Vitess, it is possible to use the `vtgate` parameter `--no_scatter` to prevent `vtgate` from issuing scatter queries. Thus only queries that do not scatter will be allowed.

This comment directive is used to override that limitation, allowing application code to be customized to allow scatters for certain chosen use-cases, but not for the general case.

## Consolidator (`CONSOLIDATOR`)

In `vttablet`, the consolidator is enabled with the `--enable_consolidator` and `--enable_consolidator_replicas` flags. Those settings may be overridden with this comment directive, allowing application code to opt into (or out of) consolidation for individual `SELECT` queries.

This directive requires one of the following values:

 * `disabled`
 * `enabled`
 * `enabled_replicas`

### Planner (`PLANNER`)

Overrides the default planner to the one specified by the directive. Example query:

```sql
select /*vt+ PLANNER=gen4 */ * from user;
```

Valid values are the same as for the planner flag - `Gen4`, `Gen4Greedy` and `Gen4Left2Right`.

### Workload Name (`WORKLOAD_NAME`)

Specifies the client application workload name. This does not affect query execution, but can be used to instrument
some `vttablet` metrics to include a label specifying the workload name. It can be useful if you are interested in
getting insights about how much of the work being done at the `vttablet` level is being caused by each client
application workload. For this to work, you must use  `--enable-per-workload-table-metrics` at the `vttablet`, and pass
the client workload name on each query as a directive. For example:

```sql
select /*vt+ WORKLOAD_NAME=webstore */ * from commerce.customer;
```

will result in metrics such as this one:

```bash
% curl -s localhost:15100/metrics  | grep "table=\"customer\"" |grep webstore
vttablet_query_counts{plan="Select",table="customer",workload="webstore"} 1
vttablet_query_error_counts{plan="Select",table="customer",workload="webstore"} 0
vttablet_query_rows_returned{plan="Select",table="customer",workload="webstore"} 0
vttablet_query_times_ns{plan="Select",table="customer",workload="webstore"} 602557
```

As shown above, the metrics being instrumented this way are `vttablet_query_counts`, `vttablet_query_error_counts`,
`vttablet_query_rows_returned` and `vttablet_query_times_ns`.

If the query lacks the `WORKLOAD_NAME` directive, the corresponding label in the metric will have the value of an empty
string. If `vttablet` is not started with `--enable-per-workload-table-metrics`, metrics are emitted without the
workload label (e.g. `vttablet_query_counts{plan="Select",table="customer"}`.
