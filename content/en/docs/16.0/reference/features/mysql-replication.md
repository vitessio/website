---
title: Replication
weight: 9
aliases: ['/docs/reference/row-based-replication/','/docs/reference/vitess-replication/','/docs/reference/mysql-replication/']
---

{{< warning >}}
Vitess requires the use of Row-Based Replication with GTIDs enabled. In addition, Vitess only supports the default `binlog_row_image` of `FULL`.
{{< /warning >}}

Vitess makes use of MySQL Replication for both high availability and to receive a feed of changes to database tables. This feed is then used in features such as [VReplication](../../vreplication/vreplication/), and to identify schema changes so that caches can be updated.

## Semi-Sync

Vitess strongly recommends the use of Semi-synchronous replication for High Availability. The characteristics of semi-sync are replication governed by the [Durability Policy](../../../user-guides/configuration-basic/durability_policy) configured for the keyspace. 
Some characteristics are shared by all the policies -

* Vitess configures the semi-sync timeout to essentially an unlimited number so that it will never fallback to asyncronous replication. This is important to prevent split brain (or alternate futures) in case of a network partition. If we can verify all replicas have stopped replicating, we know the old primary is not accepting writes, even if we are unable to contact the old primary itself.

* All pre-configured durability policies do not allow tablets of type rdonly to send semi-sync ACKs. This is intentional because rdonly tablets are not eligible to be promoted to primary, so Vitess avoids the case where a rdonly tablet is the single best candidate for election at the time of primary failure.

Having semi-sync enabled, gives you the property that, in case of primary failure, there is at least one other replica that has every transaction that was ever reported to clients as having completed. You can then wait for [VTOrc](../../../user-guides/configuration-basic/vtorc) to repair it, or ([manually](../../programs/vtctl/shards/#emergencyreparentshard) pick the replica that is farthest ahead in GTID position and promote that to be the new primary.

Thus, you can survive sudden primary failure without losing any transactions that were reported to clients as completed. In MySQL 5.7+, this guarantee is strengthened slightly to preventing loss of any transactions that were ever **committed** on the original primary, eliminating so-called [phantom reads](http://bugs.mysql.com/bug.php?id=62174).

On the other hand these behaviors also give a requirement that each shard must have at least 2 tablets with type *replica* (with addition of the primary that can be demoted to type *replica* this gives a minimum of 3 tablets with initial type *replica*). This will allow for the primary to have a semi-sync acker when one of the replica tablets is down for any reason (for a version update, machine reboot, schema swap or anything else).
These requirements will changed based on the durability policy.

With regard to replication lag, note that this does **not** guarantee there is always at least one replica from which queries will always return up-to-date results. Semi-sync guarantees that at least one replica has the transaction in its relay log, but it has not necessarily been applied yet. The only way Vitess guarantees a fully up-to-date read is to send the request to the primary.

## Database Schema Considerations

* Row-based replication requires that replicas have the same schema as the primary, and corruption will likely occur if the column order does not match. Earlier versions of Vitess which used Statement-Based replication recommended applying schema changes on replicas first, and then swapping their role to primary. This method is no longer recommended in favour of the use of Online-DDL. More information can be found [here](../../../user-guides/schema-changes).

* Using a column of type `FLOAT` or `DOUBLE` as part of a Primary Key is not supported. This limitation is because Vitess may try to execute a query for a value (for example 2.2) which MySQL will return zero results, even when the approximate value is present.

* It is not recommended to change the schema at the same time a resharding operation is being performed. This limitation exists because interpreting RBR events requires accurate knowledge of the table's schema, and Vitess does not always correctly handle the case that the schema has changed.
