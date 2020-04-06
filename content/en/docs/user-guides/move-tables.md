---
title: MoveTables
weight: 6
---

{{< info >}}
This guide follows on from [get started with a local deployment](../../get-started/local). It assumes that the `./101_initial_cluster.sh` script has been executed, and you have a running Vitess cluster.
{{< /info >}}

MoveTables is a new [VReplication](../../concepts/vreplication) workflow in Vitess 6, and obsoletes Vertical Split from earlier releases.

This feature enables you to move a subset of tables between keyspaces without downtime. For example, after [initially deploying Vitess](../../get-started/local) your single commerce schema may grow so large that it needs to be split into multiple keyspaces.

As a stepping stone towards horizontally sharding (splitting a single table across multiple servers), it usually makes sense to split from having a single monolithic keyspace (`commerce`) to having multiple keyspaces (`commerce` and `customer`) that match your access pattern. For example, in our ecommerce system we know that `customer` and `corder` tables are closely related and growing at a high rate just by themselves.

Lets start by simulating this situation by loading sample data:

```sql
mysql < ../common/insert_commerce_data.sql
```

We can look at what we just inserted:

```sh
mysql --table < ../common/select_commerce_data.sql
Using commerce/0
Customer
+-------------+--------------------+
| customer_id | email              |
+-------------+--------------------+
|           1 | alice@domain.com   |
|           2 | bob@domain.com     |
|           3 | charlie@domain.com |
|           4 | dan@domain.com     |
|           5 | eve@domain.com     |
+-------------+--------------------+
Product
+----------+-------------+-------+
| sku      | description | price |
+----------+-------------+-------+
| SKU-1001 | Monitor     |   100 |
| SKU-1002 | Keyboard    |    30 |
+----------+-------------+-------+
COrder
+----------+-------------+----------+-------+
| order_id | customer_id | sku      | price |
+----------+-------------+----------+-------+
|        1 |           1 | SKU-1001 |   100 |
|        2 |           2 | SKU-1002 |    30 |
|        3 |           3 | SKU-1002 |    30 |
|        4 |           4 | SKU-1002 |    30 |
|        5 |           5 | SKU-1002 |    30 |
+----------+-------------+----------+-------+
```

Notice that we are using keyspace `commerce/0` to select data from our tables.

## Planning to Move Tables

In this scenario, we are going to split the `commerce` keyspace into `commerce` and `customer` keyspaces. The tables `Customer` and `COrder` will be moved into the newly created keyspace, and the `Product` table will remain in the `commerce` keyspace. This operation is online, which means that it does not block either read or write operations to the tables, __except__ for a small window during the final cut-over.

We could have equally decided to keep the `Customer` and `COrder` tables in the `commerce` keyspace, and created a new keyspace to move our `Product` table into. Which makes more sense often depends on the specifics of your environment. If the `Product` table is much larger, it will take more time to move, but in doing so you might also be able to migrate to newer hardware which has more headroom before you need to perform additional operations such as sharding. Similarly, if the `Customer` and `COrder` tables are updated at a more frequent rate, then this could also increase the move time.

### Impact to Production Traffic

Another consideration in planning which tables to move is the modification rate. Internally a MoveTables operation is comprised of both a table copy and a subscription to all changes made to the table. Vitess uses batching to improve the performance of both table copying and applying subscription changes, but you should expect that tables with lighter modification rates to move faster.

During the active move process, data is copied from replicas instead of the master server. This helps ensure minimal production traffic impact.

During the `SwitchWrites` phase of the MoveTables operation, Vitess may be briefly unavailable. This unavailability is usually a few seconds, but will be higher in the event that your system has a high replication delay.

## Create new tablets

The first step in our MoveTables operation is to deploy new tablets for our `customer` keyspace. By convention, we are going to use the UIDs 200-202 as the `commerce` keyspace previously used `100-102`. Once the tablets have started, we can `-force` the first tablet to be the master:

