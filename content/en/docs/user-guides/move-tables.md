---
title: MoveTables
weight: 6
---

{{< info >}}
This guide follows on from the Get Started guides. Please make sure that you have either a [Kubernetes (helm)](../../get-started/kubernetes) or [local](../../get-started/local) installation ready.
{{< /info >}}

[MoveTables](../../concepts/move-tables) is a new VReplication workflow in Vitess 6, and obsoletes Vertical Split from earlier releases.

This feature enables you to move a subset of tables between keyspaces without downtime. For example, after [Initially deploying Vitess](../../get-started/local), your single commerce schema may grow so large that it needs to be split into multiple keyspaces.

As a stepping stone towards splitting a single table across multiple servers (sharding), it usually makes sense to first split from having a single monolithic keyspace (`commerce`) to having multiple keyspaces (`commerce` and `customer`). For example, in our ecommerce system we know that `customer` and `corder` tables are closely related and growing at a high rate just by themselves.

Let's start by simulating this situation by loading sample data:

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

## Create new tablets

The first step in our MoveTables operation is to deploy new tablets for our `customer` keyspace. By convention, we are going to use the UIDs 200-202 as the `commerce` keyspace previously used `100-102`. Once the tablets have started, we can force the first tablet to be the master using the `-force` flag:

#### Using Kubernetes (Helm)

```sh
helm upgrade vitess ../../helm/vitess/ -f 201_customer_tablets.yaml
```

After a few minutes the pods should appear running:

```sh
$ kubectl get pods,jobs
NAME                                           READY   STATUS      RESTARTS   AGE
pod/vtctld-6f955957bb-jp2t2                    1/1     Running     0          18m
pod/vtgate-zone1-86b7cb87d6-nsmw4              1/1     Running     3          18m
pod/zone1-commerce-0-init-shard-master-d5vj4   0/1     Completed   0          18m
pod/zone1-commerce-0-replica-0                 6/6     Running     0          18m
pod/zone1-commerce-0-replica-1                 6/6     Running     0          18m
pod/zone1-commerce-0-replica-2                 6/6     Running     0          18m
pod/zone1-customer-0-init-shard-master-xhzsr   0/1     Completed   0          89s
pod/zone1-customer-0-replica-0                 6/6     Running     0          89s
pod/zone1-customer-0-replica-1                 6/6     Running     0          89s
pod/zone1-customer-0-replica-2                 6/6     Running     0          89s

NAME                                           COMPLETIONS   DURATION   AGE
job.batch/zone1-commerce-0-init-shard-master   1/1           100s       18m
job.batch/zone1-customer-0-init-shard-master   1/1           17s        89s
```

#### Using a Local Deployment

```sh
for i in 200 201 202; do
 CELL=zone1 TABLET_UID=$i ./scripts/mysqlctl-up.sh
 CELL=zone1 KEYSPACE=customer TABLET_UID=$i ./scripts/vttablet-up.sh
done

vtctlclient InitShardMaster -force customer/0 zone1-200
```

__Note:__ This change does not change the actual routing yet. We will use a _switch_ directive to achieve that shortly.

## Start the Move

In this step we will initiate the MoveTables, which copies tables from the commerce keyspace into customer. This operation does not block any database activity; the MoveTables operation is performed online:

```sh
vtctlclient MoveTables -workflow=commerce2customer commerce customer '{"customer":{}, "corder":{}}'
```

## Phase 1: Switch Reads

Once the MoveTables operation is complete, the first step in making the changes live is to _switch_ `SELECT` statements to read from the new keyspace. Other statements will continue to route to the `commerce` keyspace. By staging this as two operations, Vitess allows you to test the changes and reduce the associated risks. For example, you may have a different configuration of hardware or software on the new keyspace.

```sh
vtctlclient SwitchReads -tablet_type=rdonly customer.commerce2customer
vtctlclient SwitchReads -tablet_type=replica customer.commerce2customer
```

## Phase 2: Switch Writes

After the reads have been _switched_, and you have verified that the system is operating as expected, it is time to _switch_ the write operations. The command to execute the switch is very similar to switching reads:

```sh
vtctlclient SwitchWrites customer.commerce2customer
```

We can then verify that both reads and writes go to the new keyspace:

```sh
# Works
mysql --table < ../common/select_customer0_data.sql

# Expected to Fail!
mysql --table < ../common/select_commerce_data.sql
```

## Cleanup

The final step is to remove the data from the original keyspace. As well as freeing space on the original tablets, this is an important step to eliminate potential future confusions. If you have a misconfiguration down the line and accidentally route queries for the  `customer` and `corder` tables to `commerce`, it is much better to return a "table not found" error, rather than return stale data:

```sh
vtctlclient SetShardTabletControl -blacklisted_tables=customer,corder -remove commerce/0 rdonly
vtctlclient SetShardTabletControl -blacklisted_tables=customer,corder -remove commerce/0 replica
vtctlclient SetShardTabletControl -blacklisted_tables=customer,corder -remove commerce/0 master
vtctlclient ApplySchema -sql-file drop_commerce_tables.sql commerce
vtctlclient ApplyRoutingRules -rules='{}'
```

After this step is complete, you should see the following error:

```sh
# Expected to fail!
mysql --table < ../common/select_commerce_data.sql
```

This confirms that the data has been correctly cleaned up.

## Next Steps

Congratulations! You've sucessfully moved tables between keyspaces. The next step to try out is to shard one of your keyspaces in [Resharding](../resharding).
