---
title: "What is a shard?"
shorten_nav_links: true
notoc: true
weight: 8
---

A shard is a physical division within a keyspace;  i.e. how data is split across multiple MySQL instances. A shard typically consists of one MySQL primary and one or more MySQL replicas.

Each MySQL instance within a shard has the same data, if the effect of MySQL replication lag is ignored. The replicas can serve read-only traffic, execute long-running queries from data analysis tools, or perform administrative tasks.

An unsharded keyspace always has only a single shard.
