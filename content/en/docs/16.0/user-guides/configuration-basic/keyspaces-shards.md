---
title: Keyspaces and Shards
weight: 7
---

You can create keyspaces and shards using [vtctldclient](../../../reference/programs/vtctldclient) commands. However, they are not necessary because these are implicitly created as you bring up the vttablets.

The canonical information for keyspaces and shards is initially created in the global topo. This information is then deployed to the cell-specific topos through rebuild commands like `RebuildKeyspaceGraph` and `RebuildVSchemaGraph`. These commands are implicitly issued on your behalf whenever applicable. But there are situations where you will have to issue them manually. For example, if you create a new cell, you will have to issue these commands to copy the data into the new cell.

There are use cases where you may want to experimentally deploy changes to only some cells. Separating information from the global topo and local cells makes those experiments possible without affecting the entire deployment.

Tools like [vtgate](../../../reference/programs/vtgate) and [vttablet](../../../reference/programs/vttablet) consume information from the local copy of the topo.

An unsharded keyspace typically has a single shard named `0` or` -`. A sharded keyspace has shards named after the keyranges assigned to it, like `-80` and `80-`. Please refer to the section on [shard naming](../../../concepts/shard/#shard-naming) for more info on how shards are named.
