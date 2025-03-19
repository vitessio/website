---
title: "What is a cell? How does it work?"
shorten_nav_links: true
notoc: true
weight: 6
---

A cell is a group of servers and associated network infrastructure co-located in an area, and isolated from failures in other cells. It is typically either a full data center or a subset of a data center, sometimes called a zone or availability zone. Vitess gracefully handles cell-level failures, such as when a cell is isolated from other cells by a network failure. A useful way to think of a cell is as a failure domain.

Each cell in a Vitess implementation has a local Topology Service, which is hosted in that cell. The Topology Service contains most of the information about the Vitess tablets in its cell. This enables a cell to be taken down and rebuilt as a unit.

Vitess limits cross-cell traffic for both data and metadata. Vitess currently serves reads only from the local cell. Writes will go cross-cell as necessary, to wherever the primary for that shard resides.
