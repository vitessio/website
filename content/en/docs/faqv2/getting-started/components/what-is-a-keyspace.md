---
title: "What is a keyspace?"
shorten_nav_links: true
notoc: true
weight: 4
---

A keyspace is a logical database. Typically, a keyspace maps to multiple MySQL instances regardless of sharding. This is because it is recommended to run multiple replicas even for an unsharded keyspace. In other words, a keyspace appears as a single database from the application's viewpoint.

Reading data from a keyspace is just like reading from a MySQL database.
