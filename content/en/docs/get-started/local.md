---
title: Run Vitess Locally
description: Instructions for using Vitess on your machine for testing purposes
weight: 4
featured: true
aliases: ['/docs/tutorials/local/']
---

This guide covers installing Vitess locally for testing purposes, from pre-compiled binaries. We will launch multiple copies of `mysqld`, so it is recommended to have greater than 4GB RAM, as well as 20GB of available disk space.

## Download Vitess Package

Download and extract the [latest `.tar.gz` release](https://github.com/vitessio/vitess/releases) from GitHub. Use the following command to extract the file.

```
tar -zxvf latest-version.tar.gz
```

## Install MySQL and etcd

Vitess supports MySQL 5.6+ and MariaDB 10.0+. We recommend MySQL 5.7 if your installation method provides a choice:

```
# Ubuntu based
sudo apt install -y mysql-server etcd
sudo apt install -y curl

# Debian
sudo apt install -y default-mysql-server default-mysql-client etcd
sudo apt install -y curl

# Yum based
sudo yum -y localinstall https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
sudo yum -y install mysql-community-server etcd
sudo yum -y install curl
```

On apt-based distributions the services `mysqld` and `etcd` will need to be shutdown, since `etcd` will conflict with the `etcd` started in the examples, and `mysqlctl` will start its own copies of `mysqld`:

```
# Debian and Ubuntu
sudo service mysql stop
sudo service etcd stop
sudo systemctl disable mysql
sudo systemctl disable etcd
```

## Disable AppArmor or SELinux

AppArmor/SELinux will not allow Vitess to launch MySQL in any data directory by default. You will need to disable it:

__AppArmor__:
```
# Debian and Ubuntu
sudo ln -s /etc/apparmor.d/usr.sbin.mysqld /etc/apparmor.d/disable/
sudo apparmor_parser -R /etc/apparmor.d/usr.sbin.mysqld

# The following command should return an empty result:
sudo aa-status | grep mysqld
```

__SELinux__:
```
# CentOS
sudo setenforce 0
```

## Configure Environment

Add the following to your `$Home/.bashrc` file. Make sure to replace `/path/to/extracted-tarball` with the actual path to where you extracted the latest release file:

```
export VTROOT=/path/to/extracted-tarball
export VTTOP=$VTROOT
export VTDATAROOT=${HOME}/vtdataroot
export PATH=${VTROOT}/bin:${PATH}
```

You are now ready to start your first cluster! Open a new terminal window before continuing.

## Start a Single Keyspace Cluster

A [keyspace](../../concepts/keyspace) in Vitess is a logical database consisting of potentially multiple shards. For our first example, we are going to be using Vitess without sharding using a single keyspace. The file `101_initial_cluster.sh` is for example `1` phase `01`. Lets execute it now:

```
cd examples/local
./101_initial_cluster.sh
```

You should see output similar to the following:

```
~/...vitess/examples/local> ./101_initial_cluster.sh
enter etcd2 env
add /vitess/global
add /vitess/zone1
add zone1 CellInfo
etcd start done...
enter etcd2 env
Starting vtctld...
Access vtctld web UI at http://morgox1:15000
Send commands with: vtctlclient -server morgox1:15999 ...
enter etcd2 env
Starting MySQL for tablet zone1-0000000100...
Starting MySQL for tablet zone1-0000000101...
Starting MySQL for tablet zone1-0000000102...
Starting vttablet for zone1-0000000100...
Access tablet zone1-0000000100 at http://morgox1:15100/debug/status
Starting vttablet for zone1-0000000101...
Access tablet zone1-0000000101 at http://morgox1:15101/debug/status
Starting vttablet for zone1-0000000102...
..
```

You can also verify that the processes have started with `pgrep`:

```
~/...vitess/examples/local> pgrep -fl vtdataroot
26563 etcd
26626 vtctld
26770 mysqld_safe
26771 mysqld_safe
26890 mysqld_safe
29910 mysqld
29925 mysqld
29945 mysqld
30035 vttablet
30036 vttablet
30037 vttablet
30218 vtgate
```

_The exact list of processes will vary. For example, you may not see `mysqld_safe` listed._

If you encounter any errors, such as ports already in use, you can kill the processes and start over:

```
pkill -9 -e -f '(vtdataroot|VTDATAROOT)' # kill Vitess processes
rm -rf ${HOME}/vtdataroot
```

## Connect to Your Cluster

You should now be able to connect to the VTGate server that was started in `101_initial_cluster.sh`. To connect to it with the `mysql` command line client:

```
~/...vitess/examples/local> mysql -h 127.0.0.1 -P 15306
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 1
Server version: 5.5.10-Vitess (Ubuntu)

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
3 rows in set (0.01 sec)
```

It is recommended to configure the MySQL command line to default to these settings, as the user guides omit `-h 127.0.0.1 -P 15306` for brevity. Enter the following into the command line:

```
cat << EOF > ~/.my.cnf
[client]
host=127.0.0.1
port=15306
EOF
```

Repeating the previous step, you should now be able to use the `mysql` client without any settings:

```
~/...vitess/examples/local> mysql
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 1
Server version: 5.5.10-Vitess (Ubuntu)

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

You can also browse to the vtctld console using the following URL:

```
http://localhost:15000
```

## Summary

In this example, we deployed a single unsharded keyspace named `commerce`. Unsharded keyspaces have a single shard named `0`. The following schema reflects a common ecommerce scenario that was created by the script:

```
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

You can now proceed with [Vertical Split](../../user-guides/vertical-split).

Or alternatively, if you would like to teardown your example:

```
./401_teardown.sh
```
