---
title: Run Vitess on Kubernetes
weight: 3
featured: true
aliases: ['/docs/tutorials/kubernetes/']
---

*The following example will use a simple commerce database to illustrate how Vitess can take you through the journey of scaling from a single database to a fully distributed and sharded cluster. This is a fairly common story, and it applies to many use cases beyond e-commerce.*

It’s 2019 and, no surprise to anyone, people are still buying stuff online. You recently attended the first half of a seminar on disruption in the tech industry and want to create a completely revolutionary e-commerce site. In classic tech postmodern fashion, you call your products widgets instead of a more meaningful identifier and it somehow fits.

Naturally, you realize the need for a reliable transactional datastore. Because of the new generation of hipsters, you’re probably going to pull traffic away from the main industry players just because you’re not them. You’re smart enough to foresee the scalability you need, so you choose Vitess as your best scaling solution.

### Prerequisites

Before we get started, let’s get a few things out of the way.

{{< info >}}
The example settings have been tuned to run on Minikube. However, you should be able to try this on your own Kubernetes cluster. If you do, you may also want to remove some of the Minikube specific resource settings (explained below).
{{< /info >}}

* [Download Vitess](https://github.com/vitessio/vitess)
* [Install Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)
* Start a Minikube engine: `minikube start --cpus=4 --memory=5000`. Note the additional resource requirements. In order to go through all the use cases, many vttablet and MySQL instances will be launched. These require more resources than the defaults used by Minikube.
* [Install etcd operator](https://github.com/coreos/etcd-operator/blob/master/doc/user/install_guide.md)
* [Install helm](https://docs.helm.sh/using_helm/)
* After installing, run `helm init`

### Optional

* Install the MySQL client. On Ubuntu: `apt-get install mysql-client`
* Install vtctlclient
    * Install go 1.11+
    * `go get vitess.io/vitess/go/cmd/vtctlclient`
    * vtctlclient will be installed at `$GOPATH/bin/`

## Starting a single keyspace cluster

So you searched keyspace on Google and got a bunch of stuff about NoSQL… what’s the deal? It took a few hours, but after diving through the ancient Vitess scrolls you figure out that in the NewSQL world, keyspaces and databases are essentially the same thing when unsharded. Finally, it’s time to get started.

Change to the helm example directory:

``` sh
cd examples/helm
```

In this directory, you will see a group of yaml files. The first digit of each file name indicates the phase of example. The next two digits indicate the order in which to execute them. For example, ‘101_initial_cluster.yaml’ is the first file of the first phase. We shall execute that now:

``` sh
helm install ../../helm/vitess -f 101_initial_cluster.yaml
```

This will bring up the initial Vitess cluster with a single keyspace.

### Verify cluster

Once successful, you should see the following state:

``` sh
~/...vitess/helm/vitess/templates> kubectl get pods,jobs
NAME                               READY     STATUS    RESTARTS   AGE
po/etcd-global-2cwwqfkf8d          1/1       Running   0          14m
po/etcd-operator-9db58db94-25crx   1/1       Running   0          15m
po/etcd-zone1-btv8p7pxsg           1/1       Running   0          14m
po/vtctld-55c47c8b6c-5v82t         1/1       Running   1          14m
po/vtgate-zone1-569f7b64b4-zkxgp   1/1       Running   2          14m
po/zone1-commerce-0-rdonly-0       6/6       Running   0          14m
po/zone1-commerce-0-replica-0      6/6       Running   0          14m
po/zone1-commerce-0-replica-1      6/6       Running   0          14m

NAME                                      DESIRED   SUCCESSFUL   AGE
jobs/commerce-apply-schema-initial        1         1            14m
jobs/commerce-apply-vschema-initial       1         1            14m
jobs/zone1-commerce-0-init-shard-master   1         1            14m
```

If you have installed the the MySQL client, you should now be able to connect to the cluster using the following command:

``` sh
~/...vitess/examples/helm> ./kmysql.sh
mysql> show tables;
+--------------------+
| Tables_in_commerce |
+--------------------+
| corder             |
| customer           |
| product            |
+--------------------+
3 rows in set (0.01 sec)
```

You can also browse to the vtctld console using the following command (Ubuntu):

``` sh
./kvtctld.sh
```

### Minikube Customizations

The helm example is based on the `values.yaml` file provided as the default helm chart for Vitess. The following overrides have been performed in order to run under Minikube:

* `resources`: have been nulled out. This instructs the Kubernetes environment to use whatever is available. Note, this is not recommended for a production environment. In such cases, you should start with the baseline values provided in `helm/vitess/values.yaml` and iterate from those.
* etcd and VTGate replicas are set to 1. In a production environment, there should be 3-5 etcd replicas. The number of VTGate servers will need to scale up based on cluster size.
* `mysqlProtocol.authType` is set to `none`. This should be changed to `secret` and the credentials should be stored as Kubernetes secrets.
* A serviceType of `NodePort` is not recommended in production. You may choose not to expose these end points to anyone outside Kubernetes at all. Another option is to create Ingress controllers.

### Topology

The helm chart specifies a single unsharded keyspace: `commerce`. Unsharded keyspaces have a single shard named `0`.

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
* The `customer` table has a customer_id that has an auto-increment. A typical customer table would have a lot more columns, and sometimes additional detail tables.
* The `corder` table (named so because `order` is an SQL reserved word) has an order_id auto-increment column. It also has foreign keys into customer(customer_id) and product(sku).

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

``` sh
./kmysql.sh < ../common/insert_commerce_data.sql
```

We can look at what we just inserted:

``` sh
./kmysql.sh --table < ../common/select_commerce_data.sql
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

For subsequent commands, it will be convenient to capture the name of the release and save into a variable:

``` sh
export release=$(helm ls -q)
```

For a vertical split, we first need to create a special `served_from` keyspace. This keyspace starts off as an alias for the `commerce` keyspace. Any queries sent to this keyspace will be redirected to `commerce`. Once this is created, we can vertically split tables into the new keyspace without having to make the app aware of this change:

``` sh
helm upgrade $release ../../helm/vitess/ -f 201_customer_keyspace.yaml
```

Looking into the yaml file, the only addition over the previous version is the following job:

``` yaml
jobs:
  - name: "create-customer-ks"
    kind: "vtctlclient"
    command: "CreateKeyspace -served_from='master:commerce,replica:commerce,rdonly:commerce' customer"
```

This creates an entry into the topology indicating that any requests to master, replica, or rdonly sent to `customer` must be redirected to (served from) `commerce`. These tablet type specific redirects will be used to control how we transition the cutover from `commerce` to `customer`.

A successful completion of this job should show up as:

``` sh
NAME                                      DESIRED   SUCCESSFUL   AGE
jobs/vtctlclient-create-customer-ks       1         1            10s
```

### Customer Tablets

Now you have to create vttablet instances to back this new keyspace onto which you’ll move the necessary tables:

``` sh
helm upgrade $release ../../helm/vitess/ -f 202_customer_tablets.yaml
```

This yaml also makes a few additional changes:

``` yaml
        - name: "commerce"
          shards:
            - name: "0"
              tablets:
                - type: "replica"
                  vttablet:
                    replicas: 2
                - type: "rdonly"
                  vttablet:
                    replicas: 1
          vschema:
            vsplit: |-
              {
                "tables": {
                  "product": {}
                }
              }
        - name: "customer"
          shards:
            - name: "0"
              tablets:
                - type: "replica"
                  vttablet:
                    replicas: 2
                - type: "rdonly"
                  vttablet:
                    replicas: 1
              copySchema:
                source: "commerce/0"
                tables:
                  - "customer"
                  - "corder"
          vschema:
            vsplit: |-
              {
                "tables": {
                  "customer": {},
                  "corder": {}
                }
              }
```

The most significant change, of course, is the instantiation of vttablets for the new keyspace. Additionally:

* You moved customer and corder from the commerce’s VSchema to customer’s VSchema. Note that the physical tables are still in commerce.
* You requested that the schema for customer and corder be copied to customer using the `copySchema` directive.

The move in the VSchema should not make a difference yet because any queries sent to customer are still redirected to commerce, where all the data is still present.

Upon completion of this step, there must be six running vttablet pods, and the following new jobs must have completed successfully:

``` sh
NAME                                      DESIRED   SUCCESSFUL   AGE
jobs/commerce-apply-vschema-vsplit        1         1            5m
jobs/customer-apply-vschema-vsplit        1         1            5m
jobs/customer-copy-schema-0               1         1            5m
jobs/zone1-customer-0-init-shard-master   1         1            5m
```

### VerticalSplitClone

The next step:

``` sh
helm upgrade $release ../../helm/vitess/ -f 203_vertical_split.yaml
```

starts the process of migrating the data from commerce to customer. The new content on this file is:

``` yaml
jobs:
  - name: "vertical-split"
    kind: "vtworker"
    cell: "zone1"
    command: "VerticalSplitClone -min_healthy_rdonly_tablets=1 -tables=customer,corder customer/0"
```

For large tables, this job could potentially run for many days, and may be restarted if failed. This job performs the following tasks:

* Dirty copy data from commerce’s customer and corder tables to customer’s tables.
* Stop replication on commerce’s rdonly tablet and perform a final sync.
* Start a filtered replication process from commerce->customer that keeps the customer’s tables in sync with those in commerce.


NOTE: In production, you would want to run multiple sanity checks on the replication by running `SplitDiff` jobs multiple times before starting the cutover:

``` yaml
jobs:
  - name: "vertical-split-diff"
    kind: "vtworker"
    cell: "zone1"
    command: "VerticalSplitDiff -min_healthy_rdonly_tablets=1 customer/0"
```

We can look at the results of VerticalSplitClone by examining the data in the customer keyspace. Notice that all data in the `customer` and `corder` tables has been copied over.

``` sh
./kmysql.sh --table < ../common/select_customer0_data.sql
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
helm upgrade $release ../../helm/vitess/ -f 204_vertical_migrate_replicas.yaml
```

For master:

``` sh
helm upgrade $release ../../helm/vitess/ -f 205_vertical_migrate_master.yaml
```

Once this is done, the `customer` and `corder` tables are no longer accessible in the `commerce` keyspace. You can verify this by trying to read from them.

``` sh
./kmysql.sh --table < ../common/select_commerce_data.sql
Using commerce/0
Customer
ERROR 1105 (HY000) at line 4: vtgate: http://vtgate-zone1-5ff9c47db6-7rmld:15001/: target: commerce.0.master, used tablet: zone1-1564760600 (zone1-commerce-0-replica-0.vttablet), vttablet: rpc error: code = FailedPrecondition desc = disallowed due to rule: enforce blacklisted tables (CallerID: userData1)
```

The replica and rdonly cutovers are freely reversible. However, the master cutover is one-way and cannot be reversed. This is a limitation of vertical resharding, which will be resolved in the near future. For now, care should be taken so that no loss of data or availability occurs after the cutover completes.

### Clean up

After celebrating your first successful ‘vertical resharding’, you will need to clean up the leftover artifacts:

``` sh
helm upgrade $release ../../helm/vitess/ -f 206_clean_commerce.yaml
```

You can see the following DML statements in commerce:

``` sql
            postsplit: |-
              drop table customer;
              drop table corder;
```

Those tables are now being served from customer. So, they can be dropped from commerce.

``` yaml
jobs:
  - name: "vclean1"
    kind: "vtctlclient"
    command: "SetShardTabletControl -blacklisted_tables=customer,corder -remove commerce/0 rdonly"
  - name: "vclean2"
    kind: "vtctlclient"
    command: "SetShardTabletControl -blacklisted_tables=customer,corder -remove commerce/0 replica"
  - name: "vclean3"
    kind: "vtctlclient"
    command: "SetShardTabletControl -blacklisted_tables=customer,corder -remove commerce/0 master"
```

These ‘control’ records were added by the `MigrateServedFrom` command during the cutover to prevent the commerce tables from accidentally accepting writes. They can now be removed.

After this step, the `customer` and `corder` tables no longer exist in the `commerce` keyspace.

``` sh
./kmysql.sh --table < ../common/select_commerce_data.sql
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

The VSchema allows you to associate a column of a table with the sequence table. Once this is done, an insert on that table transparently fetches an id from the sequence table, fills in the value, and routes the row to the appropriate shard. This makes the construct backward compatible to how MySQL's `auto_increment` property works.

Since sequences are unsharded tables, they will be stored in the commerce database. The schema:

``` sql
create table customer_seq(id int, next_id bigint, cache bigint, primary key(id)) comment 'vitess_sequence';
insert into customer_seq(id, next_id, cache) values(0, 1000, 100);
create table order_seq(id int, next_id bigint, cache bigint, primary key(id)) comment 'vitess_sequence';
insert into order_seq(id, next_id, cache) values(0, 1000, 100);
```

Note the `vitess_sequence` comment in the create table statement. VTTablet will use this metadata to treat this table as a sequence.

* `id` is always 0
* `next_id` is set to `1000`: the value should be comfortably greater than the `auto_increment` max value used so far.
* `cache` specifies the number of values to cache before vttablet updates `next_id`.

Higher cache values are more performant. However, cached values are lost if a reparent happens. The new master will start off at the `next_id` that was saved by the old master.

The VTGate servers also need to know about the sequence tables. This is done by updating the VSchema for commerce as follows:

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

NOTE: For some use cases, `customer_id` may actually map to a `tenant_id`. In such cases, the cardinality of a tenant id may be too low. It’s also common that such systems have queries that use other high cardinality columns in their where clauses. Those should then be taken into consideration when deciding on a good Primary Vindex.

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
helm upgrade $release ../../helm/vitess/ -f 301_customer_sharded.yaml
```

The jobs to watch for:

``` sh
NAME                                      DESIRED   SUCCESSFUL   AGE
jobs/commerce-apply-schema-seq            1         1            19s
jobs/commerce-apply-vschema-seq           1         1            19s
jobs/customer-apply-schema-sharded        1         1            19s
jobs/customer-apply-vschema-sharded       1         1            19s
```

### Create new shards

At this point, you have finalized your sharded VSchema and vetted all the queries to make sure they still work. Now, it’s time to reshard.

The resharding process works by splitting existing shards into smaller shards. This type of resharding is the most appropriate for Vitess. There are some use cases where you may want to spin up a new shard and add new rows in the most recently created shard. This can be achieved in Vitess by splitting a shard in such a way that no rows end up in the ‘new’ shard. However, it’s not natural for Vitess.

We have to create the new target shards:

``` sh
helm upgrade $release ../../helm/vitess/ -f 302_new_shards.yaml
```

The change we are applying is:

``` yaml
        - name: "customer"
          shards:
            - name: "0"
              tablets:
                - type: "replica"
                  vttablet:
                    replicas: 2
                - type: "rdonly"
                  vttablet:
                    replicas: 1
            - name: "-80"
              tablets:
                - type: "replica"
                  vttablet:
                    replicas: 2
                - type: "rdonly"
                  vttablet:
                    replicas: 1
              copySchema:
                source: "customer/0"
            - name: "80-"
              tablets:
                - type: "replica"
                  vttablet:
                    replicas: 2
                - type: "rdonly"
                  vttablet:
                    replicas: 1
              copySchema:
                source: "customer/0"
```

Shard 0 was already there. We have now added shards `-80` and `80-`. We’ve also added the `copySchema` directive which requests that the schema from shard 0 be copied into the new shards.

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

Applying the above change should result in the creation of six more vttablet pods, and the following new jobs:

``` sh
NAME                                         DESIRED   SUCCESSFUL   AGE
jobs/customer-copy-schema-80-x               1         1            58m
jobs/customer-copy-schema-x-80               1         1            58m
jobs/zone1-customer-80-x-init-shard-master   1         1            58m
jobs/zone1-customer-x-80-init-shard-master   1         1            58m
```
At this point, the tables have been created in the new shards but have no data yet.

``` sh
./kmysql.sh --table < ../common/select_customer-80_data.sql
Using customer/-80
Customer
COrder
./kmysql.sh --table < ../common/select_customer80-_data.sql
Using customer/80-
Customer
COrder
```

### SplitClone

The process for SplitClone is similar to VerticalSplitClone. It starts the horizontal resharding process:

``` sh
helm upgrade $release ../../helm/vitess/ -f 303_horizontal_split.yaml
```

This starts the following job:

``` yaml
jobs:
  - name: "horizontal-split"
    kind: "vtworker"
    cell: "zone1"
    command: "SplitClone -min_healthy_rdonly_tablets=1 customer/0"
```

For large tables, this job could potentially run for many days, and can be restarted if failed. This job performs the following tasks:

* Dirty copy data from customer/0 into the two new shards. But rows are split based on their target shards.
* Stop replication on customer/0 rdonly tablet and perform a final sync.
* Start a filtered replication process from customer/0 into the two shards by sending changes to one or the other shard depending on which shard the rows belong to.

Once `SplitClone` has completed, you should see this:

``` sh
NAME                                         DESIRED   SUCCESSFUL   AGE
jobs/vtworker-horizontal-split               1         1            5m
```

The horizontal counterpart to `VerticalSplitDiff` is `SplitDiff`. It can be used to validate the data integrity of the resharding process:

``` yaml
jobs:
  - name: "horizontal-split-diff"
    kind: "vtworker"
    cell: "zone1"
    command: "SplitDiff -min_healthy_rdonly_tablets=1 customer/-80"
```

Note that the last argument of SplitDiff is the target (smaller) shard. You will need to run one job for each target shard. Also, you cannot run them in parallel because they need to take an `rdonly` instance offline to perform the comparison.

NOTE: This example does not actually run this command.

NOTE: SplitDiff can be used to split shards as well as to merge them.

### Cut over
Now that you have verified that the tables are being continuously updated from the source shard, you can cutover the traffic. This is typically performed in three steps: `rdonly`, `replica` and `master`:

For rdonly and replica:

``` sh
helm upgrade $release ../../helm/vitess/ -f 304_migrate_replicas.yaml
```

For master:

``` sh
helm upgrade $release ../../helm/vitess/ -f 305_migrate_master.yaml
```

During the *master* migration, the original shard master will first stop accepting updates. Then the process will wait for the new shard masters to fully catch up on filtered replication before allowing them to begin serving. Since filtered replication has been following along with live updates, there should only be a few seconds of master unavailability.

The replica and rdonly cutovers are freely reversible. Unlike the Vertical Split, a horizontal split is also reversible. You just have to add a `-reverse_replication` flag while cutting over the master. This flag causes the entire resharding process to run in the opposite direction, allowing you to Migrate in the other direction if the need arises.

You should now be able to see the data that has been copied over to the new shards.

``` sh
./kmysql.sh --table < ../common/select_customer-80_data.sql
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

./kmysql.sh --table < ../common/select_customer80-_data.sql
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
helm upgrade $release ../../helm/vitess/ -f 306_down_shard_0.yaml
```

In this yaml, we just deleted shard 0. This will cause all those vttablet pods to be deleted. But the shard metadata is still present. We can clean that up with this command (after all vttablets have been brought down):

``` sh
helm upgrade $release ../../helm/vitess/ -f 307_delete_shard_0.yaml
```

This command runs the following job:

``` yaml
jobs:
  - name: "delete-shard0"
    kind: "vtctlclient"
    command: "DeleteShard -recursive customer/0"
```

Beyond this, you will also need to manually delete the Persistent Volume Claims associated to this shard.

And, as the final act, we remove the last executed job:

``` sh
helm upgrade $release ../../helm/vitess/ -f 308_final.yaml
```

### Teardown (optional)

You can delete the whole example if you are not proceeding to another exercise.

``` sh
helm delete $release
```

You will need to delete the persistent volume claims too

``` sh
kubectl delete pvc $(kubectl get pvc | grep vtdataroot-zone1 | awk '{print $1}')
```

Congratulations on completing this exercise!
