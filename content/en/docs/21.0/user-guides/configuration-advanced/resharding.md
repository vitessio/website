---
title: Resharding
weight: 15
aliases: ['/docs/user-guides/resharding/']
---

{{< info >}}
This guide follows on from the Get Started guides. Please make sure that you have
an [Operator](../../../get-started/operator) or [local](../../../get-started/local) installation ready. It also assumes
that the [MoveTables](../../migration/move-tables/) user guide has been followed (which take you through
steps `101`-`205` and more).
{{< /info >}}

## Preparation

[Sharding](../../../concepts/shard) enables you to both _initially shard_ or partition your data as well as reshard
your tables — as your data set size grows over time — so that your [keyspace](../../../concepts/keyspace/) is
partitioned across several underlying [tablets](../../../concepts/tablet). A sharded keyspace has some additional
restrictions on both [query syntax](../../../reference/compatibility/mysql-compatibility) and features such as
`auto_increment`, so it is helpful to plan out a reshard operation diligently. However, you can always
_reshard again_ later if your sharding scheme turns out to be suboptimal.

Using our example `commerce` and `customer` keyspaces, lets work through the two most common issues.

### Sequences

The first issue to address is the fact that customer and corder have auto-increment columns. This scheme does not work
well in a sharded setup. Instead, Vitess provides an equivalent feature called [sequences](../../../reference/features/vitess-sequences/).

