---
title: How do Vitess replicas stay in sync? Do replicas use VReplication?
shorten_nav_links: true
weight: 4
---

Every shard in Vitess uses normal MySQL replication to replicate changes from the primary for that shard to the replica(s). Vitess can use asynchronous MySQL replication (the default), but can also be configured to use semi-synchronous MySQL replication in order to provide data durability in the presence of failures.

VReplication is used internally in Vitess for features like resharding, migrating tables across keyspaces, and materialized views. It is not used directly to keep replicas in sync with a primary.
