---
title: VReplication
description: Frequently Asked Questions about Vitess
weight: 7
---

## What is semi-sync replication?

Semi-sync replication enables you to prevent your primary from finishing replication until a replica confirms that it has received all the changes. Thus adding an extra guarantee that at least one other machine has copies of the data.

This addresses the problem of a combination of lagging replication and network issues resulting in data loss. With semi-sync replication, even if you have network issues you shouldn’t lose your data.

Please do note that when using semi-sync replication you will have to wait for your data to flow from the primary to the replica and then get a confirmation back to the primary. Thus each transaction may take longer. The length of time depends on how close network wise the replica is to the primary.

## What is the typical replication lag in VReplication?


VReplication is very fast, typically replication lag is below a second as long as your network is good. 

However, if there is a network partition, things can be delayed depending on your configuration. For anything transactional, we recommend always reading from the source table. This principle follows the same rule as recommending reading from primary instead of a replica.

## Why would I use semi-sync replication?

Semi-sync replication ensures higher levels of durability between the primary and at least one replica. You can read more about semi-sync replication here.