The sequence table is an unsharded single row table that Vitess can use to generate monotonically increasing IDs.
The syntax to generate IDs is: `select next value from customer_seq` or `select next N values from customer_seq`.
The `vttablet` that exposes this table is capable of serving a very large number of such IDs because values are
reserved in chunks, then cached and served from memory. The chunk/cache size is configurable via the [`cache`
value](../../../reference/features/vitess-sequences/#initializing-a-sequence).

The VSchema allows you to associate the column of a table with the sequence table. Once this is done, an `INSERT`
on that table transparently fetches an ID from the sequence table, fills in the value in the new row, and then
routes the row to the appropriate shard. This makes the construct backward compatible to how [MySQL's
`auto_increment`](https://dev.mysql.com/doc/refman/en/example-auto-increment.html) works.

Since sequences table must be unsharded, they will be stored in the unsharded `commerce` keyspace. Here is the
schema used:

```sql
CREATE TABLE customer_seq (id int, next_id bigint, cache bigint, primary key(id)) comment 'vitess_sequence';
INSERT INTO customer_seq (id, next_id, cache) VALUES (0, 1000, 100);
CREATE TABLE order_seq (id int, next_id bigint, cache bigint, primary key(id)) comment 'vitess_sequence';
INSERT INTO order_seq (id, next_id, cache) VALUES (0, 1000, 100);
```

</br>

Note the `vitess_sequence` comment in the create table statement. VTTablet will use this metadata to treat this
table as a sequence. About the values we specified above:

* `id` is always 0
* `next_id` is set to `1000`: the value should be comfortably greater than the max `auto_increment` used so far.
* `cache` specifies the number of values to reserve and cache before the primary `vttablet` for the `commerce`
keyspace updates `next_id` to reserve and cache the next chunk of IDs.

Larger cache values perform better but can exhaust the available values more quickly since e.g. during reparent
operations the new PRIMARY `vttablet` will start off at the `next_id` value and any unused values from the
previously reserved chunk are lost.

The [VTGate servers](../../../concepts/vtgate/) also need to know about the sequence tables. This is done by
updating the [VSchema](../../../concepts/vschema/) for the `commerce` keyspace as follows:

```json
{
  "tables": {
    "customer_seq": {
      "type": "sequence"
    },
    "order_seq": {
      "type": "sequence"
    },
    "product": {}
  }
}
```

### Vindexes

The next decision is about the sharding keys or
[Primary Vindexes](../../../reference/features/vindexes/#the-primary-vindex). This is a complex decision
that involves the following considerations:

* What are the highest QPS queries, and what are the `WHERE` clauses for them?
* Cardinality of the column — it must be high.
* Do we want some rows to live together to support in-shard joins (data locality)?
* Do we want certain rows that will be in the same transaction to live together (data locality)?

Using the above considerations, in our use case, we can determine the following:

* For the customer table, the most common `WHERE` clause uses `customer_id`. So `customer_id` is declared as the
  [Primary Vindex](../../../reference/features/vindexes/#the-primary-vindex) for that table.
* Given that the customer table has a lot of rows, its cardinality is also high.
* For the corder table, we have a choice between `customer_id` and `order_id`. Given that our app joins `customer`
  with `corder` quite often on the `customer_id` column, it will be beneficial to choose `customer_id` as the Primary
  Vindex for the `corder` table as well so that we have data locality for those joins and can avoid costly cross-shard operations.
* Coincidentally, transactions also update `corder` tables with their corresponding `customer` rows. This further
  reinforces the decision to use `customer_id` as Primary Vindex.

There are a couple of other considerations which are out of scope for now, but worth mentioning:

* It may also be worth creating a [secondary lookup Vindex](../../../reference/features/vindexes/#secondary-vindexes)
on `corder.order_id`.
* Sometimes the `customer_id` is really a `tenant_id`. For example, if your application is a SaaS, which serves tenants
that themselves have customers. One key consideration here is that the sharding by the `tenant_id` can lead to
unbalanced shards. You may also need to consider sharding by the tenant's `customer_id`.

Putting it all together, we have a VSchema similar to the following for the `customer` keyspace:

```json
{
  "sharded": true,
  "vindexes": {
    "hash": {
      "type": "hash"
    }
  },
  "tables": {
    "customer": {
      "column_vindexes": [
        {
          "column": "customer_id",
          "name": "hash"
        }
      ],
      "auto_increment": {
        "column": "customer_id",
        "sequence": "customer_seq"
      }
    },
    "corder": {
      "column_vindexes": [
        {
          "column": "customer_id",
          "name": "hash"
        }
      ],
      "auto_increment": {
        "column": "order_id",
        "sequence": "order_seq"
      }
    }
  }
}
```

</br>

Since the primary vindex columns here use the
[`BIGINT` MySQL integer type](https://dev.mysql.com/doc/refman/en/integer-types.html), we choose `hash` as
the primary [vindex type](../../../reference/features/vindexes/#predefined-vindexes), which is a pseudo-random
way of distributing rows into various shards. For other data types we would typically use a different vindex
type:

* For `VARCHAR` columns, use `unicode_loose_xxhash`.
* For `VARBINARY`, use `xxhash`.
* Vitess uses a plugin system to define vindexes. If none of the
[predefined vindexes](../../../reference/features/vindexes/#predefined-vindexes) suit your needs, you can
develop your own custom vindex.

## Apply VSchema

Applying the new VSchema instructs Vitess that the keyspace is sharded, which may prevent some complex queries. It is a
good idea to [validate this](../../sql/vtexplain) before proceeding with this step. If you do notice that certain
queries start failing, you can always revert temporarily by restoring the old VSchema. Make sure you fix all of the
queries before proceeding to the [Reshard](../../../reference/vreplication/reshard/) process.

### Using Operator

```bash
vtctldclient ApplySchema --sql="$(cat create_commerce_seq.sql)" commerce
vtctldclient ApplyVSchema --vschema="$(cat vschema_commerce_seq.json)" commerce
vtctldclient ApplyVSchema --vschema="$(cat vschema_customer_sharded.json)" customer
vtctldclient ApplySchema --sql="$(cat create_customer_sharded.sql)" customer
```

### Using a Local Deployment

```bash
vtctldclient ApplySchema --sql-file create_commerce_seq.sql commerce
vtctldclient ApplyVSchema --vschema-file vschema_commerce_seq.json commerce
vtctldclient ApplyVSchema --vschema-file vschema_customer_sharded.json customer
vtctldclient ApplySchema --sql-file create_customer_sharded.sql customer
```

## Create New Shards

At this point, you have finalized your sharded VSchema and vetted all the queries to make sure they still work. Now,
it’s time to reshard.

The resharding process works by splitting existing shards into smaller shards. This type of resharding is the most
appropriate for Vitess. There are some use cases where you may want to bring up a new shard and add new rows in the
most recently created shard. This can be achieved in Vitess by splitting a shard in such a way that no existing rows
end up in the new shard. However, it's not natural for Vitess. We now have to create the new target shards:

### Using Operator

```bash
kubectl apply -f 302_new_shards.yaml
```

</br>

Make sure that you restart the port-forward after you have verified with `kubectl get pods` that this operation has
completed:

```bash
killall kubectl
./pf.sh &
```

### Using a Local Deployment

```bash
./302_new_shards.sh
```

## Start the Reshard

Now we can start the [Reshard](../../../reference/vreplication/reshard/) operation. It occurs online, and
will not block any read or write operations to your database:

```bash
vtctldclient Reshard --target-keyspace customer --workflow cust2cust create --source-shards '0' --target-shards '-80,80-'
```

</br>

All of the command options and parameters for `Reshard` are listed in
our [reference page for Reshard](../../../reference/vreplication/reshard).

## Validate Correctness

After the reshard is complete, we can use [VDiff](../../../reference/vreplication/vdiff) to check data integrity and ensure our source and target shards are consistent:

```bash
$ vtctldclient VDiff --target-keyspace customer --workflow cust2cust create
VDiff 60fa5738-9bad-11ed-b6de-920702940ee0 scheduled on target shards, use show to view progress

$ vtctldclient VDiff --target-keyspace customer --workflow cust2cust show last
{
	"Workflow": "cust2cust",
	"Keyspace": "customer",
	"State": "completed",
	"UUID": "60fa5738-9bad-11ed-b6de-920702940ee0",
	"RowsCompared": 10,
	"HasMismatch": false,
	"Shards": "-80,80-",
	"StartedAt": "2023-01-24 06:07:27",
	"CompletedAt": "2023-01-24 06:07:28"
} 
```

## Switch Non-Primary Reads

After validating for correctness, the next step is to switch
[`REPLICA` and `RDONLY` targeted read operations](../../../reference/features/vschema/#tablet-types) to occur
at the new location. By switching targeted read operations first, we are able to verify that the new shard's
tablets are healthy and able to respond to requests:

```bash
vtctldclient Reshard --target-keyspace customer --workflow cust2cust SwitchTraffic --tablet-types=rdonly,replica
```

## Switch Writes and Primary Reads

After the [`REPLICA` and `RDONLY` targeted reads](../../../reference/features/vschema/#tablet-types) have been
switched, and the health of the system has been verified, it's time to switch writes and all default traffic:

```bash
vtctldclient Reshard --target-keyspace customer --workflow cust2cust SwitchTraffic
```

## Note

While we have switched tablet type targeted reads and writes separately in this example, you can also switch
all traffic at the same time. This is done by default as if you don't specify the `--tablet_types` parameter
then `SwitchTraffic` will start serving all traffic from the target for all tablet types.

You should now be able to see the data that has been copied over to the new shards (assuming you 
previously loaded this data in the [`MoveTable` user-guide](../../migration/move-tables/)):

```bash
$ mysql --table < ../common/select_customer-80_data.sql
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

$ mysql --table < ../common/select_customer80-_data.sql
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

## Finalize and Cleanup

After celebrating your second successful resharding, you are now ready to clean up the leftover artifacts:

### Using Operator

```bash
vtctldclient Reshard --target-keyspace customer --workflow cust2cust complete
```

After the workflow has completed, you can go ahead and remove the shard that is no longer required -

```bash
kubectl apply -f 306_down_shard_0.yaml
```

### Using a Local Deployment

```bash
vtctldclient Reshard --target-keyspace customer --workflow cust2cust complete

for i in 200 201 202; do
 CELL=zone1 TABLET_UID=$i ./scripts/vttablet-down.sh
 CELL=zone1 TABLET_UID=$i ./scripts/mysqlctl-down.sh
done

vtctldclient DeleteShards --recursive customer/0
```

</br>

These are the steps taken in the `306_down_shard_0.sh` and `307_delete_shard_0.sh` scripts. In the first script (`306`)
we stop all tablet instances for shard 0. This will cause all those `vttablet` and `mysqld` processes to be stopped.
In the second script (`307`) we delete the shard records from our Vitess cluster topology.
Beyond this, you will also want to manually delete the on-disk directories associated with this shard. With the local examples that would be:

```bash
rm -rf ${VTDATAROOT}/vt_000000020{0,1,2}/
```

## Next Steps

Congratulations! You have successfully resharded your customer keyspace into two shards. Now, let's learn how to take backups of your Vitess cluster.

* For Local Environment: If you are using a local machine, you can refer to the section on [Backups and Restore for Local Environment](../../operating-vitess/backup-and-restore/backup_and_restore_local) to perform backups and restorations.

* For Kubernetes Environment: If you are using Kubernetes, you can follow the instructions on [how to schedule backups](../../operating-vitess/backup-and-restore/scheduled-backups) to automate your backup processes.