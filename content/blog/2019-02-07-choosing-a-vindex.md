---
author: "Abhi Vaidyanatha"
date: 2019-02-07T09:07:21-08:00
slug: "2019-02-07-choosing-a-vindex"
tags: ['Guides', 'Vindexes', 'Documentation']
title: "Choosing a Primary Vindex"
---

When we talk to Vitess, it appears as if we are talking to a single unit, so what sets up this seemingly magical feature? This is achieved through a VSchema, the beautiful mind that sends all of your queries to the correct shard. 

When Vitess shards your database, it assigns each row an identifier called a keyspace ID. We then break up the domain of all keyspace ID values into ranges and assign ranges to each shard. Therefore, if a row’s keyspace ID falls in a certain range, it will be assigned a specific shard. This is cool because we can reshard the data completely without changing the keyspace ID at all… or your application knowing about it. The less your application has to know, the better. 

Vindexes are maps from column values to keyspace ID. This map can be configured in many different ways, but a simple hash map works fine. We’ll decide what kind of map we want after we pick our vindex column.  

Half the battle of designing a VSchema is choosing a strong primary vindex - you’ve learned that vindexes map a column value to a keyspace ID, so what qualities are we looking for? 

* Frequency in WHERE clause of queries
* Uniqueness (of the mapping function)
* Co-locating rows for joins
* Co-locating rows for single-shard transactions
* High cardinality

Let’s break this down. Uniqueness just means that a vindex will map a column value to only one keyspace ID (or none at all). Remember that all vindexes need to do is direct our queries to the correct shard, so it’s okay if another column value maps to the same keyspace ID - it’s Vitess’ job to figure that out. 

**Note:** If a vindex maps a column value to a null keyspace ID, Vitess will simply error out or neutralize the query depending on the query type.*

Co-location is a critical concept to understand and should heavily influence your sharding scheme. When Vitess performs operations on your keyspaces, you want as many of them to be isolated to a single shard as possible. This can be easily achieved by using the same primary vindex for multiple tables, as all rows tied to the same primary index will automatically be located in the same shard due to the uniqueness property of the vindex map. 

Cardinality refers to the number of unique elements in the column. A high cardinality will produce a sufficiently large number of keyspace IDs, which will give you finer control for rebalancing load through resharding.

Naturally, if you’re using a primary key as your where clause for your highest QPS queries, you will likely be using this as your primary vindex. 

*Can I change the values of my primary vindex?*
No. Vitess does not support updating primary vindex columns, even if it will stay within a shard. We don’t want something to pass in tests and fail in production; updating the vindex may result in a row having to move across shards. 

**Note:** 99.9% of the time you want your primary vindex to have a pre-established map between column value and keyspace ID. This is referred to as a functional vindex. Conversely, a lookup vindex is one where a table association is created between values and keyspace IDs for fine-grained query optimization. These lookup vindexes that help Vitess speed up your queries are used as secondary vindexes so that we can avoid doing scatter-gathers on queries that don’t refer to the primary vindex. 

Finally, after we have decided on our column value, we can settle on a map type. Vitess supports some predefined ones such as identities, md5 hashes, bit reversal, and others, but you can also define your own! For most cases, identities and md5 hashes work great, but there are some exceptions. While not common, certain use cases involving geolocation may warrant these custom defined vindexes. For example, when you want to co-locate information from a certain region or customer, you can create functions that take information from the columns and create the keyspace ID to have expected similar properties. This allows you to have finer grained control over your shard ranges. 

If you have any other questions, check the article on it in our [documentation](https://vitess.io/docs/schema-management/vschema/) or head on over to the [Vitess Slack channel!](https://vitess.slack.com/messages)

