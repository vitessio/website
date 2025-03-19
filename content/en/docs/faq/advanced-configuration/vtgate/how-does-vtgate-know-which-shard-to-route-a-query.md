---
title: "How does VTGate know which shard to route a query to?"
shorten_nav_links: true
notoc: true
weight: 1
---

VTGate knows both the Vschema and the schema of your tables in the backing MySQL databases.

This enables VTGate to look at the WHERE clause of the query and then route the queries to the correct shards. VTGate is also aware of the sharding metadata, cluster state, and availability of tables, so it will only scatter the query across the shards it needs to use.
