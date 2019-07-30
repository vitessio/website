---
title: Vitess, MySQL Replication, and Schema Changes
weight: 5
---

## Statement vs Row Based Replication

MySQL supports two primary modes of replication in its binary logs: statement or row based. Vitess recommends using Row-based Replication.

For schema changes, if the number of affected rows is greater > 100k (configurable), we don't allow direct application of DDLs. The recommended tools in such cases are [gh-ost](https://github.com/github/gh-ost) or [pt-osc](https://www.percona.com/doc/percona-toolkit/LATEST/pt-online-schema-change.html).

## Rewriting Update Statements

Vitess rewrites ‘UPDATE’ SQL statements to always know what rows will be affected. For instance, this statement:

``` sql
UPDATE <table> SET <set values> WHERE <clause>
```

Will be rewritten into:

``` sql
SELECT <primary key columns> FROM <table> WHERE <clause> FOR UPDATE
UPDATE <table> SET <set values> WHERE <primary key columns> IN <result from previous SELECT> /* primary key values: … */
```

With this rewrite in effect, we know exactly which rows are affected, by primary key, and we also document them as a SQL comment.

The replication stream then doesn’t contain the expensive WHERE clauses, but only the UPDATE statements by primary key. In a sense, it is combining the best of row based and statement based replication: the slaves only do primary key based updates, but the replication stream is very friendly for schema changes.

Also, Vitess adds comments to the rewritten statements that identify the primary key affected by that statement. This allows us to produce an Update Stream (see section below).


## Update Stream

Since the replication stream also contains comments of which primary key is affected by a change, it is possible to look at the replication stream and know exactly what objects have changed. This Vitess feature is called [Update Stream](../update-stream).

By subscribing to the Update Stream for a given shard, one can know what values change. This stream can be used to create a stream of data changes (export to an Apache Kafka for instance), or even invalidate an application layer cache.

Note: the [Update Stream](../update-stream) only reliably contains the primary key values of the rows that have changed, not the actual values for all columns. To get these values, it is necessary to re-query the database.

We have plans to make this Update Stream feature more consistent, very resilient, fast, and transparent to sharding.

## Semi-Sync

Vitess uses Semisynchronous replication in it's default configuration. This means the following will happen:

* The master will only accept writes if it has at least one slave connected and sending semi-sync ACK. It will never fall back to asynchronous (not requiring ACKs) because of timeouts while waiting for ACK, nor because of having zero slaves connected (although it will fall back to asynchronous in case of shutdown, abrupt or graceful).

   This is important to prevent split brain (or alternate futures) in case of a network partition. If we can verify all slaves have stopped replicating, we know the old master is not accepting writes, even if we are unable to contact the old master itself.

* Slaves of replica type will send semi-sync ACK. Slaves of rdonly type will not send ACK. This is because rdonly slaves are not eligible to be promoted to master, so we want to avoid the case where a rdonly slave is the single best candidate for election at the time of master failure (though a split brain is possible when all rdonly slaves have transactions that none of replica slaves have).

These behaviors combine to give you the property that, in case of master failure, there is at least one other replica type slave that has every transaction that was ever reported to clients as having completed. You can then ([manually](../vtctl/#emergencyreparentshard)], or with an automated tool like [Orchestrator](https://github.com/github/orchestrator)) pick the replica that is farthest ahead in GTID position and promote that to be the new master.

Thus, you can survive sudden master failure without losing any transactions that were reported to clients as completed. In MySQL 5.7+, this guarantee is strengthened slightly to preventing loss of any transactions that were ever **committed** on the original master, eliminating so-called [phantom reads](http://bugs.mysql.com/bug.php?id=62174).

On the other hand these behaviors also give a requirement that each shard must have at least 2 tablets with type *replica* (with addition of the master that can be demoted to type *replica* this gives a minimum of 3 tablets with initial type *replica*). This will allow for the master to have a semi-sync acker when one of the replica tablets is down for any reason (for a version update, machine reboot, schema swap or anything else).

With regard to replication lag, note that this does **not** guarantee there is always at least one replica type slave from which queries will always return up-to-date results. Semi-sync guarantees that at least one slave has the transaction in its relay log, but it has not necessarily been applied yet. The only way to guarantee a fully up-to-date read is to send the request to the master.

See this [document](../row-based-replication) for more information.
