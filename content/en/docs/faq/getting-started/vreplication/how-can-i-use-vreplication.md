---
title: "How can I use VReplication?"
shorten_nav_links: true
notoc: true
weight: 2
---

There are a number of higher level commands like MoveTables, Reshard, and Materialize that create VReplication streams behind the scenes of the command. By using these higher level commands, Vitess creates VReplication rules for the user. Further use cases are listed out [here](https://vitess.io/docs/reference/features/vreplication/).

For more information on [MoveTables](https://vitess.io/docs/user-guides/migration/move-tables/) and [Materialized Views](https://vitess.io/docs/user-guides/migration/materialize/) please follow the links provided.

It is possible to create VReplication rules by hand, but we don’t recommend doing that as it can be challenging to configure the rules correctly.
