---
title: Vindexes
weight: 6
---

## What is a Vindex?
If you are unfamiliar with Vindexes, we recommend that you first read the [documentation](https://vitess.io/docs/reference/features/vindexes/).

## Does the Primary Vindex for a table need to match its Primary Key?

It is not necessary that a Primary Vindex be the same as the Primary Key. In fact, there are many use cases where you would not want this. For example, if there are tables with one-to-many relationships, the Primary Vindex of the main table is likely to be the same as the Primary Key.

However, if you want the rows of the secondary table to reside in the same shard as the parent row, the Primary Vindex for that table must be the foreign key that points to the main table. A typical example is a user and order table.

In this case, the order table has the `user_id` as a foreign key to the `id` of the user table. The `order_id` may be the primary key for `order`, but you may still want to choose `user_id` as Primary Vindex, which will make a user's orders live in the same shard as the user.

## How do I create a new LookupVindex?

Please refer to the [user guide on CreateLookupVindex](https://vitess.io/docs/user-guides/configuration-advanced/createlookupvindex/) to learn how to create a new Lookup Vindex, how to add it to a column, and how to verify that it was successfully added.

