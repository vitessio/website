---
title: Local Install via source for Mac
description: Instructions for using Vitess on your macOS machine for testing purposes
weight: 4
---

This guide covers installing Vitess locally for testing purposes, from pre-compiled binaries. We will launch multiple copies of `mysqld`, so it is recommended to have greater than 4GB RAM, as well as 20GB of available disk space.

A pure [homebrew setup](../local-brew/) is also available.

## Install Brew

For the purposes of installing software you will need to have brew installed. This will also install curl and git which will also be needed:

```sh
$ curl https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh > brew-install.sh

$ bash brew-install.sh
```

## Install MySQL and etcd

Once brew is installed you will need to install some dependencies for Vitess. Vitess supports MySQL 5.7+ and MariaDB 10.3+: 

```sh
$ brew install automake go mysql@5.7 mysql-client etcd
```

When MySQL installs with brew it will startup, you will want to shut this process down, as Vitess will be managing the startup and shutdown of MySQL:

```sh
$ brew services stop mysql@5.7
```

## PATH Settings

With the tools you’ve just installed via brew, you will next update your PATH variable so your shell knows where to find the binaries:

```sh
$ echo “export PATH=${PATH}:/opt/homebrew/opt/mysql-client/bin:/opt/homebrew/opt/mysql@5.7/bin:~/Github/vitess/bin:/Users/jason/go/bin:​​/opt/homebrew/bin” >> ~/.zshrc
$ source ~/.zshrc
```

If you’re using bash for your shell you’ll have to update the paths in `.bash_profile` or `.bashrc` instead. Mac does not read `.bashrc` by default:

```sh
$ echo “export PATH=${PATH}:/opt/homebrew/opt/mysql-client/bin:/opt/homebrew/opt/mysql@5.7/bin:~/Github/vitess/bin:/Users/jason/go/bin:/opt/homebrew/bin” >> ~/.bash_profile
$ source ~/.bash_profile
```

## System Check

Before going further, you should check to confirm your shell has access to `go`, `mysql`, and `mysqld`. If versions are not returned when you run the following commands you should check that the programs are installed and the path is correct for your shell: 

```sh
$ mysqld --version
$ mysql --version
$ go version
$ etcd --version
```

## Install Vitess

With everything now in place you can clone and build Vitess.

```sh
$ git clone https://github.com/vitessio/vitess.git
$ cd vitess
$ make build
```

It will take some time for Vitess to build. Once it completes you should see a bin folder which will hold the Vitess binaries. You will need to add this folder to your `PATH` variable as well: 

```sh
$ cd bin
$ echo "$(printf 'export PATH="${PATH}:'; echo "$(pwd)\"")" >> ~/.zshrc
$ source ~/.zshrc
```

If you are using bash this will need to be your `.bash_profile` or `.bashrc` file instead:

```sh
$ cd bin
$ echo "$(printf 'export PATH="${PATH}:'; echo "$(pwd)\"")" >> ~/.bash_profile
$ source ~/.bash_profile
```

You are now ready to start your first cluster! Open a new terminal window to ensure your `.bashrc` file changes take effect. 

## Start a Single Keyspace Cluster

You are now ready to stand up your first Vitess cluster, using the example scripts provided in the source code. Assuming you are still in the bin directory you will need to navigate to the sample files:

```sh
$ cd ../examples/local/
```

From here you can startup the cluster and source the env file which will help set environment variables used when working with this local cluster: 

```sh
$ ./101_initial_cluster.sh
$ source env.sh
```

You should see output similar to the following:

```text
~/my-vitess-example> ./101_initial_cluster.sh
$ ./101_initial_cluster.sh 
add /vitess/global
add /vitess/zone1
add zone1 CellInfo
etcd start done...
Starting vtctld...
Starting MySQL for tablet zone1-0000000100...
Starting vttablet for zone1-0000000100...
HTTP/1.1 200 OK
Date: Wed, 25 Mar 2020 17:32:45 GMT
Content-Type: text/html; charset=utf-8

Starting MySQL for tablet zone1-0000000101...
Starting vttablet for zone1-0000000101...
HTTP/1.1 200 OK
Date: Wed, 25 Mar 2020 17:32:53 GMT
Content-Type: text/html; charset=utf-8

Starting MySQL for tablet zone1-0000000102...
Starting vttablet for zone1-0000000102...
HTTP/1.1 200 OK
Date: Wed, 25 Mar 2020 17:33:01 GMT
Content-Type: text/html; charset=utf-8

W0325 11:33:01.932674   16036 main.go:64] W0325 17:33:01.930970 reparent.go:185] primary-elect tablet zone1-0000000100 is not the shard primary, proceeding anyway as -force was used
W0325 11:33:01.933188   16036 main.go:64] W0325 17:33:01.931580 reparent.go:191] primary-elect tablet zone1-0000000100 is not a primary in the shard, proceeding anyway as -force was used
..
```

If you encounter any errors, such as ports already in use, you can kill the processes and start over:

```sh
NEED EXAMPLE
```

## Connect to your cluster

You should now be able to connect to the VTGate server that was started in `101_initial_cluster.sh`:

``NEED EXAMPLE```

You can also browse to the vtctld console using the following URL:

```text
http://localhost:15000
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

Or alternatively, once you are finished with the local examples or if you would like to start over, you can clean up by running the 401_teardown script:

```sh
$ ./401_teardown.sh
$ rm -rf ./vtdataroot
```

Sometimes you will still need to manually kill processes if there are errors in the environment:

```sh
$ pkill -9 -f ./vtdataroot
$ rm -rf ./vtdataroot
```
