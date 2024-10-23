---
title: Vindex
description: Frequently Asked Questions about Vitess
weight: 6
---

## What is a secondary Vindex? How does it work?

Secondary Vindexes are additional Vindexes against other columns of a table offering optimizations for WHERE clauses that do not use the Primary Vindex. Secondary Vindexes return a single or a limited set of keyspace IDs which will allow VTGate to only target shards where the relevant data is present. In the absence of a Secondary Vindex, VTGate would have to send the query to all shards (called a scatter query).

It is important to note that Secondary Vindexes are only used for making routing decisions. The underlying database shards will need traditional indexes on those same columns, to allow efficient retrieval from the table on the underlying MySQL instances.

MARKED NOT HELPFUL

## How do I create a unique index for a column in Vitess?

Unique index is a distinct MySQL option. For Vitess just normal MySQL DDL will do. You have a couple other options as well either to use `ApplySchema` or directly apply the index to MySQL.

Please note this is different from a unique Vindex, as that enables sending queries to one specific shard rather than ensuring the uniqueness of a column.

## How do I make a CreateLookupVindex?

In addition to the [user guide](https://vitess.io/docs/user-guides/configuration-advanced/createlookupvindex/) on CreateLookupVindex we also have an example walkthrough [here](https://github.com/aquarapid/vitess_examples/tree/master/vindexes/createlookupvindex). 

This walkthrough demonstrates the syntax of a CreateLookupVindex how to make one, how to add it to a column, and how to verify that it was successfully added.

## What is a LookupVindex and how does it work?

CreateLookupVindex is a new VReplication workflow that was introduced in Vitess 6. It is used to create and backfill a lookup Vindex automatically for a table that already exists and that could already have a significant amount of data in it.

The CreateLookupVindex process uses VReplication for the backfill process, until the lookup Vindex is “in sync”. Then the normal process for adding/deleting/updating rows in the lookup Vindex via the standard transactional flow when updating the “owner” table for the Vindex takes over.

You can read more about how to make a CreateLookupVindex [here](https://vitess.io/docs/user-guides/configuration-advanced/createlookupvindex/). If you are unfamiliar with Vindexes we recommend that you first read the information [here](https://vitess.io/docs/reference/features/vindexes).

MARKED NOT HELPFUL

## Does the Primary Vindex need to match its Primary Key?

It is not necessary that a Primary Vindex be the same as the Primary Key. In fact, there are many use cases where you would not want this. For example, if there are tables with one-to-many relationships, the Primary Vindex of the main table is likely to be the same as the Primary Key. 

However, if you want the rows of the secondary table to reside in the same shard as the parent row, the Primary Vindex for that table must be the foreign key that points to the main table. A typical example is a user and order table. 

In this case, the order table has the `user_id` as a foreign key to the `id` of the user table. The `order_id` may be the primary key for `order`, but you may still want to choose `user_id` as Primary Vindex, which will make a user's orders live in the same shard as the user.
