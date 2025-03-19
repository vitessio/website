---
title: "Can I use Vitess to do cross-shard JOINs or Transactions?"
shorten_nav_links: true
notoc: true
weight: 2
---

A horizontal sharding solution for MySQL like Vitess does allow you to do both cross-shard joins and transactions, but just because you can doesn’t mean you should. 

A sharded architecture will perform best if you design it well and play to its strength, e.g. favoring single-shard targeted writes within any individual transaction. Enabling two-phase commit in Vitess to support cross-shard writes is possible, but will come at a significant performance cost. 

Whether that tradeoff is worth it differs from application to application and, generally speaking, adjusting the schema/workload is considered the better approach.
