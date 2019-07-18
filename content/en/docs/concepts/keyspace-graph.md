---
title: Keyspace Graph
---

# Keyspace Graph

The *keyspace graph* allows Vitess to decide which set of shards to use for a given keyspace, cell, and tablet type.

## Partitions

During horizontal resharding (splitting or merging shards), there can be shards with overlapping key ranges. For example, the source shard of a split may serve `c0-d0` while its destination shards serve `c0-c8` and `c8-d0` respectively.

Since these shards need to exist simultaneously during the migration, the keyspace graph maintains a list (called a *partitioning* or just a *partition*) of shards whose ranges cover all possible keyspace ID values, while being non-overlapping and contiguous. Shards can be moved in and out of this list to
determine whether they are active.

The keyspace graph stores a separate partitioning for each `(cell, tablet type)` pair. This allows migrations to proceed in phases: first migrate *rdonly* and *replica* requests, one cell at a time, and finally migrate *master* requests.

## Served From

During vertical resharding (moving tables out from one keyspace to form a new keyspace), there can be multiple keyspaces that contain the same table.

Since these multiple copies of the table need to exist simultaneously during the migration, the keyspace graph supports keyspace redirects, called `ServedFrom` records. That enables a migration flow like this:

1. Create `new_keyspace` and set its `ServedFrom` to point to `old_keyspace`.
2. Update the app to look for the tables to be moved in `new_keyspace`. Vitess will automatically redirect these requests to `old_keyspace`.
3. Perform a vertical split clone to copy data to the new keyspace and start filtered replication.
4. Remove the `ServedFrom` redirect to begin actually serving from `new_keyspace`.
5. Drop the now unused copies of the tables from `old_keyspace`.

There can be a different `ServedFrom` record for each `(cell, tablet type)` pair. This allows migrations to proceed in phases: first migrate *rdonly* and *replica* requests, one cell at a time, and finally migrate *master* requests.

