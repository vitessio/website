---
title: "What is semi-sync replication?"
shorten_nav_links: true
notoc: true
weight: 6
---

Semi-sync replication enables you to prevent your primary from acknowledging a transaction to the client until a replica confirms that it has received all the changes. This adds an extra guarantee that at least one other machine has a copy of the changes.

This addresses the problem of a combination of lagging replication and network issues resulting in data loss. With semi-sync replication, even if you have network issues you shouldn’t lose your data.

Please do note that when using semi-sync replication you will have to wait for your data to flow from the primary to the replica and then get a confirmation back to the primary. Thus each transaction may take longer. The length of time depends on the round trip time from the primary to the replica.
