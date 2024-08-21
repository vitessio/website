---
author: 'Andrés Taylor'
date: 2024-08-20
slug: '2024-08-20-recursive-cte'
tags: ['Vitess', 'PlanetScale', 'MySQL', "Compability", "CTE"]
title: 'Vitess Now Supports Recursive CTEs: A Step Closer to Full MySQL Compatibility'
description: "Vitess introduces support for recursive CTEs, enabling powerful query capabilities across sharded keyspaces, as we continue our progress toward full MySQL feature compatibility"
---

We are excited to announce that Vitess now supports recursive [Common Table Expressions (CTEs)](https://dev.mysql.com/doc/refman/8.4/en/with.html), marking another significant step in our journey to fully align with MySQL’s capabilities. Recursive CTEs, often a critical feature for complex query handling, allow for the execution of recursive queries within a single CTE. This addition brings more flexibility and power to developers using Vitess, especially those working with distributed databases.

One of the key challenges in implementing recursive CTEs within a sharded environment is managing the distribution of data across multiple shards. Vitess has addressed this challenge with two distinct approaches. First, when possible, we merge recursive CTEs into a single query that can be efficiently executed on a single shard. This optimization makes it possible to run recursive queries on a single shard, for queries where this is possible.

In scenarios where merging is not feasible, Vitess takes advantage of its powerful `vtgate` proxy. The `vtgate` handles recursion, allowing recursive CTEs to function seamlessly across sharded keyspaces. This ensures that recursive queries are no longer a barrier when working with large, distributed datasets.

It’s important to note that support for recursive CTEs is still in the experimental stage and has just been merged into the main branch. This feature is not yet available in any official release but will be part of the upcoming Vitess 21 release. We encourage the community to explore this feature and provide feedback on any issues encountered. Your input is invaluable as we continue to refine and enhance Vitess.

This development brings us even closer to our goal of fully supporting MySQL’s feature set. With recursive CTEs now implemented, Vitess is on the verge of achieving complete MySQL compatibility. We remain dedicated to expanding Vitess’s capabilities, and this advancement marks another significant milestone in that ongoing journey.

We look forward to your feedback and hope you enjoy the expanded capabilities that recursive CTEs bring to Vitess.
