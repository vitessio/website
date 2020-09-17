---
title: Reshard
description: Move one or more tables between keyspaces without downtime
aliases: ['/docs/advanced/reshard','/docs/reference/reshard']
weight: 60
---

### Command

```
Reshard  [-skip_schema_copy] <keyspace.workflow> <source_shards> <target_shards>

```


### Description

Reshard support horizontal sharding by letting you change the sharding ranges of your existing keyspace.

### Parameters

#### -skip_schema_copy 
**optional**\
**default** false

<div class="cmd">
If true the source schema is copied to the target shards. If false, you need to create the tables
before calling reshard.
</div>

#### keyspace.workflow 
**mandatory**

<div class="cmd">
Name of target keyspace and the associated workflow name to create for this Reshard workflow.
</div>

#### source_shards 
**mandatory**

<div class="cmd">
Comma separated shard names to reshard to.
</div>

#### target_shards
**mandatory**

<div class="cmd">
Comma separated shard names to reshard to.
</div>
