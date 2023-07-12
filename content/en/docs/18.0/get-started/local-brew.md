---
title: Local Install via Homebrew
description: Instructions for using Vitess on your macOS machine for testing purposes
weight: 2
featured: true
aliases: ['/docs/tutorials/local-brew/']
---

This guide covers installing Vitess locally to macOS for testing purposes, from pre-compiled binaries. We will launch multiple copies of `mysqld`, so it is recommended to have greater than 4GB RAM, as well as 20GB of available disk space.

A [Homebrew](https://brew.sh/) package manager is also available, which requires no dependencies on your local host.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

> In this guide, `v9.0.0` is used in most outputs. You can replace it by the version of Vitess you are using.

## Install Vitess with Homebrew

Vitess supports the databases listed [here](../../overview/supported-databases/). Homebrew will install latest tagged Vitess Release.

```bash
$ brew install vitess
Updating Homebrew...
==> Auto-updated Homebrew!
Updated 2 taps (homebrew/core and homebrew/cask).
==> Updated Formulae
Updated 19 formulae.
==> Updated Casks
Updated 1 cask.

==> Downloading https://homebrew.bintray.com/bottles/vitess-9.0.0.catalina.bottle.tar.gz
Already downloaded: /Users/askdba/Library/Caches/Homebrew/downloads/45991b27589a191910e89a1ce529fcdaa694bb5f36b99f1b20146f8f0fc3ee6d--vitess-9.0.0.catalina.bottle.tar.gz
==> Pouring vitess-9.0.0.catalina.bottle.tar.gz
🍺  /usr/local/Cellar/vitess/9.0.0: 268 files, 528.3MB
```
At this point Vitess binaries installed under default Homebrew install location at /usr/local/share/vitess.

### Install Node 18.16.0+ (required to run VTAdmin)

```bash
$ brew install nvm
$ nvm install --lts 18.16.0
$ nvm use 18.16.0
```

See the [vtadmin README](https://github.com/vitessio/vitess/blob/main/web/vtadmin/README.md) for more details.

## Start a Single Keyspace Cluster

For testing purposes initiate following example;
```bash
$ cd /usr/local/share/vitess/examples/local/
$ ./101_initial_cluster.sh
add /vitess/global
add /vitess/zone1
add zone1 CellInfo
Created cell: zone1
etcd start done...
Starting vtctld...
vtctld is running!
Successfully created keyspace commerce. Result:
{
  "name": "commerce",
  "keyspace": {
    "served_froms": [],
    "keyspace_type": 0,
    "base_keyspace": "",
    "snapshot_time": null,
    "durability_policy": "semi_sync",
    "throttler_config": null,
    "sidecar_db_name": "_vt"
  }
}
Starting MySQL for tablet zone1-0000000100...
Starting vttablet for zone1-0000000100...
HTTP/1.1 200 OK
Date: Mon, 26 Jun 2023 19:21:51 GMT
Content-Type: text/html; charset=utf-8

Starting MySQL for tablet zone1-0000000101...
Starting vttablet for zone1-0000000101...
HTTP/1.1 200 OK
Date: Mon, 26 Jun 2023 19:21:54 GMT
Content-Type: text/html; charset=utf-8

Starting MySQL for tablet zone1-0000000102...
Starting vttablet for zone1-0000000102...
HTTP/1.1 200 OK
Date: Mon, 26 Jun 2023 19:21:56 GMT
Content-Type: text/html; charset=utf-8

vtorc is running!
  - UI: http://localhost:16000
  - Logs: /Users/florentpoinsard/Code/vitess/vtdataroot/tmp/vtorc.out
  - PID: 49556


New VSchema object:
{
  "sharded": false,
  "vindexes": {},
  "tables": {
    "corder": {
      "type": "",
      "column_vindexes": [],
      "auto_increment": null,
      "columns": [],
      "pinned": "",
      "column_list_authoritative": false,
      "source": ""
    },
    "customer": {
      "type": "",
      "column_vindexes": [],
      "auto_increment": null,
      "columns": [],
      "pinned": "",
      "column_list_authoritative": false,
      "source": ""
    },
    "product": {
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
If this is not what you expected, check the input data (as JSON parsing will skip unexpected fields).
Waiting for vtgate to be up...
vtgate is up!
Access vtgate at http://Florents-MacBook-Pro-2.local:15001/debug/status
vtadmin-api is running!
  - API: http://Florents-MacBook-Pro-2.local:14200
  - Logs: /Users/florentpoinsard/Code/vitess/vtdataroot/tmp/vtadmin-api.out
  - PID: 49695

vtadmin-web is running!
  - Browser: http://Florents-MacBook-Pro-2.local:14201
  - Logs: /Users/florentpoinsard/Code/vitess/vtdataroot/tmp/vtadmin-web.out
  - PID: 49698
```
Verify your initial cluster:
```sql
$ mysql -e "show vitess_tablets"
+-------+----------+-------+------------+---------+------------------+-----------+----------------------+
| Cell  | Keyspace | Shard | TabletType | State   | Alias            | Hostname  | MasterTermStartTime  |
+-------+----------+-------+------------+---------+------------------+-----------+----------------------+
| zone1 | commerce | 0     | PRIMARY    | SERVING | zone1-0000000100 | localhost | 2021-02-17T13:10:13Z |
| zone1 | commerce | 0     | REPLICA    | SERVING | zone1-0000000101 | localhost |                      |
| zone1 | commerce | 0     | RDONLY     | SERVING | zone1-0000000102 | localhost |                      |
+-------+----------+-------+------------+---------+------------------+-----------+----------------------+
```
You can also verify that the processes have started with `pgrep`:

```bash
$ pgrep -fl vitess | awk '{print $2,$3}'
etcd --enable-v2=true
vtctld -topo_implementation
/bin/sh /usr/local/opt/mysql@5.7/bin/mysqld_safe
/usr/local/opt/mysql@5.7/bin/mysqld --defaults-file=/usr/local/Cellar/vitess/9.0.0/share/vitess/examples/local/vtdataroot/vt_0000000100/my.cnf
vttablet -topo_implementation
/bin/sh /usr/local/opt/mysql@5.7/bin/mysqld_safe
/usr/local/opt/mysql@5.7/bin/mysqld --defaults-file=/usr/local/Cellar/vitess/9.0.0/share/vitess/examples/local/vtdataroot/vt_0000000101/my.cnf
vttablet -topo_implementation
/bin/sh /usr/local/opt/mysql@5.7/bin/mysqld_safe
/usr/local/opt/mysql@5.7/bin/mysqld --defaults-file=/usr/local/Cellar/vitess/9.0.0/share/vitess/examples/local/vtdataroot/vt_0000000102/my.cnf
vttablet -topo_implementation
vtgate -topo_implementation
vtorc --topo_implementation
```

_The exact list of processes will vary. For example, you may not see `mysqld_safe` listed._

If you encounter any errors, such as ports already in use, you can kill the processes and start over:

```bash
pkill -9 -f '(vtdataroot|VTDATAROOT|vitess|vtadmin)' # kill Vitess processes
rm -rf /usr/local/Cellar/vitess/9.0.0/share/vitess/examples/local/vtdataroot
```

## Setup Aliases

For ease-of-use, Vitess provides aliases for `mysql` and `vtctlclient`:

```bash
source ./env.sh
```

Setting up aliases changes `mysql` to always connect to Vitess for your current session. To revert this, type `unalias mysql && unalias vtctlclient` or close your session.

## Connect to your cluster

You should now be able to connect to the VTGate server that was started in `101_initial_cluster.sh`:

```bash
/usr/local/share/vitess/examples/local> mysql
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.7.9-Vitess (Ubuntu)

Copyright (c) 2000, 2019, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show tables;
+-----------------------+
| Tables_in_vt_commerce |
+-----------------------+
| corder                |
| customer              |
| product               |
+-----------------------+
3 rows in set (0.00 sec)
```

</br>

You can also now browse and administer your new Vitess cluster using the [VTAdmin](../../reference/vtadmin/) UI at the following URL:

```text
http://localhost:14201
```

</br>

VTOrc is also setup as part of the initialization. You can look at its user-interface at:

```text
http://localhost:16000
```

## Summary

In this example, we deployed a single unsharded keyspace named `commerce`. Unsharded keyspaces have a single shard named `0`. The following schema reflects a common ecommerce scenario that was created by the script:

```sql
create table product (
  sku varbinary(128),
  description varbinary(128),
  price bigint,
  primary key(sku)
);
create table customer (
  customer_id bigint not null auto_increment,
  email varbinary(128),
  primary key(customer_id)
);
create table corder (
  order_id bigint not null auto_increment,
  customer_id bigint,
  sku varbinary(128),
  price bigint,
  primary key(order_id)
);
```

The schema has been simplified to include only those fields that are significant to the example:

* The `product` table contains the product information for all of the products.
* The `customer` table has a `customer_id` that has an `auto_increment`. A typical customer table would have a lot more columns, and sometimes additional detail tables.
* The `corder` table (named so because `order` is an SQL reserved word) has an `order_id` auto-increment column. It also has foreign keys into `customer(customer_id)` and `product(sku)`.

## Next Steps

You can now proceed with [MoveTables](../../user-guides/migration/move-tables).

Or alternatively, if you would like to teardown your example:

```bash
pkill -9 -f '(vtdataroot|VTDATAROOT)' # kill Vitess processes
rm -rf /usr/local/Cellar/vitess/9.0.0/share/vitess/examples/local/vtdataroot
```
