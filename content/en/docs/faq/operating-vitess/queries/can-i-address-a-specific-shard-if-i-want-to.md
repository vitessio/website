---
title: "Can I address a specific shard if I want to?"
shorten_nav_links: true
notoc: true
weight: 3
---

If necessary, you can access a specific shard by connecting to it using the shard-specific database name, or issuing a `USE` statement to switch to it if already connected to vtgate. 

For a keyspace `ks` and shard `-80`, you would use the database name `ks:-80`. This is called manual shard targeting. Please note that shard targeting is considered an advanced feature and should be used with caution.
In particular, it is possible to insert rows into the wrong shard by using shard targeting.
