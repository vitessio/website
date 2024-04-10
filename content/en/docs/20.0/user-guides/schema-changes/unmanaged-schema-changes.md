---
title: Unmanaged Schema Changes
weight: 1
aliases: ['/docs/user-guides/operating-vitess/making-schema-changes', '/docs/schema-management/unmanaged-schema-changes/', '/docs/user-guides/unmanaged-schema-changes/']
---

Vitess offers multiple approaches to running unmanaged schema changes. Below, we review each of these approaches.

We assume we have a keyspace (schema) called `commerce`, with a table called `demo`, that has the following definition:

```sql
CREATE TABLE `demo` (
  `id` int NOT NULL,
  `status` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB
```

## ApplySchema

`ApplySchema` is a `vtctldclient` command that can be used to apply a schema change to a keyspace. The main advantage of using this tool is that it performs some sanity checks about the schema before applying it. However, a downside is that it can be a little too strict and may not work for all use cases.

Consider the following examples:

```shell
$ vtctldclient ApplySchema --sql "ALTER TABLE demo modify id bigint unsigned" commerce
```
```sql
SHOW CREATE TABLE demo;


CREATE TABLE `demo` (
  `id` bigint unsigned NOT NULL,
  `status` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB
```
In the above, we run a direct, synchronous, blocking `ALTER TABLE` statement. Knowing the table is in `commerce` keyspace, Vitess autodetects the relevant shards, and then autodetects which is the `primary` server in each shard. It then directly invokes the `ALTER TABLE` statement on all shards (concurrently), and the `vtctldclient` command only returns when all are complete.


When applying a new schema, where all statements are `CREATE TABLE` or `CREATE VIEW`, you may supply the flag `--batch-size=<n>`. For example:

```shell
$ vtctldclient ApplySchema --sql-file /tmp/create.sql --batch-size=100 commerce
```

This flag only applies for unmanaged schema changes, and optimizes total run time by sending batches of `CREATE` statements to the underlying databases.


## VTGate

You may run DDL directly from VTGate just like you would send to a MySQL instance. For example:

```shell
$ mysql -h 127.0.0.1 -P 15306 commerce
Welcome to the MySQL monitor.  Commands end with ; or \g.

mysql> ALTER TABLE demo ADD COLUMN sample INT;
Query OK, 0 rows affected (0.04 sec)
```

Just like in the previous example, Vitess will find out what the affected shards are, what the identity is of each shard's `primary`, then invoke the statement on all shards.

You may apply the change to specific shards by connecting directly to those shards:

```shell
$ mysql -h 127.0.0.1 -P 15306 commerce/-80
Welcome to the MySQL monitor.  Commands end with ; or \g.

mysql> ALTER TABLE demo ADD COLUMN sample INT;
Query OK, 0 rows affected (0.04 sec)
```

In the above we connect to VTGate via the `mysql` command line client, but of course you may connect with any standard MySQL client or from your application.

Please do note that if VTGate does not recognize a DDL syntax, the statement will get rejected and that this approach is not recommended for changing large tables.

## Directly to MySQL

You can apply schema changes directly to the underlying MySQL shard primary instances. 

VTTablet will eventually notice the change and update itself. This is controlled by the `--queryserver-config-schema-reload-time` parameter which defaults to 1800 seconds.

You can also explicitly issue the `vtctldclient` `ReloadSchema` command to make it reload immediately. Specify a tablet to reload the schema from, as in:

```shell
$ vtctldclient ReloadSchema zone1-0000000100
```

Users will likely want to deploy schema changes via [managed, online schema changes](../managed-online-schema-changes/) where the table is not locked in the duration of the migration.
