---
title: Sharding Guidelines
weight: 3
---

The following guidelines are not set in stone. They mainly establish a framework for making decisions.

### Why

There was a time when sharding used to be a line that one should avoid crossing for as long as possible. However, with Vitess considerably reducing the pain of sharding, we can look at leveraging some of its benefits much sooner than when a machine runs out of capacity:

* Smaller blast radius: If a shard goes down, the outage affects a smaller percentage of the users.
* Improved resource utilization: It is difficult to pack large instances of servers efficiently across machines. It is much easier to utilize the capacity of the existing hardware if the shard sizes are relatively small. Orchestration systems like Kubernetes further facilitate such utilization.
* Reduced contention: MySQL itself runs a lot better when instance sizes are small. There is less internal contention, replicas tend to keep up more easily with their primary, etc.
* Improved maintenance: Operations like schema deployment can happen in parallel across all shards and finish much sooner than usual.

There is a general worry that the complexity of deployment increases with the number of servers. However, this becomes a static cost once the necessary automation and monitoring is put in place.

### Why not

There are also reasons why you may want to avoid sharding. The main reason is that you may introduce inefficiencies by splitting data that would have been better off if it stayed together. Or, if your database is extremely small.

However, if you reach a point where the data is starting to grow, sharding may become inevitable.

### Moving Tables

Typically, the first step you may perform is to split your database by moving some tables on to other databases. In Vitess parlance, we call this as splitting off keyspaces. The [MoveTables](../../migration/move-tables) workflow allows you to perform this with minimal impact to the application.

### Resharding

Beyond a certain point, it may not make sense to separate tables that are strongly related to each other. This is when resharding comes into play. Choosing the “sharding key” is often intuitively obvious.

If you analyze the query pattern in the application, the query with the highest QPS will dictate the sharding key (or Primary Vindex). In our example below, we will be choosing `customer_id` as the Primary Vindex for the `customer` table.

If there are queries with other where clauses on the same table, those would be candidates for secondary lookup vindexes.

### Joins

The next criteria to take into account are joins. If you are performing joins across tables, it will be beneficial to keep those rows together. In our example, we will be keeping the rows of the order table along with their customer. This grouping will allow us to efficiently perform operations like reading all orders placed by a customer.

### Transactions

It is important to keep transactions within a single shard whenever possible.

Grouping related rows together usually results in transactions also falling within the same shard, but there are situations where this may not be possible. For such use-cases, Vitess supports [configurable atomicity levels for transactions that go across shards](../../configuration-advanced/shard-isolation-atomicity).

In the cases where a cross-shard transaction simply cannot be avoided, the [usage of 2PC](../../../reference/features/two-phase-commit/) allows for atomic writes across shards in a single logical transaction.

### Large Tenants

If your application is tenant-based, it is possible that a single tenant may grow so big that they may not fit in one shard. If so, it is likely that the application is using a different key that has a higher cardinality than the tenant id.

The question to ask oneself is: if the tenant were a single application by themselves, what would be their sharding key, and then shard by that key instead of the tenant id.

Vitess now has support for [multi-column Vindexes](../advanced-vschema/#multi-column-vindexes). You can now shard by the tenant id and a secondary key. The two-column sharding approach allows you to group all data for a given tenant into a smaller set of shards rather than a random distribution. This may be beneficial for security or compliance reasons, in case the tenant would want their data to be physically isolated from other tenants.

### Region Sharding

The Vitess multi-column Vindex feature also allows you to locate data associated with regions in different geographical locations. For more details, see [Region-based Sharding](../../configuration-advanced/region-sharding).

### Many-to-Many relationships

Sharding works well only if the relationship between data is hierarchical (one-to-one or one-to-many). If a table has foreign keys into multiple other tables, you have to choose one based on the strongest relationship and group the rows by that foreign key. The rest of the relationships will incur cross-shard overheads.

If more than one relationship is critically strong, you can look at the [Materialization](../../../reference/vreplication/materialize) feature which allows you to create a materialized view of the table that is sharded using the other relationship. The application will write to the source, and the other view will be automatically updated.

### Course Correction

It may happen that the original sharding decision is not working out. It may also be possible that the application evolves in such a way that the sharding decision you previously made does not make sense any more.

In such cases, the [MoveTables](../../migration/move-tables) feature can be used to change the sharding key of existing tables.

Essentially, Vitess removes the fear of making the wrong sharding decision because you can always change your mind later.

### Rule of Thumb

Although a Vitess shard can grow to many terabytes, we have seen that 250GB is the sweet spot. If your data size approaches this limit, it is time to think about splitting your data.

Please also note that smaller shard sizes will backup more quickly. However, you will likely end up with more shards to backup, which may take more time to run in total, but can be run in parallel.  
