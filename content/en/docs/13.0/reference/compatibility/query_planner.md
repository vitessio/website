---
title: Query Planners
weight: 2
aliases: ['/docs/reference/query_planner/', '/docs/reference/gen4-and-v3-compatibility/']
---

The query planner is the module that is responsible for taking a query sent to VTGate, split it across shards and combiner the results to make it look like a single database.
Since this is a critical piece of the system, we have made it easy to change which planner is used.

The following planners are available:

 + v3
   - This is the default planner. It is not being worked on anymore - new features are added to gen4. 

 + gen4
   - The new planner added to vitess. 
   It supports more queries, and is able to find plans that are more optimal than the old planner could.
   Read more about it [here](/blog/2021-11-02-why-write-new-planner.md)

 + left2right
   - This planner works similar to the `straight_join` directive in MySQL - the joins are going to be performed in the order specified by the query.
   
 + gen4fallback
   - This planner will first try the gen4 planner, and if it fails, it uses the v3 planner. This was useful during the development of gen4, but probably not very useful in production.

 + gen4comparev3
   - Finally, specifying the planner to `gen4comparev3` will run the query using both planners, and compares the output, failing the query if the results do not agree.

### Specifying the planner to use

You can change which planner is to be used in two ways - you can specify the `-planner_version` flag when starting VTGate, and then you can override this value using a query hint.

Example of using the planner_version flag:

```bash
vtgate -planner_version=gen4 # rest of config follows here
```

Example of using the query hint to specify planner:

```sql
select /*vt+ PLANNER=gen4 */ * from commerce;
```

### Testing the new planner using `gen4comparev3`

The latest version of the Vitess query planner, `Gen4`, changes most of the planner's internals.
To ensure `Gen4` produces plans that, once executed, give us the same results as what `V3` would, we have developed a small test tool that runs queries using both `Gen4` and `V3` planners and compares their results. 
If the results we got are different from the two planners, the query will fail and the difference will be printed in VTGate's logs as a warning.

This tool is enabled by the use of a new planner: `Gen4CompareV3`, to use it, we must start VTGate with the `-planner_version` flag set to `Gen4CompareV3`.
Once set, new queries will be tested against both `Gen4` and `V3`.

The comparer planner runs the same query twice, so it will consume a lot more resources and take longer to run. 
It is only meant to be used for testing before switching query planners.

{{< warning >}}
The gen4 planner is still considered experimental and should only be used after careful testing
{{< /warning >}}
