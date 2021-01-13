---
title: Delete a Keyspace
weight: 14
---

Although adding a keyspace is implicit, deleting one is not. In order to delete a keyspace, you must first bring down all tablets on that keyspace.

Following this, you should either delete all shards of a keyspace:

```text
vtctlclient DeleteShard -recursive commerce/0
```

The `recursive` flag is required to ensure that the shard is deleted from all cells. If there are tablets still running against the shard, the command will fail.

You can add an `-even_if_serving` flag to ignore running tablets, but it is not recommended.

Once all shards are deleted, you can delete the keyspace with:

```text
Vtctlclient DeleteKeyspace commerce
```

`DeleteKeyspace` also supports a `-recursive` flag that loops through all shards and deletes them recursively, but also ignores any tablets that are running.
