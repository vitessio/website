---
title: Local Install
description: Instructions for using Vitess on your machine for testing purposes
weight: 2
featured: true
aliases: ['/docs/tutorials/local/']
---

This guide covers installing Vitess locally for testing purposes, from pre-compiled binaries. We will launch multiple copies of `mysqld`, so it is recommended to have greater than 4GB RAM, as well as 20GB of available disk space.

A [docker setup](../local-docker/) is also available, which requires no dependencies on your local host.

## Install MySQL and etcd

Vitess supports the databases listed [here](../../overview/supported-databases/). We recommend MySQL 8.0 if your installation method provides that option:

```sh
# Ubuntu based
sudo apt install -y mysql-server etcd-server etcd-client curl

# Debian
sudo apt install -y default-mysql-server default-mysql-client etcd curl

# Yum based
sudo yum -y localinstall https://dev.mysql.com/get/mysql80-community-release-el8-3.noarch.rpm
sudo yum -y install mysql-community-server etcd curl
```

On apt-based distributions the services `mysqld` and `etcd` will need to be shutdown, since `etcd` will conflict with the `etcd` started in the examples, and `mysqlctl` will start its own copies of `mysqld`:

```sh
# Debian and Ubuntu
sudo service mysql stop
sudo service etcd stop
sudo systemctl disable mysql
sudo systemctl disable etcd
```


## Install Node

```
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
```

Ensure the following is in your bashrc/zshrc or similar. `nvm` automatically attempts to add them:
```
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
```

Finally, install [node](https://nodejs.org/):

```
nvm install 18
nvm use 18
```

See the [vtadmin README](https://github.com/vitessio/vitess/blob/main/web/vtadmin/README.md) for more details.

## Disable AppArmor or SELinux

AppArmor/SELinux will not allow Vitess to launch MySQL in any data directory by default. You will need to disable it:

__AppArmor__:
```sh
# Debian and Ubuntu
sudo ln -s /etc/apparmor.d/usr.sbin.mysqld /etc/apparmor.d/disable/
sudo apparmor_parser -R /etc/apparmor.d/usr.sbin.mysqld

# The following command should return an empty result:
sudo aa-status | grep mysqld
```

__SELinux__:
```sh
# CentOS
sudo setenforce 0
```

## Install Vitess

Download the [latest binary release](https://github.com/vitessio/vitess/releases) for Vitess on Linux. For example with Vitess 19:

**Notes:**

* Ubuntu is the only fully supported OS, for another OS please [build Vitess by yourself](/docs/contributing) or use the Docker images.

```sh
version=19.0.4
file=vitess-${version}-2c56724.tar.gz
wget https://github.com/vitessio/vitess/releases/download/v${version}/${file}
tar -xzf ${file}
cd ${file/.tar.gz/}
sudo mkdir -p /usr/local/vitess
sudo cp -r * /usr/local/vitess/
```

Make sure to add `/usr/local/vitess/bin` to the `PATH` environment variable. You can do this by adding the following to your `$HOME/.bashrc` file:

```sh
export PATH=/usr/local/vitess/bin:${PATH}
```

You are now ready to start your first cluster! Open a new terminal window to ensure your `.bashrc` file changes take effect. 

## Start a Single Keyspace Cluster

Start by copying the local examples included with Vitess to your preferred location. For our first example we will deploy a [single unsharded keyspace](../../concepts/keyspace). The file `101_initial_cluster.sh` is for example `1` phase `01`. Lets execute it now:

```sh
vitess_path=/usr/local/vitess
mkdir ~/my-vitess-example
cp -r ${vitess_path}/{examples,web} ~/my-vitess-example
cd ~/my-vitess-example/examples/local
./101_initial_cluster.sh
```

You should see an output similar to the following:

```bash
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

You can also verify that the processes have started with `pgrep`:

```bash
$ pgrep -fl vitess
14119 etcd
14176 vtctld
14251 mysqld_safe
14720 mysqld
14787 vttablet
14885 mysqld_safe
15352 mysqld
15396 vttablet
15492 mysqld_safe
15959 mysqld
16006 vttablet
16112 vtgate
16788 vtorc
```

_The exact list of processes will vary. For example, you may not see `mysqld_safe` listed._

If you encounter any errors, such as ports already in use, you can kill the processes and start over:

```sh
pkill -9 -f '(vtdataroot|VTDATAROOT|vitess|vtadmin)' # kill Vitess processes
rm -rf vtdataroot
```

## Setup Aliases

For ease-of-use, Vitess provides aliases for `mysql` and `vtcltdclient`:

```bash
source ../common/env.sh
```

Setting up aliases changes `mysql` to always connect to Vitess for your current session. To revert this, type `unalias mysql && unalias vtctldclient` or close your session.

## Connect to your cluster

You should now be able to connect to the VTGate server that was started in `101_initial_cluster.sh`:

```bash
$ mysql
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 8.0.31-Vitess (Ubuntu)

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
./401_teardown.sh
rm -rf vtdataroot
```