```sh
# Example 201_customer_tablets.sh

source ./env.sh

for i in 200 201 202; do
 CELL=zone1 TABLET_UID=$i ./scripts/mysqlctl-up.sh
 CELL=zone1 KEYSPACE=customer TABLET_UID=$i ./scripts/vttablet-up.sh
done

vtctlclient -server localhost:15999 InitShardMaster -force customer/0 zone1-200
vtctlclient -server localhost:15999 ApplyVSchema -vschema '{ "tables": { "product": {} } }' commerce
vtctlclient -server localhost:15999 ApplyVSchema -vschema '{ "tables": { "customer": {}, "corder": {} } }' customer
```

The last two commands here set the VSchema. In our case, we need to tell VTGate that the `customer` keyspace will now contain the tables `customer` and `corder`. The `commerce` keyspace will continue to hold just the `Product` table.

__Note:__ This change does not change the actual routing yet. We will use a _switch_ directive to achieve that shortly.

## Start the Move

In this step we will initiate the MoveTables, which copies tables from the commerce keyspace into customer. This operation does not block any database activity; the MoveTables operation is performed online:

```sh
# Example 202_move_tables.sh

vtctlclient \
    -server localhost:15999 \
    -log_dir "$VTDATAROOT"/tmp \
    -alsologtostderr \
    MoveTables \
    -workflow=commerce2customer \
    commerce customer customer,corder

sleep 2
```

## Phase 1: Switch Reads

Once the MoveTables operation is complete, the first step in making the changes live is to _switch_ `SELECT` statements to read from the new keyspace. Other statements will continue to route to the `commerce` keyspace. By staging this as two operations, Vitess allows you to canary the changes and reduce the risks associated with changes. For example, you may have a different configuration of hardware or software on the new keyspace.

```sh
# Example 203_switch_reads.sh

vtctlclient \
 -server localhost:15999 \
 -log_dir "$VTDATAROOT"/tmp \
 -alsologtostderr \
 SwitchReads \
 -tablet_type=rdonly \
 customer.commerce2customer

vtctlclient \
 -server localhost:15999 \
 -log_dir "$VTDATAROOT"/tmp \
 -alsologtostderr \
 SwitchReads \
 -tablet_type=replica \
 customer.commerce2customer

```

## Phase 2: Switch Writes

After the reads have been _switched_, and you have verified that the system is operating as expected, it is time to _switch_ the write operations. The command to execute the switch is very similar to switching reads:

```sh
# Example 204_switch_writes.sh

vtctlclient \
 -server localhost:15999 \
 -log_dir "$VTDATAROOT"/tmp \
 -alsologtostderr \
 SwitchWrites \
 customer.commerce2customer

```

We can then verify that both reads and writes go to the new keyspace:

```sh
# Works
mysql --table < ../common/select_customer0_data.sql

# Expected to Fail!
mysql --table < ../common/select_commerce_data.sql
```

## Cleanup

The final step is to remove the data from the original keyspace. As well as freeing space on the original tablets, this is an important step to eliminate potential future confusions. If you have a misconfiguration down the line and accidentally route queries for the  `customer` and `corder` tables to `commerce`, it is much better to return a table not found error, rather than return stale data:

```sh
# Example 205_clean_commerce.sh

vtctlclient -server localhost:15999 ApplySchema -sql-file drop_commerce_tables.sql commerce
vtctlclient -server localhost:15999 SetShardTabletControl -blacklisted_tables=customer,corder -remove commerce/0 rdonly
vtctlclient -server localhost:15999 SetShardTabletControl -blacklisted_tables=customer,corder -remove commerce/0 replica
vtctlclient -server localhost:15999 SetShardTabletControl -blacklisted_tables=customer,corder -remove commerce/0 master

```

After this step is complete, you should see the following error:

```sh
# Expected to fail!
mysql -h 127.0.0.1 -P 15306 --table < ../common/select_commerce_data.sql
```

This confirms that the data has been correctly cleaned up.

## Next Steps

Congratulations! You've sucessfully moved tables between keyspaces. The next step to try out is to shard one of your keyspaces in [Resharding](../resharding).

Alternatively, if you would like to teardown your example:

``` bash
./401_teardown.sh
```
