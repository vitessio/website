---
title: "What is VTCtld?"
shorten_nav_links: true
notoc: true
weight: 3
---

VTCtld is a Vitess server component that can perform various Vitess cluster- and component-level operations on behalf of an administrative user. You can interact with VTCtld via a web UI, or via an gRPC interface using the vtctldclient CLI tool.
It has an administrative UI called VTAdmin.

Some of the administrative actions VTCtld can perform include: reparents (failovers), backups, shard splits, resharding, and shard merges.
