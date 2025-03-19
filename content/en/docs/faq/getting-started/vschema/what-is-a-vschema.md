---
title: "What is a VSchema?"
shorten_nav_links: true
notoc: true
weight: 1
---

VSchema is short for Vitess Schema and it describes how to shard data within Vitess. 

In contrast to a traditional database schema that contains metadata about tables, a VSchema contains metadata about how tables are organized across shards. This information is used for routing queries and also during resharding operations. 

Simply put, it contains the information needed to make Vitess look and act like a single database server.

For example, the VSchema will contain the sharding key for each sharded table. When the application issues a query with a WHERE clause that references the key, the VSchema will be used to route the query to the appropriate shard.
