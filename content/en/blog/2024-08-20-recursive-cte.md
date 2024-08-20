---
author: 'Andrés Taylor'
date: 2024-08-20
slug: '2024-08-20-recursive-cte'
tags: ['Vitess', 'PlanetScale', 'MySQL', "Compability", "CTE"]
title: 'Vitess Now Supports Recursive CTEs: A Step Closer to Full MySQL Compatibility'
description: "Vitess introduces support for recursive CTEs, enabling powerful query capabilities across sharded keyspaces, as we continue our progress toward full MySQL feature compatibility"
---

We are excited to announce that Vitess now supports recursive Common Table Expressions (CTEs), marking another significant step in our journey to fully align with MySQL’s capabilities. Recursive CTEs, often a critical feature for complex query handling, allow for the execution of recursive queries within a single CTE. This addition brings more flexibility and power to developers using Vitess, especially those working with distributed databases.

One of the key challenges in implementing recursive CTEs within a sharded environment is managing the distribution of data across multiple shards. Vitess has addressed this challenge with two distinct approaches. First, when possible, we merge recursive CTEs into a single query that can be efficiently executed on a single shard. This optimization minimizes the complexity and overhead associated with sharded queries, ensuring that performance remains robust even with recursive operations.

In scenarios where merging is not feasible, Vitess takes advantage of its powerful `vtgate` proxy. The `vtgate` handles recursion, allowing recursive CTEs to function seamlessly across sharded keyspaces. This ensures that recursive queries are no longer a barrier when working with large, distributed datasets. With this feature, developers can now leverage the full potential of recursive CTEs, regardless of the underlying sharding strategy.

It’s important to note that support for recursive CTEs is still in the experimental stage. We encourage the community to explore this feature and provide feedback on any issues encountered. Your input is invaluable as we continue to refine and enhance Vitess.

This development is part of our broader vision to support more and more of MySQL’s feature set. With recursive CTEs now in place, there are only a few major pieces left before Vitess can fully match MySQL’s capabilities. We are committed to pushing the boundaries of what Vitess can do, and this is just one more step on that journey.

We look forward to your feedback and hope you enjoy the expanded capabilities that recursive CTEs bring to Vitess.
