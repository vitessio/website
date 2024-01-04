---
title: Local Install via source for Mac
description: Instructions for using Vitess on your macOS machine for testing purposes
weight: 4
---

This guide covers installing Vitess locally for testing purposes, from pre-compiled binaries. We will launch multiple copies of `mysqld`, so it is recommended to have greater than 4GB RAM, as well as 20GB of available disk space.

## Install Brew

For the purposes of installing software you will need to have brew installed. This will also install curl and git which will also be needed:

```sh
curl https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh > brew-install.sh

bash brew-install.sh
```

## Install MySQL and etcd

Once brew is installed you will need to install some dependencies for Vitess. Vitess supports the databases listed [here](../../overview/supported-databases/): 

```sh
brew install automake go mysql mysql-client etcd
```

When MySQL installs with brew it will startup, you will want to shut this process down, as Vitess will be managing the startup and shutdown of MySQL:

```sh
brew services stop mysql
```

### Install Node 16.13.0+ (required to run VTAdmin)

```bash
brew install nvm
nvm install --lts 16.13.0
nvm use 16.13.0
```

See the [vtadmin README](https://github.com/vitessio/vitess/blob/main/web/vtadmin/README.md) for more details.

## PATH Settings

With the tools you’ve just installed via brew, you will next update your PATH variable so your shell knows where to find the binaries:

```sh
echo “export PATH=${PATH}:/opt/homebrew/opt/mysql-client/bin:/opt/homebrew/opt/mysql/bin:~/Github/vitess/bin:/Users/jason/go/bin:​​/opt/homebrew/bin” >> ~/.zshrc
source ~/.zshrc
```

If you’re using bash for your shell you’ll have to update the paths in `.bash_profile` or `.bashrc` instead. Mac does not read `.bashrc` by default:

```sh
echo “export PATH=${PATH}:/opt/homebrew/opt/mysql-client/bin:/opt/homebrew/opt/mysql/bin:~/Github/vitess/bin:/Users/jason/go/bin:/opt/homebrew/bin” >> ~/.bash_profile
source ~/.bash_profile
```

## System Check

Before going further, you should check to confirm your shell has access to `go`, `mysql`, and `mysqld`. If versions are not returned when you run the following commands you should check that the programs are installed and the path is correct for your shell: 

```sh
mysqld --version
mysql --version
go version
etcd --version
node --version
npm --version
```

## Install Vitess

With everything now in place you can clone and build Vitess.

```sh
git clone https://github.com/vitessio/vitess.git
cd vitess
git checkout release-16.0
make build
```

It will take some time for Vitess to build. Once it completes you should see a bin folder which will hold the Vitess binaries. You will need to add this folder to your `PATH` variable as well: 

```sh
cd bin
echo "$(printf 'export PATH="${PATH}:'; echo "$(pwd)\"")" >> ~/.zshrc
source ~/.zshrc
```

If you are using bash this will need to be your `.bash_profile` or `.bashrc` file instead:

```sh
cd bin
echo "$(printf 'export PATH="${PATH}:'; echo "$(pwd)\"")" >> ~/.bash_profile
source ~/.bash_profile
```

You are now ready to start your first cluster! Open a new terminal window to ensure your `.bashrc` file changes take effect. 

## Start a Single Keyspace Cluster

You are now ready to stand up your first Vitess cluster, using the example scripts provided in the source code. Assuming you are still in the bin directory you will need to navigate to the sample files:

```sh
cd ../examples/local/
```

From here you can startup the cluster and source the env file which will help set environment variables used when working with this local cluster: 

```sh
./101_initial_cluster.sh
source ../common/env.sh
```

You should see an output similar to the following:

```text
$ ./101_initial_cluster.sh 
add /vitess/global
add /vitess/zone1
add zone1 CellInfo
Created cell: zone1
etcd start done...
Starting vtctld...
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
    "durability_policy": "semi_sync"
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


> vtadmin@0.1.0 build
> react-scripts build

Creating an optimized production build...
Browserslist: caniuse-lite is outdated. Please run:
  npx browserslist@latest --update-db
  Why you should do it regularly: https://github.com/browserslist/browserslist#browsers-data-updating
Browserslist: caniuse-lite is outdated. Please run:
  npx browserslist@latest --update-db
  Why you should do it regularly: https://github.com/browserslist/browserslist#browsers-data-updating
Compiled successfully.

File sizes after gzip:

  385.49 kB  build/static/js/main.044e444c.js
  15.4 kB    build/static/css/main.a46ccb6f.css

The project was built assuming it is hosted at /.
You can control this with the homepage field in your package.json.

The build folder is ready to be deployed.
You may serve it with a static server:

  npm install -g serve
  serve -s build

Find out more about deployment here:

  https://cra.link/deployment

vtadmin-web is running!
  - Browser: http://localhost:14201
  - Logs: /Users/manangupta/vitess/vtdataroot/tmp/vtadmin-web.out
  - PID: 74070
```

If you encounter any errors, such as ports already in use, you can kill the processes and start over. Ensure you're in the vitess/examples/local directory, then issue the statement to kill the processes and remove the data directory. 
This data directory `vtdataroot` will get recreated when you run the 101_initial_cluster.sh startup script again.

```sh
user@computer:~/Github/vitess/examples/local$ pwd
/home/user/Github/vitess/examples/local

user@computer:~/Github/vitess/examples/local$ pkill -9 -f '(vtdataroot|VTDATAROOT|vitess|vtadmin)'
etcd killed (pid 224091)
vtctld killed (pid 224154)
mysqld_safe killed (pid 224247)
mysqld killed (pid 224716)
vttablet killed (pid 224764)
mysqld_safe killed (pid 224897)
mysqld killed (pid 225364)
vttablet killed (pid 225413)
mysqld_safe killed (pid 225529)
mysqld killed (pid 225995)
vttablet killed (pid 226045)
vtgate killed (pid 226204)
vtadmin killed (pid 226391)
vtorc killed (pid 226397)

user@computer:~/Github/vitess/examples/local$ rm -rf ./vtdataroot
```

## Connect to your cluster

You should now be able to connect to the VTGate server that was started in `101_initial_cluster.sh`:

```sh
mysql -P 15306 -u root --protocol tcp
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

Or alternatively, once you are finished with the local examples or if you would like to start over, you can clean up by running the 401_teardown script:

```sh
./401_teardown.sh
rm -rf ./vtdataroot
```

Sometimes you will still need to manually kill processes if there are errors in the environment:

```sh
pkill -9 -f ./vtdataroot
rm -rf ./vtdataroot
```
