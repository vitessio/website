---
title: Vitess Replication
weight: 5
aliases: ['/docs/reference/row-based-replication/']
---

{{< warning >}}
Vitess requires the use of Row-Based Replication with GTIDs enabled. In addition, Vitess only supports the default `binlog_row_image` of `FULL`.
{{< /warning >}}

Vitess makes use of MySQL Replication for both high availability and to receive a feed of changes to database tables. This feed is then used in features such as [VReplication](../vreplication), and to identify schema changes so that caches can be updated.

## Semi-Sync

Vitess strongly recommends the use of Semisynchronous replication for High Availability. Semi-sync has the following characteristics:

* The master will only accept writes if it has at least one slave connected and sending semi-sync ACK. It will never fall back to asynchronous (not requiring ACKs) because of timeouts while waiting for ACK, nor because of having zero slaves connected (although it will fall back to asynchronous in case of shutdown, abrupt or graceful).

   This is important to prevent split brain (or alternate futures) in case of a network partition. If we can verify all slaves have stopped replicating, we know the old master is not accepting writes, even if we are unable to contact the old master itself.

* Slaves of replica type will send semi-sync ACK. Slaves of rdonly type will not send ACK. This is because rdonly slaves are not eligible to be promoted to master, so we want to avoid the case where a rdonly slave is the single best candidate for election at the time of master failure (though a split brain is possible when all rdonly slaves have transactions that none of replica slaves have).

These behaviors combine to give you the property that, in case of master failure, there is at least one other replica type slave that has every transaction that was ever reported to clients as having completed. You can then ([manually](../vtctl/#emergencyreparentshard)], or with an automated tool like [Orchestrator](https://github.com/github/orchestrator)) pick the replica that is farthest ahead in GTID position and promote that to be the new master.

Thus, you can survive sudden master failure without losing any transactions that were reported to clients as completed. In MySQL 5.7+, this guarantee is strengthened slightly to preventing loss of any transactions that were ever **committed** on the original master, eliminating so-called [phantom reads](http://bugs.mysql.com/bug.php?id=62174).

On the other hand these behaviors also give a requirement that each shard must have at least 2 tablets with type *replica* (with addition of the master that can be demoted to type *replica* this gives a minimum of 3 tablets with initial type *replica*). This will allow for the master to have a semi-sync acker when one of the replica tablets is down for any reason (for a version update, machine reboot, schema swap or anything else).

With regard to replication lag, note that this does **not** guarantee there is always at least one replica type slave from which queries will always return up-to-date results. Semi-sync guarantees that at least one slave has the transaction in its relay log, but it has not necessarily been applied yet. The only way to guarantee a fully up-to-date read is to send the request to the master.

## Filtered Replication

This is used during horizontal and vertical resharding, to keep source and destination shards up to date.

We need to transform the RBR events into SQL statements, filter them based either on `keyspace_id` (horizontal resharding) or table name (vertical resharding), and apply them.

For horizontal splits, we need to understand the VSchema to be able to find the primary VIndex used for sharding.

*Note*: this again means we need accurate schema information. We could do one of two things:

* Send all statements to all destination shards, and let them do the filtering. They can have accurate schema information if they receive and apply all schema changes through Filtered Replication.
* Have the filtering be done on the stream server side, and assume the schema doesn't change in incompatible ways. As this is simpler for now, that's the option we're going with.

## Database Schema Considerations

* Row-based replication requires that replicas have the same schema as the master, and corruption will likely occur if the column order does not match. Earlier versions of Vitess which used Statement-Based replication recommended applying schema changes on replicas first, and then swapping their role to master. This method is no longer recommended and a tool such as [`gh-ost`](https://github.com/github/gh-ost) or [`pt-online-schema-change`](https://www.percona.com/doc/percona-toolkit/LATEST/pt-online-schema-change.html) should be used instead.

* Using a column of type `FLOAT` or `DOUBLE` as part of a Primary Key is not supported. This limitation is because Vitess may try to execute a query for a value (for example 2.2) which MySQL will return zero results, even when the approximate value is present.

* It is not recommended to change the schema at the same time a resharding operation is being performed. This limitation exists because interpreting RBR events requires accurate knowledge of the table's schema, and Vitess does not always correctly handle the case that the schema has changed.