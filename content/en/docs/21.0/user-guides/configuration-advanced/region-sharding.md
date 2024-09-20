---
title: Region Based Sharding
weight: 25
aliases: ['/docs/user-guides/region-sharding/'] 
---

{{< info >}}
This guide follows on from the Get Started guides. Please make sure that you have a [local](../../../get-started/local) installation ready. You should also have already gone through the [MoveTables](../../migration/move-tables) and [Resharding](../../configuration-advanced/resharding) tutorials. The commands in this guide also assume you have setup the shell aliases from this example contained in `env.sh`.
{{< /info >}}

## Introduction

Having gone through the [Resharding tutorial](../resharding/), you should be familiar with
[VSchema](../../../reference/features/vschema) and [Vindexes](../../../reference/features/vindexes).
In this tutorial, we will perform resharding on an existing keyspace using a location-based vindex. We will create 4 shards: `-40`, `40-80`, `80-c0`, `c0-`. The location will be denoted by a `country` column in the customer table.

## Create and Start the Cluster

Start by copying the [`region_sharding` examples](https://github.com/vitessio/vitess/tree/main/examples/region_sharding)
included with Vitess to your preferred location and running the `101_initial_cluster.sh` script:

```bash
cp -r <vitess source path>/examples ~/my-vitess-example/examples
cp -r <vitess source path>/web ~/my-vitess-example
cd ~/my-vitess-example/examples/region_sharding
./101_initial_cluster.sh
```

## Initial Schema

This 101 script created the `customer` table in the unsharded `main` keyspace. This is the table that we will be
sharding by country.

We can connect to our new cluster — using the `mysql` alias setup by `env.sh` within the script — to confirm our current schema:

```mysql
$ mysql --binary-as-hex=false
...

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| main               |
| information_schema |
| mysql              |
| sys                |
| performance_schema |
+--------------------+
5 rows in set (0.00 sec)

mysql> use customer;
Database changed

mysql> show tables;
+----------------+
| Tables_in_main |
+----------------+
| customer       |
+----------------+
1 row in set (0.00 sec)

mysql> show create table customer\G
*************************** 1. row ***************************
       Table: customer
Create Table: CREATE TABLE `customer` (
  `id` int NOT NULL,
  `fullname` varbinary(256) DEFAULT NULL,
  `nationalid` varbinary(256) DEFAULT NULL,
  `country` varbinary(256) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
1 row in set (0.00 sec)
```

## Creating Test Data

Let's now create some test data:

```bash
$ mysql < ./insert_customers.sql

$ mysql --table < ./show_initial_data.sql
+----+------------------+-------------+---------------+
| id | fullname         | nationalid  | country       |
+----+------------------+-------------+---------------+
|  1 | Philip Roth      | 123-456-789 | United States |
|  2 | Gary Shteyngart  | 234-567-891 | United States |
|  3 | Margaret Atwood  | 345-678-912 | Canada        |
|  4 | Alice Munro      | 456-789-123 | Canada        |
|  5 | Albert Camus     | 912-345-678 | France        |
|  6 | Colette          | 102-345-678 | France        |
|  7 | Hermann Hesse    | 304-567-891 | Germany       |
|  8 | Cornelia Funke   | 203-456-789 | Germany       |
|  9 | Cixin Liu        | 789-123-456 | China         |
| 10 | Jian Ma          | 891-234-567 | China         |
| 11 | Haruki Murakami  | 405-678-912 | Japan         |
| 12 | Banana Yoshimoto | 506-789-123 | Japan         |
| 13 | Arundhati Roy    | 567-891-234 | India         |
| 14 | Shashi Tharoor   | 678-912-345 | India         |
| 15 | Andrea Hirata    | 607-891-234 | Indonesia     |
| 16 | Ayu Utami        | 708-912-345 | Indonesia     |
+----+------------------+-------------+---------------+
```

## Prepare For Resharding

Now that we have some data in our unsharded `main` keyspace, let's go ahead and perform the setup needed
for resharding. The initial vschema is unsharded and simply lists the customer table:

```json
$ vtctldclient --server localhost:15999 GetVSchema main
{
  "sharded": false,
  "vindexes": {},
  "tables": {
    "customer": {
      "type": "",
      "column_vindexes": [],
      "auto_increment": null,
      "columns": [],
      "pinned": "",
      "column_list_authoritative": false,
      "source": ""
    }
  },
  "require_explicit_routing": false
}
```

</br>

We are next going to prepare for having a sharded vschema in the cluster by editing the
`main_vschema_sharded.json` file and updating the the `region_map` key's value to point to the
filesystem path where that file resides on your machine. For example (relative paths are OK):

```json
        "region_map": "./countries.json",
```

</br>

We then run the 201 script:

```bash
./201_main_sharded.sh
```

</br>

That script creates our sharded vschema as defined in the `main_vschema_sharded.json` file and it
creates a [lookup vindex](../../../reference/features/vindexes/#functional-and-lookup-vindex) using the
[`LookupVindex create` command](../../reference/programs/vtctldclient/vtctldclient_lookupvindex/vtctldclient_lookupvindex_create/).

Now if we look at the `main` keyspace's vschema again we can see that it now includes the `region_vdx` vindex and
a lookup vindex called `customer_region_lookup`:

```json
$ vtctldclient --server=localhost:15999 GetVSchema main --compact
{
  "sharded": true,
  "vindexes": {
    "customer_region_lookup": {
      "type": "consistent_lookup_unique",
      "params": {
        "from": "id",
        "ignore_nulls": "false",
        "table": "main.customer_region_lookup",
        "to": "keyspace_id"
      },
      "owner": "customer"
    },
    "region_vdx": {
      "type": "region_json",
      "params": {
        "region_bytes": "1",
        "region_map": "./countries.json"
      }
    },
    "xxhash": {
      "type": "xxhash"
    }
  },
  "tables": {
    "customer": {
      "column_vindexes": [
        {
          "name": "region_vdx",
          "columns": [
            "id",
            "country"
          ]
        },
        {
          "name": "customer_region_lookup",
          "columns": [
            "id"
          ]
        }
      ]
    },
    "customer_region_lookup": {
      "column_vindexes": [
        {
          "column": "id",
          "name": "xxhash"
        }
      ]
    }
  }
}
```

</br>

Notice that the vschema shows a `xxhash` [vindex type](../../../reference/features/vindexes/#predefined-vindexes) for
the lookup table. This is automatically created by the `LookupVindex` workflow, along with the
backing table needed to hold the vindex and populating it with the correct rows (for additional details on this
command see [the associated user-guide](../createlookupvindex/)). We can see that by checking our `main`
database/keyspace again:

```mysql
mysql> show tables;
+-------------------+
| Tables_in_vt_main |
+-------------------+
| customer          |
| customer_lookup   |
+-------------------+
2 rows in set (0.00 sec)

mysql> describe customer_lookup;
+-------------+----------------+------+-----+---------+-------+
| Field       | Type           | Null | Key | Default | Extra |
+-------------+----------------+------+-----+---------+-------+
| id          | int(11)        | NO   | PRI | NULL    |       |
| keyspace_id | varbinary(128) | YES  |     | NULL    |       |
+-------------+----------------+------+-----+---------+-------+
2 rows in set (0.01 sec)

mysql> select id, hex(keyspace_id) from customer_lookup;
+----+--------------------+
| id | hex(keyspace_id)   |
+----+--------------------+
|  1 | 01166B40B44ABA4BD6 |
|  2 | 0106E7EA22CE92708F |
|  3 | 024EB190C9A2FA169C |
|  4 | 02D2FD8867D50D2DFE |
|  5 | 4070BB023C810CA87A |
|  6 | 40F098480AC4C4BE71 |
|  7 | 41FB8BAAAD918119B8 |
|  8 | 41CC083F1E6D9E85F6 |
|  9 | 80692BB9BF752B0F58 |
| 10 | 80594764E1A2B2D98E |
| 11 | 81AEFC44491CFE474C |
| 12 | 81D3748269B7058A0E |
| 13 | C062DCE203C602F358 |
| 14 | C0ACBFDA0D70613FC4 |
| 15 | C16A8B56ED414942B8 |
| 16 | C15B711BC4CEEBF2EE |
+----+--------------------+
16 rows in set (0.01 sec)
```

</br>

Now that the sharded vschema and lookup vindex and its backing table are ready, we can start tablets that will be
used for our new *sharded* `main` keyspace:

```bash
./202_new_tablets.sh
```

</br>

Now we have tablets for our original unsharded `main` keyspace — shard `0` — and one tablet for each of the 4 shards
we'll be using when we reshard the `main` keyspace:

```bash
$ vtctldclient --server localhost:15999 GetTablets --keyspace=main
zone1-0000000100 main 0 primary localhost:15100 localhost:17100 [] 2023-01-24T04:31:08Z
zone1-0000000200 main -40 primary localhost:15200 localhost:17200 [] 2023-01-24T04:45:38Z
zone1-0000000300 main 40-80 primary localhost:15300 localhost:17300 [] 2023-01-24T04:45:38Z
zone1-0000000400 main 80-c0 primary localhost:15400 localhost:17400 [] 2023-01-24T04:45:38Z
zone1-0000000500 main c0- primary localhost:15500 localhost:17500 [] 2023-01-24T04:45:38Z
```

</br>

{{< info >}}
In this example we are deploying 1 tablet per shard and thus disabling the
[semi-sync durability policy](../../configuration-basic/durability_policy/), but in typical production setups each
shard will consist of 3 or more tablets.
{{< /info >}}

## Perform Resharding

Now that our new tablets are up, we can go ahead with the resharding:

```bash
./203_reshard.sh
```

</br>

This script executes one command:

```bash
vtctldclient --server localhost:15999 Reshard --target-keyspace main --workflow main2regions create --source-shards '0' --target-shards '-40,40-80,80-c0,c0-' --tablet-types=PRIMARY
```

</br>

This step copies all the data from our source `main/0` shard to our new `main` target shards and sets up
a VReplication workflow to keep the tables on the target in sync with the source.

You can learn more about what the VReplication [`Reshard` command](../../../reference/vreplication/reshard/)
does and how it works in [the reference page](../../../reference/vreplication/reshard/) and the
[Resharding user-guide](../../configuration-advanced/resharding/).

We can check the correctness of the copy using the [`VDiff` command](../../../reference/vreplication/vdiff)
and the `<keyspace>.<workflow>` name we used for `Reshard` command above:

```bash
$ vtctldclient --server localhost:15999 VDiff --target-keyspace main --workflow main2regions create
VDiff 044e8da0-9ba4-11ed-8bc7-920702940ee0 scheduled on target shards, use show to view progress

$ vtctldclient --server localhost:15999 VDiff --format=json --target-keyspace main --workflow main2regions show last
{
	"Workflow": "main2regions",
	"Keyspace": "main",
	"State": "completed",
	"UUID": "044e8da0-9ba4-11ed-8bc7-920702940ee0",
	"RowsCompared": 32,
	"HasMismatch": false,
	"Shards": "-40,40-80,80-c0,c0-",
	"StartedAt": "2023-01-24 05:00:26",
	"CompletedAt": "2023-01-24 05:00:27"
}
```

</br>

We can take a look at the VReplication workflow's status using the
[`show` action](../../../reference/programs/vtctldclient/vtctldclient_reshard/vtctldclient_reshard_show/):

```bash
vtctldclient --server localhost:15999 Reshard --target-keyspace main --workflow main2regions show
```

</br>

We now have a running stream from the source tablet (`100`) to each of of our new `main` target shards that will
keep the tables up-to-date with the source shard (`0`).

## Cutover

Once the VReplication workflow's [copy phase](../../../reference/vreplication/internal/life-of-a-stream/#copy) is
complete, we can start cutting-over traffic. This is done via the
[SwitchTraffic](../../../reference/vreplication/reshard/#switchtraffic) actions included in the following scripts:

```bash
./204_switch_reads.sh
./205_switch_writes.sh
```

</br>

Now we can look at how our data is sharded, e.g. by looking at what's stored on the `main/-40` shard:

```mysql
mysql> show vitess_tablets;
+-------+----------+-------+------------+---------+------------------+-----------+----------------------+
| Cell  | Keyspace | Shard | TabletType | State   | Alias            | Hostname  | PrimaryTermStartTime |
+-------+----------+-------+------------+---------+------------------+-----------+----------------------+
| zone1 | main     | -40   | PRIMARY    | SERVING | zone1-0000000200 | localhost | 2023-01-24T04:45:38Z |
| zone1 | main     | 0     | PRIMARY    | SERVING | zone1-0000000100 | localhost | 2023-01-24T04:31:08Z |
| zone1 | main     | 40-80 | PRIMARY    | SERVING | zone1-0000000300 | localhost | 2023-01-24T04:45:38Z |
| zone1 | main     | 80-c0 | PRIMARY    | SERVING | zone1-0000000400 | localhost | 2023-01-24T04:45:38Z |
| zone1 | main     | c0-   | PRIMARY    | SERVING | zone1-0000000500 | localhost | 2023-01-24T04:45:38Z |
+-------+----------+-------+------------+---------+------------------+-----------+----------------------+
5 rows in set (0.00 sec)

mysql> use main/-40;
Database changed

mysql> select * from customer;
+----+-----------------+-------------+---------------+
| id | fullname        | nationalid  | country       |
+----+-----------------+-------------+---------------+
|  1 | Philip Roth     | 123-456-789 | United States |
|  2 | Gary Shteyngart | 234-567-891 | United States |
|  3 | Margaret Atwood | 345-678-912 | Canada        |
|  4 | Alice Munro     | 456-789-123 | Canada        |
+----+-----------------+-------------+---------------+
4 rows in set (0.01 sec)

mysql> select id,hex(keyspace_id) from customer_lookup;
+----+--------------------+
| id | hex(keyspace_id)   |
+----+--------------------+
|  1 | 01166B40B44ABA4BD6 |
|  2 | 0106E7EA22CE92708F |
+----+--------------------+
2 rows in set (0.00 sec)
```

</br>

You can see that only data from US and Canada exists in the `customer` table in this shard. If you look at the
other shards — `40-80`, `80-c0`, and `c0-` — you will see that each shard contains 4 rows in `customer` table.

The lookup table, however, has a different number of rows per shard. This is because we are using a
[`xxhash` vindex type](../../../reference/features/vindexes/#predefined-vindexes) to shard the lookup table
which means that it is distributed differently from the `customer` table. We can see an example of this if we
look at the next shard, `40-80`:

```mysql
mysql> use main/40-80;

Database changed
mysql> select * from customer;
+----+----------------+-------------+---------+
| id | fullname       | nationalid  | country |
+----+----------------+-------------+---------+
|  5 | Albert Camus   | 912-345-678 | France  |
|  6 | Colette        | 102-345-678 | France  |
|  7 | Hermann Hesse  | 304-567-891 | Germany |
|  8 | Cornelia Funke | 203-456-789 | Germany |
+----+----------------+-------------+---------+
4 rows in set (0.00 sec)

mysql> select id, hex(keyspace_id) from customer_lookup;
+----+--------------------+
| id | hex(keyspace_id)   |
+----+--------------------+
|  3 | 024EB190C9A2FA169C |
|  5 | 4070BB023C810CA87A |
|  9 | 80692BB9BF752B0F58 |
| 10 | 80594764E1A2B2D98E |
| 13 | C062DCE203C602F358 |
| 15 | C16A8B56ED414942B8 |
| 16 | C15B711BC4CEEBF2EE |
+----+--------------------+
7 rows in set (0.00 sec)
```

## Cleanup

Now that our resharding work is complete, we can teardown and delete the old `main/0` source shard:

```bash
./206_down_shard_0.sh
./207_delete_shard_0.sh
```

</br>

All we have now is the sharded `main` keyspace and the original unsharded `main` keyspace (shard `0`) no
longer exists:

```bash
$ vtctldclient GetTablets
zone1-0000000200 main -40 primary localhost:15200 localhost:17200 [] 2023-01-24T04:45:38Z
zone1-0000000300 main 40-80 primary localhost:15300 localhost:17300 [] 2023-01-24T04:45:38Z
zone1-0000000400 main 80-c0 primary localhost:15400 localhost:17400 [] 2023-01-24T04:45:38Z
zone1-0000000500 main c0- primary localhost:15500 localhost:17500 [] 2023-01-24T04:45:38Z
```

## Teardown

Once you are done playing with the example, you can tear the cluster down and remove all of its resources
completely:

```bash
./301_teardown.sh
```
