---
title: Execution Plans
---

Vitess parses queries at both the VTGate and VTTablet layer in order to evaluate the best method to execute a query. This evaluation is known as query planning, and results in a _query execution plan_.

The Execution Plan is dependent on both the query and the associated [VSchema](../vschema). One of the underlying goals of Vitess' planning strategy is to push down as much work as possible to the underlying MySQL instances. When this is not possible, Vitess will use a plan that collects input from multiple sources and merges the results to produce the correct query result.

### Evaluation Model

An execution plan consists of operators, each of which implements a specific piece of work. The operators combine into a tree-like structure, which represents the overall execution plan. The plan represents each operator as a node in the tree. Each operator takes as input zero or more rows, and produces as output zero or more rows. This means that the output from one operator becomes the input for the next operator. Operators that join two branches in the tree combine input from two incoming streams and produce a single output.

Evaluation of the execution plan begins at the leaf nodes of the tree. Leaf nodes pull in data from VTTablet, the Topology Service, and in some cases are also able to evaluate expression values locally. Each leaf node will not have input from other operators, and pipe in any nodes they produce into their parent nodes. The parents nodes will then pipe in nodes to their parent nodes, all the way up to a root node. The root node produces the final results of the query and delivers the results to the user.

### Routing Operators

A routing operator in an execution plan instructs Vitess which destination to send a piece of work to. Typically a routing operator will tell Vitess which keyspace to use when executing the piece of work, whether or not the keyspace is sharded, and, in the case of sharded keyspaces, which vindex to use.

### Scatter Queries

A routing operator which specifies a sharded keyspace, but which does not specify a vindex, will "scatter" to all shards in a sharded keyspace. A "scatter" query contains one or more pieces of work routed to a sharded keyspace, but which cannot be routed using a vindex.

Note that not all queries which are sent to multiple (or all) shards in a sharded keyspace are considered scatter queries.

### Observing Execution Plans

Cached execution plans can be observed at the VTGate level by browsing the `/queryz` end point.

Starting with Vitess 16, individual statement plans can also be observed with [`VExplain`](../../user-guides/sql/explain-format-vtexplain).

**Related Vitess Documentation**

* [VTGate](../vtgate)
