---
title: "When do I need to use a VSchema?"
shorten_nav_links: true
notoc: true
weight: 5
---

For a very trivial setup where there is only one unsharded keyspace, there is no need to specify a VSchema because Vitess will know that there is nowhere to route a query except to the single shard.

However, once you have sharding, having a VSchema becomes a necessity. This is because a VSchema is needed to locate and place rows in each table in a sharded keyspace.

The Vitess distribution has a demo of VSchema operation [here](https://github.com/vitessio/vitess/tree/master/examples/demo).
