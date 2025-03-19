---
title: "Must the application know about the sharding scheme in Vitess?"
shorten_nav_links: true
notoc: true
weight: 2
---

The application does not need to know about how the data is sharded. This information is stored in a VSchema which the VTGate servers use to automatically route your queries. This allows the application to connect to Vitess and use it as if it’s a single giant database server.
