---
title: VReplication
description: Frequently Asked Questions about Vitess
weight: 6
---

## What is VReplication? How does it work?

VReplication is used as a building block for a number of use cases throughout Vitess. It works as a stream or combination of streams that establish replication from a source keyspace/shard into a target keyspace/shard. A given stream can replicate multiple tables. It allows Vitess to keep the data being copied in-sync by using a combination of copying rows and filtered replication.

Vreplication works via the following process:

1. Analyzing the source table and identifying what rows it needs to copy. 
2. It then very briefly locks the table and makes a note of the current GTID replication position on the source database. After it’s noted the current GTID Vreplication then unlocks the table again.
3. It selects all the rows and all the columns from GTID value 0 onward and copies from that select.
4. It then streams the copy over to Vitess to start inserting rows. Vreplication will keep copying for a period of time, around an hour, to attempt to finish the copy. 
5. If Vreplication hasn’t finished in an hour, it will stop and go back to the table in order to pick up any changes that have been made since it started copying.
6. It knows what the GTID was when it started copying and what the GTID is now. This enables it to determine what events have occurred after it performed the first select and copy. 
7. It will then filter out all the events except the ones that pertain to the relevant table and will apply the changes to the destination table.

This process then repeats until Vreplication finishes copying the whole table. After the copying process finishes Vreplication will change to filtered replication to keep the table in sync. 

## How can I use VReplication?

There are a number of higher level commands like MoveTables and Materialized Views that create Vreplication streams behind the scenes of the command. By using these higher level commands, Vitess creates VReplication rules for the user. Further use cases are listed out [here](https://vitess.io/docs/reference/features/vreplication/).

For more information on [MoveTables](https://vitess.io/docs/user-guides/migration/move-tables/) and [Materialized Views](https://vitess.io/docs/user-guides/migration/materialize/ please follow the links provided.

There is a way to create VReplication rules by hand but we don’t recommend using that method as it can be challenging to configure the rules correctly.