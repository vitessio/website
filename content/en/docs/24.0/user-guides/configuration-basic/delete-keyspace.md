---
title: Delete a Keyspace
weight: 14
---

Although adding a keyspace is implicit, deleting one is not. In order to delete a keyspace, you must first bring down all tablets on that keyspace.

Following this, you should delete all shards of a keyspace. In the current example, `commerce` has only one shard (`0`). You can use the following command to delete it:

```text
vtctldclient DeleteShards --recursive commerce/0
```

The `recursive` flag is required to ensure that the shard is deleted from all cells. If there are tablets still running against the shard, the command will fail.

You can add an `--even_if_serving` flag to ignore running tablets, but it is not recommended. Otherwise, this would cause existing vttablets to get confused about their tablet records being deleted.

If a keyspace has more than one shard, you may pass multiple shard names to `DeleteShards`.
They will be deleted sequentially; if one deletion fails, the operation stops there.

{{< warning>}}
Deleting a shard also deletes the metadata for all the backups, but it does not delete the backups themselves. This is something you have to do manually.
{{< /warning >}}

Once all shards are deleted, you can delete the keyspace with:

```text
vtctldclient DeleteKeyspace commerce
```

`DeleteKeyspace` also supports a `--recursive` flag that loops through all shards and deletes them recursively, but also ignores any tablets that are running. Note that restarting a vttablet for the deleted keyspace will cause the keyspace to be recreated. This is yet another reason for ensuring that all vttablets are shutdown upfront.
