---
title: VReplication
weight: 7
---


## What is the typical replication lag in VReplication?

VReplication is very fast, typically replication lag is below a second as long as your network is good. 

However, if there is a network partition, things can be delayed depending on your configuration. For anything transactional, we recommend always reading from the source table. This principle follows the same rule as recommending reading from primary instead of a replica.

