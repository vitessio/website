---
title: Advanced
description: Frequently Asked Questions about Vitess
weight: 3
---

## How can I know which shard contains a row for a table?

You can use the primary Vindex column to query the Vindex and discover the shard ID. Once you have determined the shard ID you can use [manual shard targeting](http://vitess.io/docs/faq/operating-vitess/queries/?#can-i-address-a-specific-shard-if-i-want-to) to send that specific shard a query.  Note that if the query contains the primary Vindex column, or an appropriate secondary Vindex column, you do not need to do this, and vtgate can route the query automatically.

## Can I use Vitess to do cross-shard JOINs or Transactions?

A horizontal sharding solution for MySQL like Vitess does allow you to do both cross-shard joins and transactions, but just because you can doesn’t mean you should. 

A sharded architecture will perform best if you design it well and play to its strength, e.g. favoring single-shard targeted writes within any individual transaction. Enabling two-phase commit in Vitess to support cross-shard writes is possible, but will come at a significant performance cost. 

Whether that tradeoff is worth it differs from application to application and, generally speaking, adjusting the schema/workload is considered the better approach.