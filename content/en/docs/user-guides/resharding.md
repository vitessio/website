---
title: Resharding
weight: 7
---

{{< info >}}
This guide follows on from [MoveTables](../../user-guides/move-tables) and [Get Started with a Local deployment](../../get-started/local). It assumes that several scripts have been executed, and you have a running Vitess cluster.
{{< /info >}}

## Preparation

Resharding enables you to both _initially shard_ and reshard tables so that your keyspace is partitioned across several underlying [tablets](../../concept/tablet). A sharded keyspace has some additional restrictions on both [query syntax](../../reference/mysql-compatibility) and features such as `auto_increment`, so it is helpful to plan out a reshard operation diligently. However, you can always _reshard again_ if your sharding scheme turns out to be suboptimal.

Using our example commerce and customer keyspaces, lets work through the two most common issues.

### Sequences

### Vindexes

## Apply VSchema

Apply vschema:

```
# Example 301_customer_sharded.sh

vtctlclient -server localhost:15999 ApplySchema -sql-file create_commerce_seq.sql commerce
vtctlclient -server localhost:15999 ApplyVSchema -vschema_file vschema_commerce_seq.json commerce
vtctlclient -server localhost:15999 ApplySchema -sql-file create_customer_sharded.sql customer
vtctlclient -server localhost:15999 ApplyVSchema -vschema_file vschema_customer_sharded.json customer
```

## Create new shards

At this point, you have finalized your sharded VSchema and vetted all the queries to make sure they still work. Now, it’s time to reshard.

The resharding process works by splitting existing shards into smaller shards. This type of resharding is the most appropriate for Vitess. There are some use cases where you may want topin up a new shard and add new rows in the most recently created shard. This can be achieved in Vitess by splitting a shard in such a way that no rows end up in the ‘new’ shard. However, it's not natural for Vitess. We have to create the new target shards:

```
# Example 302_new_shards.sh

source ./env.sh

for i in 300 301 302; do
 CELL=zone1 TABLET_UID=$i ./scripts/mysqlctl-up.sh
 SHARD=-80 CELL=zone1 KEYSPACE=customer TABLET_UID=$i ./scripts/vttablet-up.sh
done

for i in 400 401 402; do
 CELL=zone1 TABLET_UID=$i ./scripts/mysqlctl-up.sh
 SHARD=80- CELL=zone1 KEYSPACE=customer TABLET_UID=$i ./scripts/vttablet-up.sh
done

vtctlclient -server localhost:15999 InitShardMaster -force customer/-80 zone1-300
vtctlclient -server localhost:15999 InitShardMaster -force customer/80- zone1-400
```

### Shard naming

What is the meaning of `-80` and `80-`? The shard names have the following characteristics:

* They represent a range, where the left number is included, but the right is not.
* Their notation is hexadecimal.
* They are left justified.
* A `-` prefix means: anything less than the RHS value.
* A `-` postfix means: anything greater than or equal to the LHS value.
* A plain `-` denotes the full keyrange.

What does this mean: `-80` == `00-80` == `0000-8000` == `000000-800000`

`80-` is not the same as `80-FF`. This is why:

`80-FF` == `8000-FF00`. Therefore `FFFF` will be out of the `80-FF` range.

`80-` means: ‘anything greater than or equal to `0x80`

A `hash` vindex produces an 8-byte number. This means that all numbers less than `0x8000000000000000` will fall in shard `-80`. Any number with the highest bit set will be >= `0x8000000000000000`, and will therefore belong to shard `80-`.

This left-justified approach allows you to have keyspace ids of arbitrary length. However, the most significant bits are the ones on the left.

For example an `md5` hash produces 16 bytes. That can also be used as a keyspace id.

A `varbinary` of arbitrary length can also be mapped as is to a keyspace id. This is what the `binary` vindex does.

In the above case, we are essentially creating two shards: any keyspace id that does not have its leftmost bit set will go to `-80`. All others will go to `80-`.

Applying the above change should result in the creation of six more vttablet instances.

At this point, the tables have been created in the new shards but have no data yet.

``` sql
mysql --table < ../common/select_customer-80_data.sql
Using customer/-80
Customer
COrder
mysql --table < ../common/select_customer80-_data.sql
Using customer/80-
Customer
COrder
```

## Start the Reshard

```
source ./env.sh

vtctlclient \
    -server localhost:15999 \
    -log_dir "$VTDATAROOT"/tmp \
    -alsologtostderr \
    Reshard \
    customer.cust2cust "0" "-80,80-"

sleep 2
```

## Switch Reads

```
# Example 304_switch_reads.sh

vtctlclient \
 -server localhost:15999 \
 -log_dir "$VTDATAROOT"/tmp \
 -alsologtostderr \
 SwitchReads \
 -tablet_type=rdonly \
 customer.cust2cust

vtctlclient \
 -server localhost:15999 \
 -log_dir "$VTDATAROOT"/tmp \
 -alsologtostderr \
 SwitchReads \
 -tablet_type=replica \
 customer.cust2cust
```

## Switch Writes

```
# Example 305_switch_writes.sh

vtctlclient \
 -server localhost:15999 \
 -log_dir "$VTDATAROOT"/tmp \
 -alsologtostderr \
 SwitchWrites \
 customer.cust2cust
```

You should now be able to see the data that has been copied over to the new shards:


``` sh
mysql --table < ../common/select_customer-80_data.sql
Using customer/-80
Customer
+-------------+--------------------+
| customer_id | email              |
+-------------+--------------------+
|           1 | alice@domain.com   |
|           2 | bob@domain.com     |
|           3 | charlie@domain.com |
|           5 | eve@domain.com     |
+-------------+--------------------+
COrder
+----------+-------------+----------+-------+
| order_id | customer_id | sku      | price |
+----------+-------------+----------+-------+
|        1 |           1 | SKU-1001 |   100 |
|        2 |           2 | SKU-1002 |    30 |
|        3 |           3 | SKU-1002 |    30 |
|        5 |           5 | SKU-1002 |    30 |
+----------+-------------+----------+-------+

mysql --table < ../common/select_customer80-_data.sql
Using customer/80-
Customer
+-------------+----------------+
| customer_id | email          |
+-------------+----------------+
|           4 | dan@domain.com |
+-------------+----------------+
COrder
+----------+-------------+----------+-------+
| order_id | customer_id | sku      | price |
+----------+-------------+----------+-------+
|        4 |           4 | SKU-1002 |    30 |
+----------+-------------+----------+-------+
```


## Cleanup

After celebrating your second successful resharding, you are now ready to clean up the leftover artifacts:

``` sh
# Examples 306_down_shard_0.sh

for i in 200 201 202; do
 CELL=zone1 TABLET_UID=$i ./scripts/vttablet-down.sh
 CELL=zone1 TABLET_UID=$i ./scripts/mysqlctl-down.sh
done

```

In this script, we just stopped all tablet instances for shard 0. This will cause all those vttablet and `mysqld` processes to be stopped. But the shard metadata is still present. We can clean that up with this command (after all vttablets have been brought down):

``` sh
# Examples 307_delete_shard_0.sh

vtctlclient -server localhost:15999 DeleteShard -recursive customer/0
```

Beyond this, you will also need to manually delete the disk associated with this shard.


## Next Steps

Feel free to experiment with your Vitess cluster! Execute the following when you are ready to teardown your example:

``` bash
./401_teardown.sh
```
