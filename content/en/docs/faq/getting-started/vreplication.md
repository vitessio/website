---
title: VReplication
weight: 6
---

## What is VReplication? How does it work?

VReplication is used as a building block for a number of features in Vitess. It works as a stream or combination of streams that establish replication from a source keyspace/shard into a target keyspace/shard. A given stream can replicate multiple tables. It allows Vitess to keep the data being copied in-sync by using a combination of copying rows and filtered replication.

VReplication works via the following process:

1. It first analyzes the source table on the source shard and identifies what rows it needs to copy. 
2. It then very briefly locks the table and records the current GTID replication position on the source database. After recording the current GTID position, VReplication then unlocks the table again.
3. It selects all rows and columns that match a specified filter from GTID value 0 onward and makes a copy of the results.
4. It then streams the copy over to the target shard to start inserting rows. VReplication will keep copying for a specified period of time (default 1 hour), to attempt to finish the copy. 
5. If the copying phase on the target hasn’t finished in an hour, it will stop and go back to the table in order to pick up any changes that have been made since it started copying.
6. It knows what the GTID was when it started copying and what the GTID is now. This enables it to determine what events have occurred after it performed the first select and copy. 
7. It will then filter out all the events except the ones that pertain to the relevant table and will apply the changes to the destination table.

This process then repeats until VReplication finishes copying the whole table. After the copying process finishes VReplication will transition to filtered replication to keep the table in sync between the source and the target. 

## How can I use VReplication?

There are a number of higher level commands like MoveTables, Reshard, and Materialize that create VReplication streams behind the scenes of the command. By using these higher level commands, Vitess creates VReplication rules for the user. Further use cases are listed out [here](https://vitess.io/docs/reference/features/vreplication/).

For more information on [MoveTables](https://vitess.io/docs/user-guides/migration/move-tables/) and [Materialized Views](https://vitess.io/docs/user-guides/migration/materialize/) please follow the links provided.

It is possible to create VReplication rules by hand, but we don’t recommend doing that as it can be challenging to configure the rules correctly.
