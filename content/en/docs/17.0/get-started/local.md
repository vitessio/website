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
nvm install 16
nvm use 16
```

See the [vtadmin README](https://github.com/vitessio/vitess/blob/release-17.0/web/vtadmin/README.md) for more details.

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

Download the [latest binary release](https://github.com/vitessio/vitess/releases) for Vitess on Linux. For example with Vitess 17:

**Notes:**

* Ubuntu is the only fully supported OS, for another OS please [build Vitess by yourself](/docs/contributing) or use the Docker images.

```sh
version=17.0.7
file=vitess-${version}-7c0245d.tar.gz
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
Starting MySQL for tablet zone1-0000000100...
Starting vttablet for zone1-0000000100...
HTTP/1.1 200 OK
Date: Thu, 01 Sep 2022 12:49:50 GMT
Content-Type: text/html; charset=utf-8

Starting MySQL for tablet zone1-0000000101...
Starting vttablet for zone1-0000000101...
HTTP/1.1 200 OK
Date: Thu, 01 Sep 2022 12:49:55 GMT
Content-Type: text/html; charset=utf-8

Starting MySQL for tablet zone1-0000000102...
Starting vttablet for zone1-0000000102...
HTTP/1.1 200 OK
Date: Thu, 01 Sep 2022 12:50:00 GMT
Content-Type: text/html; charset=utf-8

{
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
vtorc is running!
  - UI: http://localhost:16000
  - Logs: /Users/manangupta/vitess/vtdataroot/tmp/vtorc.out
  - PID: 74088

zone1-0000000100 commerce 0 primary localhost:15100 localhost:17100 [] 2022-09-23T05:48:52Z

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
      "column_list_authoritative": false
    },
    "customer": {
      "type": "",
      "column_vindexes": [],
      "auto_increment": null,
      "columns": [],
      "pinned": "",
      "column_list_authoritative": false
    },
    "product": {
      "type": "",
      "column_vindexes": [],
      "auto_increment": null,
      "columns": [],
      "pinned": "",
      "column_list_authoritative": false
    }
  },
  "require_explicit_routing": false
}
If this is not what you expected, check the input data (as JSON parsing will skip unexpected fields).
Waiting for vtgate to be up...
vtgate is up!
Access vtgate at http://Manans-MacBook-Pro.local:15001/debug/status
vtadmin-api is running!
  - API: http://localhost:14200
  - Logs: /Users/manangupta/vitess/vtdataroot/tmp/vtadmin-api.out
  - PID: 74039

Installing nvm...

nvm is installed!

Configuring Node.js 16

Downloading and installing node v16.19.1...
Local cache found: ${NVM_DIR}/.cache/bin/node-v16.19.1-darwin-x64/node-v16.19.1-darwin-x64.tar.xz
Checksums match! Using existing downloaded archive ${NVM_DIR}/.cache/bin/node-v16.19.1-darwin-x64/node-v16.19.1-darwin-x64.tar.xz
Now using node v16.19.1 (npm v8.19.3)

> vtadmin@0.1.0 build
> vite build

vite v4.2.1 building for production...
transforming (1218) src/icons/alertFail.svgUse of eval in "node_modules/@protobufjs/inquire/index.js" is strongly discouraged as it poses security risks and may cause issues with minification.
✓ 1231 modules transformed.
build/assets/chevronUp-3d6782a5.svg              0.18 kB
build/assets/chevronDown-02f94e73.svg            0.19 kB
build/assets/download-8ef290b4.svg               0.21 kB
build/assets/delete-a9184ef9.svg                 0.23 kB
build/assets/info-2617ee9d.svg                   0.34 kB
build/assets/circleAdd-cfd7e5db.svg              0.35 kB
build/assets/alertFail-8056b6e4.svg              0.35 kB
build/assets/checkSuccess-f8fd1dbb.svg           0.36 kB
build/assets/search-3261bac7.svg                 0.41 kB
build/assets/question-a67b2492.svg               0.46 kB
build/assets/runQuery-edfab4ed.svg               0.49 kB
build/assets/open-405dd348.svg                   0.49 kB
build/index.html                                 0.90 kB
build/assets/bug-5b6edb54.svg                    0.99 kB
build/assets/topology-0032b65e.svg               1.62 kB
build/assets/NotoMono-Regular-41fd7ccc.ttf     107.85 kB
build/assets/NotoSans-Regular-c8cff31f.ttf     313.14 kB
build/assets/NotoSans-SemiBold-43207822.ttf    313.72 kB
build/assets/NotoSans-Bold-c6a598dd.ttf        313.79 kB
build/assets/index-ef40fbc9.css                 87.78 kB │ gzip:  15.02 kB
build/assets/index-4ddb52ed.js               2,811.88 kB │ gzip: 492.59 kB

(!) Some chunks are larger than 500 kBs after minification. Consider:
- Using dynamic import() to code-split the application
- Use build.rollupOptions.output.manualChunks to improve chunking: https://rollupjs.org/configuration-options/#output-manualchunks
- Adjust chunk size limit for this warning via build.chunkSizeWarningLimit.
✓ built in 10.85s

vtadmin-web is running!
  - Browser: http://localhost:14201
  - Logs: /Users/manangupta/vitess/vtdataroot/tmp/vtadmin-web.out
  - PID: 74070
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

For ease-of-use, Vitess provides aliases for `mysql`, `vtctlclient` and `vtcltdclient`:

```bash
source ../common/env.sh
```

Setting up aliases changes `mysql` to always connect to Vitess for your current session. To revert this, type `unalias mysql && unalias vtctlclient && unalias vtctldclient` or close your session.

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
