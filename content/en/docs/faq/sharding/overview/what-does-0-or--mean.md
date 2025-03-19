---
title: "What does “/0” or “/-”mean?"
shorten_nav_links: true
notoc: true
weight: 4
---

`0` or `-` indicates that the keyspace in question is unsharded. This means that a single shard covers the entire keyrange. Note that while both `0` and `-` are supported for legacy reasons, you can’t merge into shard `0` only `-`. For this and other reasons, it is recommended to use `-` instead of `0`.

On the other hand a sharded cluster will have multiple keyranges, for example `-80` and `80-` if you have two shards. Note, that you can still manually target a single shard from your sharded cluster. You can read more about that [here](https://vitess.io/docs/faq/operating-vitess/queries/#can-i-address-a-specific-shard-if-i-want-to).
