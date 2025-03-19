---
title: "How do reparents work in Vitess?"
shorten_nav_links: true
notoc: true
weight: 7
---

Reparenting is the process of changing a shard’s primary tablet from one host to another or changing a replica tablet to have a different primary. Reparenting can be initiated manually or it can occur automatically in response to particular database conditions. Vitess supports two types of reparenting: [Active reparenting](https://vitess.io/docs/user-guides/configuration-advanced/reparenting/#active-reparenting) and [External reparenting](https://vitess.io/docs/user-guides/configuration-advanced/reparenting/#external-reparenting).
- Active reparenting occurs when Vitess manages the entire reparenting process. There are two types of active reparenting that can be done: [Planned reparenting](https://vitess.io/docs/user-guides/configuration-advanced/reparenting/#plannedreparentshard-planned-reparenting) and [Emergency reparenting](https://vitess.io/docs/user-guides/configuration-advanced/reparenting/#emergencyreparentshard-emergency-reparenting).
- External reparenting occurs when another tool handles the reparenting process, and Vitess just updates its components to accurately reflect the new primary-replica relationships.

You can read more about reparenting in Vitess [here](https://vitess.io/docs/user-guides/configuration-advanced/reparenting/).
