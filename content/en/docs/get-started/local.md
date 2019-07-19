---
title: Run Vitess Locally
description: Instructions for using Vitess on your machine for testing purposes
weight: 3
featured: true
---

This guide covers installing Vitess locally for testing purposes, from pre-compiled binaries. We will launch 3 copies of `mysqld`, so it is recommended to have greater than 4GB RAM, as well as 20GB of available disk space.

## Install Packages

PlanetScale provides [weekly builds](https://github.com/planetscale/vitess-releases/releases) of Vitess for 64-bit Linux.

1. Download and extract the [latest `.tar.gz` release](https://github.com/planetscale/vitess-releases/releases) from GitHub.
2. Install MySQL:
```bash
# Apt based
sudo apt-get install mysql-server
# Yum based
sudo yum install mysql-server
```

_Vitess supports MySQL 5.6+ and MariaDB 10.0+. We recommend MySQL 5.7 if your installation method provides a choice._

## Disable AppArmor

We recommend that you uninstall or disable AppArmor. Some versions of MySQL come with default AppArmor configurations that the Vitess tools don't yet recognize. This causes various permission failures when Vitess initializes MySQL instances through the mysqlctl tool. This is an issue only in test environments. If AppArmor is necessary in production, you can configure the MySQL instances appropriately without using `mysqlctl`:

```bash
sudo service apparmor stop
sudo service apparmor teardown # safe to ignore if this errors
sudo update-rc.d -f apparmor remove
```

Reboot to be sure that AppArmor is fully disabled.

## Configure Environment

Add the following to your `.bashrc` file. Make sure to replace `/path/to/extracted-tarball` with the actual path to where you extracted the latest release file:

```bash
export VTROOT=/path/to/extracted-tarball
export VTTOP=$VTROOT
export MYSQL_FLAVOR=MySQL56
export VTDATAROOT=${HOME}/vtdataroot
export PATH=${VTROOT}/bin:${PATH}
```

You are now ready to start your first cluster!

## Start a single keyspace cluster

A [keyspace](../overview/concepts.md#keyspace) in Vitess is a logical database consisting of potentially multiple shards. For our first example, we are going to be using Vitess without sharding using a single keyspace. The file `101_initial_cluster.sh` is for example `1` phase `01`. Lets execute it now:

``` sh
cd examples/local
./101_initial_cluster.sh
```

You should see output similar to the following:

```bash
~/...vitess/examples/local> ./101_initial_cluster.sh
enter zk2 env
Starting zk servers...
Waiting for zk servers to be ready...
Started zk servers.
Configured zk servers.
enter zk2 env
Starting vtctld...
Access vtctld web UI at http://ryzen:15000
Send commands with: vtctlclient -server ryzen:15999 ...
enter zk2 env
Starting MySQL for tablet zone1-0000000100...
Starting MySQL for tablet zone1-0000000101...
Starting MySQL for tablet zone1-0000000102...
```

You can also verify that the processes have started with `pgrep`:

``` sh
~/...vitess/examples/local> pgrep -fl vtdataroot
5451 zksrv.sh
5452 zksrv.sh
5453 zksrv.sh
5463 java
5464 java
5465 java
5627 vtctld
5762 mysqld_safe
5767 mysqld_safe
5799 mysqld_safe
10162 mysqld
10164 mysqld
10190 mysqld
10281 vttablet
10282 vttablet
10283 vttablet
10447 vtgate
```

If you encounter any errors, such as ports already in use, you can kill the processes and start over:

```bash
pkill -f '(vtdataroot|VTDATAROOT)' # kill Vitess processes
```

## Connecting to your Cluster

You should now be able to connect to the cluster using the following command:

``` sh
~/...vitess/examples/local> mysql -h 127.0.0.1 -P 15306
Welcome to the MySQL monitor.  Commands end with ; or \g.
mysql> show tables;
+-----------------------+
| Tables_in_vt_commerce |
+-----------------------+
| corder                |
| customer              |
| product               |
+-----------------------+
3 rows in set (0.01 sec)
```

You can also browse to the vtctld console using the following URL:

``` sh
http://localhost:15000
```

### Topology

In this example, we use a single unsharded keyspace: `commerce`. Unsharded keyspaces have a single shard named `0`.

NOTE: keyspace/shards are global entities of a cluster, independent of a cell. Ideally, you should list the keyspace/shards separately. For a cell, you should only have to specify which of those keyspace/shards are deployed in that cell. However, for simplicity, the existence of keyspace/shards are implicitly inferred from the fact that they are mentioned under each cell.

In this deployment, we are requesting two `replica` type tables and one `rdonly` type tablet. When deployed, one of the `replica` tablet types will automatically be elected as master. In the vtctld console, you should see one `master`, one `replica` and one `rdonly` vttablets.

The purpose of a replica tablet is for serving OLTP read traffic, whereas rdonly tablets are for serving analytics, or performing cluster maintenance operations like backups, or resharding. rdonly replicas are allowed to lag far behind the master because replication needs to be stopped to perform some of these functions.

In our use case, we are provisioning one rdonly replica per shard in order to perform resharding operations.

### Schema

``` sql
create table product(
  sku varbinary(128),
  description varbinary(128),
  price bigint,
  primary key(sku)
);
create table customer(
  customer_id bigint not null auto_increment,
  email varbinary(128),
  primary key(customer_id)
);
create table corder(
  order_id bigint not null auto_increment,
  customer_id bigint,
  sku varbinary(128),
  price bigint,
  primary key(order_id)
);
```

The schema has been simplified to include only those fields that are significant to the example:
* The `product` table contains the product information for all of the products.
* The `customer` table has a `customer_id` that has an auto-increment. A typical customer table would have a lot more columns, and sometimes additional detail tables.
* The `corder` table (named so because `order` is an SQL reserved word) has an `order_id` auto-increment column. It also has foreign keys into `customer(customer_id)` and `product(sku)`.

### VSchema

Since Vitess is a distributed system, a VSchema (Vitess schema) is usually required to describe how the keyspaces are organized.

``` json
{
  "tables": {
    "product": {},
    "customer": {},
    "corder": {}
  }
}
```
With a single unsharded keyspace, the VSchema is very simple; it just lists all the tables in that keyspace.

NOTE: In the case of a single unsharded keyspace, a VSchema is not strictly necessary because Vitess knows that there are no other keyspaces, and will therefore redirect all queries to the only one present.

## Vertical Split

Due to a massive ingress of free-trade, single-origin yerba mate merchants to your website, hipsters are swarming to buy stuff from you. As more users flock to your website and app, the `customer` and `corder` tables start growing at an alarming rate. To keep up, you’ll want to separate those tables by moving `customer` and `corder` to their own keyspace. Since you only have as many products as there are types of yerba mate, you won’t need to shard the product table!

Let us add some data into our tables to illustrate how the vertical split works.

``` sql
mysql -h 127.0.0.1 -P 15306 < ../common/insert_commerce_data.sql
```

We can look at what we just inserted:

``` sh
mysql -h 127.0.0.1 -P 15306 --table < ../common/select_commerce_data.sql
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

### Create Keyspace

For a vertical split, we first need to create a special `served_from` keyspace. This keyspace starts off as an alias for the `commerce` keyspace. Any queries sent to this keyspace will be redirected to `commerce`. Once this is created, we can vertically split tables into the new keyspace without having to make the app aware of this change:

``` sh
./201_customer_keyspace.sh
```

This creates an entry into the topology indicating that any requests to master, replica, or rdonly sent to `customer` must be redirected to (served from) `commerce`. These tablet type specific redirects will be used to control how we transition the cutover from `commerce` to `customer`.

### Customer Tablets

Now you have to create vttablet instances to back this new keyspace onto which you’ll move the necessary tables:

``` sh
./202_customer_tablets.sh
```

The most significant change, this script makes is the instantiation of vttablets for the new keyspace. Additionally:

* You moved customer and corder from the commerce’s VSchema to customer’s VSchema. Note that the physical tables are still in commerce.
* You requested that the schema for customer and corder be copied to customer using the `copySchema` directive.

The move in the vschema should not be material yet because any queries sent to customer are still redirected to commerce, where all the data is still present.

### VerticalSplitClone

The next step:

``` sh
./203_vertical_split.sh
```

starts the process of migrating the data from commerce to customer.

For large tables, this job could potentially run for many days, and may be restarted if failed. This job performs the following tasks:

* Dirty copy data from commerce’s customer and corder tables to customer’s tables.
* Stop replication on commerce’s rdonly tablet and perform a final sync.
* Start a filtered replication process from commerce->customer that keeps the customer’s tables in sync with those in commerce.

NOTE: In production, you would want to run multiple sanity checks on the replication by running `SplitDiff` jobs multiple times before starting the cutover.

We can look at the results of VerticalSplitClone by examining the data in the customer keyspace. Notice that all data in the `customer` and `corder` tables has been copied over.

``` sh
mysql -h 127.0.0.1 -P 15306 --table < ../common/select_customer0_data.sql
Using customer/0
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

### Cut over

Once you have verified that the customer and corder tables are being continuously updated from commerce, you can cutover the traffic. This is typically performed in three steps: `rdonly`, `replica` and `master`:

For rdonly and replica:

``` sh
./204_vertical_migrate_replicas.sh
```

For master:

``` sh
./205_vertical_migrate_master.sh
```

Once this is done, the `customer` and `corder` tables are no longer accessible in the `commerce` keyspace. You can verify this by trying to read from them.

``` sql
mysql -h 127.0.0.1 -P 15306 --table < ../common/select_commerce_data.sql
Using commerce/0
Customer
ERROR 1105 (HY000) at line 4: vtgate: http://vtgate-zone1-5ff9c47db6-7rmld:15001/: target: commerce.0.master, used tablet: zone1-1564760600 (zone1-commerce-0-replica-0.vttablet), vttablet: rpc error: code = FailedPrecondition desc = disallowed due to rule: enforce blacklisted tables (CallerID: userData1)
```

The replica and rdonly cutovers are freely reversible. However, the master cutover is one-way and cannot be reversed. This is a limitation of vertical resharding, which will be resolved in the near future. For now, care should be taken so that no loss of data or availability occurs after the cutover completes.

### Clean up

After celebrating your first successful ‘vertical resharding’, you will need to clean up the leftover artifacts:

``` sh
./206_clean_commerce.sh
```

Those tables are now being served from customer. So, they can be dropped from commerce.

The ‘control’ records were added by the `MigrateServedFrom` command during the cutover to prevent the commerce tables from accidentally accepting writes. They can now be removed.

After this step, the `customer` and `corder` tables no longer exist in the `commerce` keyspace.

``` sql
mysql -h 127.0.0.1 -P 15306 --table < ../common/select_commerce_data.sql
Using commerce/0
Customer
ERROR 1105 (HY000) at line 4: vtgate: http://vtgate-zone1-5ff9c47db6-7rmld:15001/: target: commerce.0.master, used tablet: zone1-1564760600 (zone1-commerce-0-replica-0.vttablet), vttablet: rpc error: code = InvalidArgument desc = table customer not found in schema (CallerID: userData1)
```

## Horizontal sharding

The DBAs you hired with massive troves of hipster cash are pinging you on Slack and are freaking out. With the amount of data that you’re loading up in your keyspaces, MySQL performance is starting to tank - it’s okay, you’re prepared for this! Although the query guardrails and connection pooling are cool features that Vitess can offer to a single unsharded keyspace, the real value comes into play with horizontal sharding.

### Preparation

Before starting the resharding process, you need to make some decisions and prepare the system for horizontal resharding. Important note, this is something that should have been done before starting the vertical split. However, this is a good time to explain what normally would have been decided upon earlier the process.

#### Sequences

The first issue to address is the fact that customer and corder have auto-increment columns. This scheme does not work well in a sharded setup. Instead, Vitess provides an equivalent feature through sequences.

The sequence table is an unsharded single row table that Vitess can use to generate monotonically increasing ids. The syntax to generate an id is: `select next :n values from customer_seq`. The vttablet that exposes this table is capable of serving a very large number of such ids because values are cached and served out of memory. The cache value is configurable.

The VSchema allows you to associate a column of a table with the sequence table. Once this is done, an insert on that table transparently fetches an id from the sequence table, fills in the value, and routes the row to the appropriate shard. This makes the construct backward compatible to how mysql’s auto_increment column works.

Since sequences are unsharded tables, they will be stored in the commerce database. The schema:

``` sql
create table customer_seq(id int, next_id bigint, cache bigint, primary key(id)) comment 'vitess_sequence';
insert into customer_seq(id, next_id, cache) values(0, 1000, 100);
create table order_seq(id int, next_id bigint, cache bigint, primary key(id)) comment 'vitess_sequence';
insert into order_seq(id, next_id, cache) values(0, 1000, 100);
```

Note the `vitess_sequence` comment in the create table statement. VTTablet will use this metadata to treat this table as a sequence.

* `id` is always 0
* `next_id` is set to `1000`: the value should be comfortably greater than the auto_increment max value used so far.
* `cache` specifies the number of values to cache before vttablet updates `next_id`.

Higher cache values are more performant. However, cached values are lost if a reparent happens. The new master will start off at the `next_id` that was saved by the old master.

The VTGates also need to know about the sequence tables. This is done by updating the vschema for commerce as follows:

``` json
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

#### Vindexes

The next decision is about the sharding keys, aka Primary Vindexes. This is a complex decision that involves the following considerations:

* What are the highest QPS queries, and what are the where clauses for them?
* Cardinality of the column; it must be high.
* Do we want some rows to live together to support in-shard joins?
* Do we want certain rows that will be in the same transaction to live together?

Using the above considerations, in our use case, we can determine that:

* For the customer table, the most common where clause uses `customer_id`. So, it shall have a Primary Vindex.
* Given that it has lots of users, its cardinality is also high.
* For the corder table, we have a choice between `customer_id` and `order_id`. Given that our app joins `customer` with `corder` quite often on the `customer_id` column, it will be beneficial to choose `customer_id` as the Primary Vindex for the `corder` table as well.
* Coincidentally, transactions also update `corder` tables with their corresponding `customer` rows. This further reinforces the decision to use `customer_id` as Primary Vindex.

NOTE: It may be worth creating a secondary lookup Vindex on `corder.order_id`. This is not part of the example. We will discuss this in the advanced section.

NOTE: For some use cases, `customer_id` may actually map to a tenant_id. In such cases, the cardinality of a tenant id may be too low. It’s also common that such systems have queries that use other high cardinality columns in their where clauses. Those should then be taken into consideration when deciding on a good Primary Vindex.

Putting it all together, we have the following VSchema for `customer`:

``` json
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

Note that we have now marked the keyspace as sharded. Making this change will also change how Vitess treats this keyspace. Some complex queries that previously worked may not work anymore. This is a good time to conduct thorough testing to ensure that all the queries work. If any queries fail, you can temporarily revert the keyspace as unsharded. You can go back and forth until you have got all the queries working again.

Since the primary vindex columns are `BIGINT`, we choose `hash` as the primary vindex, which is a pseudo-random way of distributing rows into various shards.

NOTE: For `VARCHAR` columns, use `unicode_loose_md5`. For `VARBINARY`, use `binary_md5`.

NOTE: All vindexes in Vitess are plugins. If none of the predefined vindexes suit your needs, you can develop your own custom vindex.

Now that we have made all the important decisions, it’s time to apply these changes:

``` sh
./301_customer_sharded.sh
```

The jobs to watch for:
TODO(jiten): Add grep command here.


### Create new shards

At this point, you have finalized your sharded vschema and vetted all the queries to make sure they still work. Now, it’s time to reshard.

The resharding process works by splitting existing shards into smaller shards. This type of resharding is the most appropriate for Vitess. There are some use cases where you may want to spin up a new shard and add new rows in the most recently created shard. This can be achieved in Vitess by splitting a shard in such a way that no rows end up in the ‘new’ shard. However, it’s not natural for Vitess.

We have to create the new target shards:

``` sh
./302_new_shards.sh
```

Shard 0 was already there. We have now added shards `-80` and `80-`. We’ve also added the `CopySchema` directive which requests that the schema from shard 0 be copied into the new shards.

#### Shard naming

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
mysql -h 127.0.0.1 -P 15306 --table < ../common/select_customer-80_data.sql
Using customer/-80
Customer
COrder
mysql -h 127.0.0.1 -P 15306 --table < ../common/select_customer80-_data.sql
Using customer/80-
Customer
COrder
```

### SplitClone

The process for SplitClone is similar to VerticalSplitClone. It starts the horizontal resharding process:

``` sh
./303_horizontal_split.sh
```

This starts the following job "SplitClone -min_healthy_rdonly_tablets=1 customer/0":

For large tables, this job could potentially run for many days, and can be restarted if failed. This job performs the following tasks:

* Dirty copy data from customer/0 into the two new shards. But rows are split based on their target shards.
* Stop replication on customer/0 rdonly tablet and perform a final sync.
* Start a filtered replication process from customer/0 into the two shards by sending changes to one or the other shard depending on which shard the rows belong to.

Once `SplitClone` has completed, you should see this:

The horizontal counterpart to `VerticalSplitDiff` is `SplitDiff`. It can be used to validate the data integrity of the resharding process "SplitDiff -min_healthy_rdonly_tablets=1 customer/-80":

NOTE: This example does not actually run this command.

Note that the last argument of SplitDiff is the target (smaller) shard. You will need to run one job for each target shard. Also, you cannot run them in parallel because they need to take an `rdonly` instance offline to perform the comparison.

NOTE: SplitDiff can be used to split shards as well as to merge them.

### Cut over

Now that you have verified that the tables are being continuously updated from the source shard, you can cutover the traffic. This is typically performed in three steps: `rdonly`, `replica` and `master`:

For rdonly and replica:

``` sh
./304_migrate_replicas.sh
```

For master:

``` sh
./305_migrate_master.sh
```

During the *master* migration, the original shard master will first stop accepting updates. Then the process will wait for the new shard masters to fully catch up on filtered replication before allowing them to begin serving. Since filtered replication has been following along with live updates, there should only be a few seconds of master unavailability.

The replica and rdonly cutovers are freely reversible. Unlike the Vertical Split, a horizontal split is also reversible. You just have to add a `-reverse_replication` flag while cutting over the master. This flag causes the entire resharding process to run in the opposite direction, allowing you to Migrate in the other direction if the need arises.

You should now be able to see the data that has been copied over to the new shards.

``` sh
mysql -h 127.0.0.1 -P 15306 --table < ../common/select_customer-80_data.sql
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

mysql -h 127.0.0.1 -P 15306 --table < ../common/select_customer80-_data.sql
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

### Clean up

After celebrating your second successful resharding, you are now ready to clean up the leftover artifacts:

``` sh
./306_down_shard_0.sh
```

In this script, we just stopped all tablet instances for shard 0. This will cause all those vttablet and mysqld processes to be stopped. But the shard metadata is still present. We can clean that up with this command (after all vttablets have been brought down):

``` sh
./307_delete_shard_0.sh
```

This command runs the following "`DeleteShard -recursive customer/0`".

Beyond this, you will also need to manually delete the disk associated with this shard.

### Teardown (optional)

You can delete the whole example if you are not proceeding to another exercise:

``` sh
./401_teardown.sh
```
