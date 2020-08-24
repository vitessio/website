---
title: MoveTables
weight: 6
---

{{< info >}}
This guide follows on from the Get Started guides. Please make sure that you have an [Operator](../../get-started/operator), [local](../../get-started/local) or [Helm](../../get-started/helm) installation ready.
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
# On helm and local installs:
mysql --table < ../common/select_commerce_data.sql
# With operator:
mysql --table < select_commerce_data.sql

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

{{< tabs name="new-tablets-tabs" >}} 
{{% tab name="Operator" %}}

```bash
kubectl apply -f 201_customer_tablets.yaml
```

After a few minutes the pods should appear running:

```bash
$ kubectl get pods
NAME                                             READY   STATUS    RESTARTS   AGE
example-etcd-faf13de3-1                          1/1     Running   0          8m11s
example-etcd-faf13de3-2                          1/1     Running   0          8m11s
example-etcd-faf13de3-3                          1/1     Running   0          8m11s
example-vttablet-zone1-1250593518-17c58396       3/3     Running   1          2m20s
example-vttablet-zone1-2469782763-bfadd780       3/3     Running   1          7m57s
example-vttablet-zone1-2548885007-46a852d0       3/3     Running   1          7m47s
example-vttablet-zone1-3778123133-6f4ed5fc       3/3     Running   1          2m20s
example-zone1-vtctld-1d4dcad0-59d8498459-kdml8   1/1     Running   1          8m11s
example-zone1-vtgate-bc6cde92-6bd99c6888-csnkj   1/1     Running   2          8m11s
vitess-operator-8454d86687-4wfnc                 1/1     Running   0          22m
```

Make sure that you restart the port-forward after launching the pods has completed:

```bash
killall kubectl
./pf.sh &
```

{{% /tab %}}

{{% tab name="Local deployment" %}}
```bash
for i in 200 201 202; do
 CELL=zone1 TABLET_UID=$i ./scripts/mysqlctl-up.sh
 CELL=zone1 KEYSPACE=customer TABLET_UID=$i ./scripts/vttablet-up.sh
done

vtctlclient InitShardMaster -force customer/0 zone1-200
```

__Note:__ This change does not change the actual routing yet. We will use a _switch_ directive to achieve that shortly.
{{% /tab %}}
{{% tab name="Helm" %}}

```bash
helm upgrade vitess ../../helm/vitess/ -f 201_customer_tablets.yaml
```

After a few minutes the pods should appear running:

```bash
$ kubectl get pods,jobs
NAME                                           READY   STATUS      RESTARTS   AGE
pod/vtctld-58bd955948-pgz7k                    1/1     Running     0          5m36s
pod/vtgate-zone1-c7444bbf6-t5xc6               1/1     Running     3          5m36s
pod/zone1-commerce-0-init-shard-master-gshz9   0/1     Completed   0          5m35s
pod/zone1-commerce-0-replica-0                 2/2     Running     0          5m35s
pod/zone1-commerce-0-replica-1                 2/2     Running     0          5m35s
pod/zone1-commerce-0-replica-2                 2/2     Running     0          5m35s
pod/zone1-customer-0-init-shard-master-7w7rm   0/1     Completed   0          84s
pod/zone1-customer-0-replica-0                 2/2     Running     0          84s
pod/zone1-customer-0-replica-1                 2/2     Running     0          84s
pod/zone1-customer-0-replica-2                 2/2     Running     0          84s

NAME                                           COMPLETIONS   DURATION   AGE
job.batch/zone1-commerce-0-init-shard-master   1/1           90s        5m36s
job.batch/zone1-customer-0-init-shard-master   1/1           23s        84s
```

{{% /tab %}}
{{< /tabs >}}

## Start the Move

In this step we will initiate the MoveTables, which copies tables from the commerce keyspace into customer. This operation does not block any database activity; the MoveTables operation is performed online:

```bash
vtctlclient MoveTables -workflow=commerce2customer commerce customer '{"customer":{}, "corder":{}}'
```

## Validate Correctness

We can use VDiff to checksum the two sources and confirm they are consistent:

```bash
vtctlclient VDiff customer.commerce2customer
```

You should see output similar to the following:
```bash
Summary for corder: {ProcessedRows:5 MatchingRows:5 MismatchedRows:0 ExtraRowsSource:0 ExtraRowsTarget:0}
Summary for customer: {ProcessedRows:5 MatchingRows:5 MismatchedRows:0 ExtraRowsSource:0 ExtraRowsTarget:0}
```

## Phase 1: Switch Reads

Once the MoveTables operation is complete, the first step in making the changes live is to _switch_ `SELECT` statements to read from the new keyspace. Other statements will continue to route to the `commerce` keyspace. By staging this as two operations, Vitess allows you to test the changes and reduce the associated risks. For example, you may have a different configuration of hardware or software on the new keyspace.

```bash
vtctlclient SwitchReads -tablet_type=rdonly customer.commerce2customer
vtctlclient SwitchReads -tablet_type=replica customer.commerce2customer
```

## Phase 2: Switch Writes

After the reads have been _switched_, and you have verified that the system is operating as expected, it is time to _switch_ the write operations. The command to execute the switch is very similar to switching reads:

```bash
vtctlclient SwitchWrites customer.commerce2customer
```

## Drop Sources

The final step is to remove the data from the original keyspace. As well as freeing space on the original tablets, this is an important step to eliminate potential future confusions. If you have a misconfiguration down the line and accidentally route queries for the  `customer` and `corder` tables to `commerce`, it is much better to return a "table not found" error, rather than return stale data:

```sh
vtctlclient DropSources customer.commerce2customer
```

After this step is complete, you should see the following error:

```sh
# Expected to fail!
mysql --table < ../common/select_commerce_data.sql
```

This confirms that the data has been correctly cleaned up.

## Next Steps

Congratulations! You've sucessfully moved tables between keyspaces. The next step to try out is to shard one of your keyspaces in [Resharding](../resharding).
