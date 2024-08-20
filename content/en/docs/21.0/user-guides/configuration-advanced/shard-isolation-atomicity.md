---
title: Shard Isolation and Atomicity Model
weight: 55
aliases: ['/docs/user-guides/shard-isolation-atomicity/'] 
---

This is meant to explain some of the practical effects of the Vitess multi-shard isolation and atomicity model touched on in [Vitess' scalability philosophy](../../../overview/scalability-philosophy/#consistency-model).

{{< info >}}
A note about naming:  When talking about multi-shard atomicity and isolation informally, we may talk about it as "consistency", but in the context of **ACID** (atomicity, consistency, isolation, durability) as it is applied in a database context, this is incorrect. For this document, we will attempt to use the more precise terms.
{{< /info >}}

## Introduction

For a sharded database (keyspace) Vitess maintains multiple, independent MySQL instances. Each of these instances is a member of a single **shard**, and contains a subset of the rows for one or more tables in the keyspace, dependent on the sharding strategy selected for that table according to the **vschema** for that keyspace.

When it comes to dealing with **isolation** and **atomicity** in the database sense (i.e.  the `I` and `A` in `ACID`), there are two main issues in a sharded environment like Vitess:

  * Cross-shard isolation
  * Cross-shard atomicity

Before we dive in, let us state that in the simple case, where a read (`SELECT`) or write (`INSERT`, `UPDATE`, `DELETE`) only addresses data in a single shard, there are no cross-shard concerns, and in general, both the isolation and atomicity guarantees are similar (or the same) to that of MySQL.

## Cross-shard Isolation

Because cross-shard writes might not be [completely atomic](../shard-isolation-atomicity/#cross-shard-atomicity), cross-shard primary reads (even if they all go to the primary) might not display **isolation**, i.e. they may show partial results for in-flight cross-shard write operations. A simple example may be that the all the rows for a multi-valued insert might not become visible across all shards at the same time.

This is typically not a big issue for most applications, since so-called read-after-write consistency is retained,  e.g.:

  * if you performed a multi-value insert across multiple shards,
  * **and** it completed successfully
  * **then** if you issue a multi-shard (primary) read after this, you should see the results of what you wrote across all shards (assuming nothing else deleted/updated those rows in the meanwhile)

### Note  

If you perform replica or rdonly reads instead of primary reads (using the `@replica` or `@rdonly` Vitess dbname syntax extension), you will face the same issues you would if you read from a single MySQL replica instance. Accordingly, writes might not become visible for an extended period of time, depending on **replica lag**. That being said, since Vitess helps you to keep your individual primary instances smaller, replica lag should be less of an issue than it would be with an unsharded large MySQL setup.

## Cross-shard Atomicity

When performing a write (`INSERT`, `UPDATE`, `DELETE`) across multiple shards, Vitess attempts to optimize performance, while also trying to ensure as much **atomicity** as possible. That is, Vitess will attempt to ensure that the whole write operation succeeds across all shards, or is rolled back.  However, if you think about what actually needs to happen across the multiple shards, achieving full atomicity across a (potentially large) number of shards can be very expensive. As a result, Vitess does not even try to guarantee cross-shard **isolation**, but rather focuses on trying to optimize cross-shard **atomicity**. The difference here is that while the results of a single transaction might not become visible across all shards in the same instant, Vitess does try to ensure that write failures on a subset of the shards are:

  * rolled back
  * or if they cannot be rolled back, the application receives a reasonable error to that effect.

As an example, imagine an insert of 20 rows into a sharded table with 4 shards. There are many ways for Vitess to take an insert like this and perform the inserts to the backend shards:

### Method 1:  The Naive Way

The first method would be to launch an autocommit insert of the subset of rows for each shard to the 4 shards. This would insert concurrently across the 4 shards, so would be great for performance. However, there are significant drawbacks:

  * What do we do if any of them fail?
  * What do we do if any/all of them time out?

As a result we might not even be able to tell the application with some certainty what happened. However, for some use-cases the performance of this option might be desirable. It is possible to select this behavior for individual DML statements in Vitess by using the special Vitess comment:

```sh
/*vt+ MULTI_SHARD_AUTOCOMMIT=1 */
```

It is not possible to make this the default behavior in Vitess; i.e. you will have to change your application code to take advantage of this option.

In the [examples](https://github.com/vitessio/vitess/tree/main/examples/vtexplain), we have a script, [`atomicity_method1.sh`](https://github.com/vitessio/vitess/tree/main/examples/vtexplain/atomicity_method1.sh); which tries to use a sample vschema from `atomicity_vschema.json` and SQL schema in `atomicity_schema.sql` to illustrate this method. Let's run this and inspect the output:

```sh
$ ./method1.sh
+ vtexplain --vschema-file atomicity_vschema.json --schema-file atomicity_schema.sql --shards 4 --sql 'INSERT /*vt+ MULTI_SHARD_AUTOCOMMIT=1 */ INTO t1 (c1) values (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20);'
----------------------------------------------------------------------
INSERT /*vt+ MULTI_SHARD_AUTOCOMMIT=1 */ INTO t1 (c1) values (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20)

1 ks1/-40: insert /*vt+ MULTI_SHARD_AUTOCOMMIT=1 */ into t1(c1) values (10), (14), (15), (16)
1 ks1/40-80: insert /*vt+ MULTI_SHARD_AUTOCOMMIT=1 */ into t1(c1) values (8), (17), (18)
1 ks1/80-c0: insert /*vt+ MULTI_SHARD_AUTOCOMMIT=1 */ into t1(c1) values (2), (3), (4), (7), (9), (12), (13), (19), (20)
1 ks1/c0-: insert /*vt+ MULTI_SHARD_AUTOCOMMIT=1 */ into t1(c1) values (1), (5), (6), (11)

----------------------------------------------------------------------
```

As can be seen from this output, we just issue all the inserts with the subset of values destined for each shard without any transactions.

### Method 2:  The I-don't-want-this Way (a.k.a. SINGLE)

In certain situations, a schema may be constructed in a fashion where cross-shard writes are very rare (or should not happen). In a situation like this Vitess provides for a transaction mode (set via the MySQL set statement `set transaction_mode = 'single'`) called **SINGLE**.  In this transaction mode, any write that needs to span multiple shards will fail with an error. Similarly, any **transactional read** (i.e. using `BEGIN` & `COMMIT`) that spans multiple shards will also get an error.

Here is our example for this case using `vtexplain` and [`atomicity_method2.sh`](https://github.com/vitessio/vitess/tree/main/examples/vtexplain/atomicity_method2.sh):

```sh
$ ./method2.sh
+ vtexplain --vschema-file atomicity_vschema.json --schema-file atomicity_schema.sql --shards 4 --sql 'SET transaction_mode="single"; INSERT INTO t1 (c1) values (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20);'
E0803 16:54:09.738322   89168 tabletserver.go:1368] unknown error: unsupported query rollback (errno 1105) (sqlstate HY000): Sql: "rollback", BindVars: {}
E0803 16:54:09.738352   89168 tabletserver.go:1368] unknown error: unsupported query rollback (errno 1105) (sqlstate HY000): Sql: "rollback", BindVars: {}
E0803 16:54:09.738431   89168 tabletserver.go:1368] unknown error: unsupported query rollback (errno 1105) (sqlstate HY000): Sql: "rollback", BindVars: {}
E0803 16:54:09.739161   89168 tabletserver.go:1368] unknown error: unsupported query rollback (errno 1105) (sqlstate HY000): Sql: "rollback", BindVars: {}
ERROR: vtexplain execute error in 'INSERT INTO t1 (c1) values (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20)': multi-db transaction attempted: [target:{keyspace:"ks1" shard:"40-80" tablet_type:PRIMARY} transaction_id:1628034849705415307 tablet_alias:{cell:"explainCell" uid:2} target:{keyspace:"ks1" shard:"80-c0" tablet_type:PRIMARY} transaction_id:1628034849709028116 tablet_alias:{cell:"explainCell" uid:3} target:{keyspace:"ks1" shard:"-40" tablet_type:PRIMARY} transaction_id:1628034849700176113 tablet_alias:{cell:"explainCell" uid:1} target:{keyspace:"ks1" shard:"c0-" tablet_type:PRIMARY} transaction_id:1628034849710978055 tablet_alias:{cell:"explainCell" uid:4}]
multi-db transaction attempted: [target:{keyspace:"ks1" shard:"40-80" tablet_type:PRIMARY} transaction_id:1628034849705415307 tablet_alias:{cell:"explainCell" uid:2} target:{keyspace:"ks1" shard:"80-c0" tablet_type:PRIMARY} transaction_id:1628034849709028116 tablet_alias:{cell:"explainCell" uid:3} target:{keyspace:"ks1" shard:"-40" tablet_type:PRIMARY} transaction_id:1628034849700176113 tablet_alias:{cell:"explainCell" uid:1}]
multi-db transaction attempted: [target:{keyspace:"ks1" shard:"40-80" tablet_type:PRIMARY} transaction_id:1628034849705415307 tablet_alias:{cell:"explainCell" uid:2} target:{keyspace:"ks1" shard:"80-c0" tablet_type:PRIMARY} transaction_id:1628034849709028116 tablet_alias:{cell:"explainCell" uid:3}]
```

As expected, we start getting errors since we are attempting a Vitess "transaction" across multiple shards.

If we limited ourselves to writes that only target a single one of the multiple shards, this would work fine, e.g.:

```sh
$ ./method2_working.sh
+ vtexplain --vschema-file atomicity_vschema.json --schema-file atomicity_schema.sql --shards 4 --sql 'SET transaction_mode="single"; INSERT INTO t1 (c1) values (10),(14),(15),(16);'
----------------------------------------------------------------------
SET transaction_mode="single"


----------------------------------------------------------------------
INSERT INTO t1 (c1) values (10),(14),(15),(16)

1 ks1/-40: insert into t1(c1) values (10), (14), (15), (16)

----------------------------------------------------------------------
```

Here is the result if we attempted a transactional read across shards while in `transaction_mode` of `single` (note the `BEGIN` and `COMMIT` in the query):

```sh
$ ./method2_reads.sh
+ vtexplain --vschema-file atomicity_vschema.json --schema-file atomicity_schema.sql --shards 4 --sql 'SET transaction_mode="single"; BEGIN; SELECT * from t1; COMMIT;'
E0803 17:00:49.524545   89777 tabletserver.go:1368] unknown error: unsupported query rollback (errno 1105) (sqlstate HY000): Sql: "rollback", BindVars: {}
E0803 17:00:49.524549   89777 tabletserver.go:1368] unknown error: unsupported query rollback (errno 1105) (sqlstate HY000): Sql: "rollback", BindVars: {}
E0803 17:00:49.524581   89777 tabletserver.go:1368] unknown error: unsupported query rollback (errno 1105) (sqlstate HY000): Sql: "rollback", BindVars: {}
E0803 17:00:49.524661   89777 tabletserver.go:1368] unknown error: unsupported query rollback (errno 1105) (sqlstate HY000): Sql: "rollback", BindVars: {}
ERROR: vtexplain execute error in 'SELECT * from t1': multi-db transaction attempted: [target:{keyspace:"ks1" shard:"c0-" tablet_type:PRIMARY} transaction_id:1628035249495856333 tablet_alias:{cell:"explainCell" uid:4} target:{keyspace:"ks1" shard:"80-c0" tablet_type:PRIMARY} transaction_id:1628035249493377809 tablet_alias:{cell:"explainCell" uid:3} target:{keyspace:"ks1" shard:"-40" tablet_type:PRIMARY} transaction_id:1628035249485888657 tablet_alias:{cell:"explainCell" uid:1} target:{keyspace:"ks1" shard:"40-80" tablet_type:PRIMARY} transaction_id:1628035249490426670 tablet_alias:{cell:"explainCell" uid:2}]
multi-db transaction attempted: [target:{keyspace:"ks1" shard:"c0-" tablet_type:PRIMARY} transaction_id:1628035249495856333 tablet_alias:{cell:"explainCell" uid:4} target:{keyspace:"ks1" shard:"80-c0" tablet_type:PRIMARY} transaction_id:1628035249493377809 tablet_alias:{cell:"explainCell" uid:3} target:{keyspace:"ks1" shard:"-40" tablet_type:PRIMARY} transaction_id:1628035249485888657 tablet_alias:{cell:"explainCell" uid:1}]
multi-db transaction attempted: [target:{keyspace:"ks1" shard:"c0-" tablet_type:PRIMARY} transaction_id:1628035249495856333 tablet_alias:{cell:"explainCell" uid:4} target:{keyspace:"ks1" shard:"80-c0" tablet_type:PRIMARY} transaction_id:1628035249493377809 tablet_alias:{cell:"explainCell" uid:3}]
```


### Method 3:  The Default Way

By default, Vitess employs a default setting for `transaction_mode` of **MULTI** (`set transaction_mode = 'multi'`).  This mode is a tradeoff between atomicity, isolation and performance, where Vitess will attempt to minimize (but not guarantee) the chances of a partial cross-shard update.  What Vitess does in a case like this is:

  * Phase 1:  Open transactions to each of the shards.  If anything fails during this phase, nothing has been written, the application sees an error, and can cleanly retry. These transactions are opened in parallel for best performance.
  * Phase 2:  Issue the subset of inserts for each shard. This is also done in parallel. An error at this point will allow us to rollback the transactions on the shards.  Again, no data has been affected, and the application can retry.
  * Phase 3:  Issue commits against each shard involved in the insert. This is done serially.  This allows the operation to halt if there is an error on one of the shards.  At this point an error would be returned to the application, **but the inserts on shards committed before the failing shard cannot be rolled back**. As a result the atomicity of the insert is broken, and now clients will see (possibly permanently) inconsistent results. It is left up to the client to repair the possible inconsistency, potentially with a retry, or some more elaborate mechanism.

VTGate records a warning and increments a counter when a commit error occurs on one shard after successfully committing to other shard(s). The warnings will look like this:

``` mysql
mysql> show warnings;
+---------+------+-----------------------------------------------------+
| Level   | Code | Message                                             |
+---------+------+-----------------------------------------------------+
| Warning |  301 | multi-db commit failed after committing to 1 shards |
+---------+------+-----------------------------------------------------+
1 row in set, 1 warning (0.00 sec)
```
<br>

#### Notes: 

* As an optimization Phase 1+2 are performed at the same time, see below.
* Because parts of this proceeds serially, the latency of the overall insert is typically proportional to the number of shards that the insert is scattered across.

Let's run our example for this case [`atomicity_method3.sh`](https://github.com/vitessio/vitess/tree/main/examples/vtexplain/atomicity_method3.sh) and inspect the output:

```sh
$ ./method3.sh
+ vtexplain --vschema-file atomicity_vschema.json --schema-file atomicity_schema.sql --shards 4 --sql 'INSERT INTO t1 (c1) values (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20);'
----------------------------------------------------------------------
INSERT INTO t1 (c1) values (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20)

1 ks1/-40: begin
1 ks1/-40: insert into t1(c1) values (10), (14), (15), (16)
1 ks1/40-80: begin
1 ks1/40-80: insert into t1(c1) values (8), (17), (18)
1 ks1/80-c0: begin
1 ks1/80-c0: insert into t1(c1) values (2), (3), (4), (7), (9), (12), (13), (19), (20)
1 ks1/c0-: begin
1 ks1/c0-: insert into t1(c1) values (1), (5), (6), (11)
2 ks1/40-80: commit
3 ks1/80-c0: commit
4 ks1/c0-: commit
5 ks1/-40: commit

----------------------------------------------------------------------
```

The numbers on the left of the output indicate the ordering of operations, i.e. everything with the number `1` are performed concurrently. Here we can see that Phase 1 and 2 are initiated across all the shards for the multi-sharded insert concurrently.  It is only in Phase 3 when we start doing the commits to each of the shards in serial, which allows us to abandon or roll back changes to at least a subset of the shards if something goes wrong between the `2 ks1/40-80: commit` and the `5 ks1/-40: commit`.


### Method 4:  The TWOPC way

Vitess also supports (assuming the vtgate and vttablets have been configured appropriately) a two-phase commit option for multi-shard writes. This is enabled by using the non-default setting for `transaction_mode` of **TWOPC**. In this mode, Vitess can guarantee atomicity for cross-shard writes;  but still does not guarantee isolation; i.e. other clients can still see partial commits across shards.

It should be emphasized that if you need to use **TWOPC** extensively in your application, you may be using Vitess incorrectly;  the vast majority of Vitess users do not use it at all.

See our [TWOPC page](../../../reference/features/two-phase-commit/) for more details on how to configure **TWOPC**.

In TWOPC mode, Vitess uses the `_vt` sidecar database to record metadata related to each transactions across multiple tables.  As a result, any multi-shard write in **TWOPC** mode is likely to be an order of a magnitude slower than in **MULTI** mode.

Unfortunately, we cannot use `vtexplain` to illustrate the working of TWOPC mode.


## In Closing

From the above examples, it should be clear that as the number of shards increase, large write operations that span multiple shards become more problematic from a performance point of view. It is therefore important for Vitess keyspaces (databases) that will span a large number of shards to be designed in a way that individual writes will affect a minimum of shards.
