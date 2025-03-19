---
title: "Can data replication from a primary region cell be controlled?"
shorten_nav_links: true
notoc: true
weight: 4
---

If you want to replicate data from a primary region cell to secondary region cell you would need to use [VReplication](https://vitess.io/docs/reference/vreplication/vreplication/).

Please note that Vitess has some regulatory requirements that certain data can't leave the primary region.
