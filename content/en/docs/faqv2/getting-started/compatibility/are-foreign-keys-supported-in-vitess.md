---
title: "Are foreign keys supported in Vitess?"
shorten_nav_links: true
notoc: true
weight: 6
---

We generally discourage the use of foreign keys, and more specifically foreign key constraints. There may be unexpected consequences when using them in sharded keyspaces.
However, you can use foreign key constraints when their scope is contained within a shard or unsharded keyspace. You will need to [configure](https://vitess.io/docs/user-guides/vschema-guide/foreign-keys/) Vitess with the desired level of support.
Please note that if you do shard or re-shard an existing keyspqce with foreign keys, you will need to take extra steps to confirm they are working as intended.
