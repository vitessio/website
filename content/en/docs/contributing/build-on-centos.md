---
title: Build on CentOS
description: Instructions for building Vitess on your machine for testing and development purposes
aliases: ['/docs/contributing/build-from-source/']
---

{{< info >}}
If you run into issues or have questions, we recommend posting in our [Slack channel](https://vitess.slack.com), click the Slack icon in the top right to join. This is a very active community forum and a great place to interact with other users.
{{< /info >}}

The following has been verified to work on __Centos 7__. If you are new to Vitess, it is recommended to start with the [local install](../../get-started/local) guide instead.

## Install Dependencies

### Install Go 1.12+

[Download and install](http://golang.org/doc/install) the latest version of Golang. For example, at writing:

```
curl -O https://dl.google.com/go/go1.13.3.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.13.3.linux-amd64.tar.gz
```

Make sure to add go to your bashrc:
```
export PATH=$PATH:/usr/local/go/bin
```

### Packages from CentOS repos

The MariaDB version included with CentOS 7 (5.5) is not supported by Vitess. First install the MySQL 5.7 repository from Oracle:

```
sudo yum localinstall -y https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
sudo yum install -y mysql-community-server
```

Install additional dependencies required to build and run Vitess:

```
sudo yum install -y make unzip g++ etcd curl git wget
```

**Notes:**

* Vitess currently has some tests written in Python, but this dependency can be avoided by running the tests in Docker (recommended).
* We will be using etcd as the topology service. The `bootstrap.sh` script can also install Zookeeper or Consul for you, which requires additional dependencies.

### Disable SELinux

SELinux will not allow Vitess to launch MySQL in any data directory by default. You will need to disable it:

```
sudo setenforce 0
```

### Install Docker

Running the testsuite requires that you [install Docker](https://docs.docker.com/install/). Should you decide to skip this step, you will still be able to compile and run Vitess.

## Build Vitess

Navigate to the directory where you want to download the Vitess source code and clone the Vitess GitHub repo. After doing so, navigate to the `src/vitess.io/vitess` directory.

```
mkdir -p ~/vitess
cd ~/vitess
git clone https://github.com/vitessio/vitess.git \
    src/vitess.io/vitess
cd src/vitess.io/vitess
```

Set environment variables that Vitess will require. It is recommended to put these in your `.bashrc`:

```
# Additions to ~/.bashrc file

# Add go PATH
export PATH=$PATH:/usr/local/go/bin

# Vitess
export VTROOT=~/vitess
export VTTOP=~/vitess/src/vitess.io/vitess
export VTDATAROOT=~/vitess/vtdataroot
export PATH=${VTROOT}/bin:${PATH}
```

Run `bootstrap.sh` script to download additional dependencies. If your machine requires a proxy to access the Internet, you will need to set the usual environment variables (e.g. `http_proxy`, `https_proxy`, `no_proxy`):

```
BUILD_PYTHON=0 BUILD_JAVA=0 ./bootstrap.sh
```

Build Vitess:

```
source ./dev.env
make build
```

## Testing your Binaries

Run the included local example:

```
cd examples/local
./101_initial_cluster.sh
```

You should see the following:
```
$ ./101_initial_cluster.sh 
[morgo@localhost local]$ ./101_initial_cluster.sh
enter etcd2 env
add /vitess/global
add /vitess/zone1
add zone1 CellInfo
etcd start done...
enter etcd2 env
Starting vtctld...
Access vtctld web UI at http://localhost:15000
Send commands with: vtctlclient -server localhost:15999 ...
enter etcd2 env
Starting MySQL for tablet zone1-0000000100...
Starting MySQL for tablet zone1-0000000101...
Starting MySQL for tablet zone1-0000000102...
Starting vttablet for zone1-0000000100...
Access tablet zone1-0000000100 at http://localhost:15100/debug/status
Starting vttablet for zone1-0000000101...
Access tablet zone1-0000000101 at http://localhost:15101/debug/status
Starting vttablet for zone1-0000000102...
Access tablet zone1-0000000102 at http://localhost:15102/debug/status
Waiting for tablets to be listening...
Tablets up!
W1028 09:30:40.634534    7333 main.go:64] W1028 15:30:40.630786 reparent.go:182] master-elect tablet zone1-0000000100 is not the shard master, proceeding anyway as -force was used
W1028 09:30:40.634792    7333 main.go:64] W1028 15:30:40.631267 reparent.go:188] master-elect tablet zone1-0000000100 is not a master in the shard, proceeding anyway as -force was used
New VSchema object:
{
  "tables": {
    "corder": {

    },
    "customer": {

    },
    "product": {

    }
  }
}
If this is not what you expected, check the input data (as JSON parsing will skip unexpected fields).
enter etcd2 env
Waiting for vtgate to be up...
vtgate is up!
Access vtgate at http://localhost:15001/debug/status
```

You can continue the remaining parts of this example by following the [local](../../get-started/local) get started guide.

### Full testsuite

To run the testsuite in Docker:

```
make docker_test flavor=mysql57
```

Running the full suite currently takes 2+ hours to complete.

## Common Build Issues

{{< info >}}
If you run into issues or have questions, we recommend posting in our [Slack channel](https://vitess.slack.com), click the Slack icon in the top right to join. This is a very active community forum and a great place to interact with other users.
{{< /info >}}

### Key Already Exists

This error is because etcd was not cleaned up from the previous run of the example. You can manually fix this by running `./401_teardown.sh` and then start again:
```
Error:  105: Key already exists (/vitess/zone1) [6]
Error:  105: Key already exists (/vitess/global) [6]
```

### MySQL Fails to Initialize

This error is most likely the result of SELinux enabled:

```
1027 18:28:23.462926   19486 mysqld.go:734] mysqld --initialize-insecure failed: /usr/sbin/mysqld: exit status 1, output: mysqld: [ERROR] Failed to open required defaults file: /home/morgo/vitess/vtdataroot/vt_0000000102/my.cnf
mysqld: [ERROR] Fatal error in defaults handling. Program aborted!

could not stat mysql error log (/home/morgo/vitess/vtdataroot/vt_0000000102/error.log): stat /home/morgo/vitess/vtdataroot/vt_0000000102/error.log: no such file or directory
E1027 18:28:23.464117   19486 mysqlctl.go:254] failed init mysql: /usr/sbin/mysqld: exit status 1, output: mysqld: [ERROR] Failed to open required defaults file: /home/morgo/vitess/vtdataroot/vt_0000000102/my.cnf
mysqld: [ERROR] Fatal error in defaults handling. Program aborted!
E1027 18:28:23.464780   19483 mysqld.go:734] mysqld --initialize-insecure failed: /usr/sbin/mysqld: exit status 1, output: mysqld: [ERROR] Failed to open required defaults file: /home/morgo/vitess/vtdataroot/vt_0000000101/my.cnf
mysqld: [ERROR] Fatal error in defaults handling. Program aborted!
```

### Python Errors

The end-to-end test suite currently requires Python 2.7. We are working on removing this dependency, but in the mean time you can run tests from within Docker. The MySQL 5.7 container provided includes the required dependencies:

```
make docker_test flavor=mysql57
```

### No .installed_version file

This error indicates that you have not put the required vitess environment variables in your `.bashrc` file:

```
enter etcd2 env
cat: /dist/etcd/.installed_version: No such file or directory
```

Make sure the following variables are defined:
```
export VTROOT=~/vitess
export VTTOP=~/vitess/src/vitess.io/vitess
export VTDATAROOT=~/vitess/vtdataroot
export PATH=${VTROOT}/bin:${PATH}
```

### Cannot create dir /etcd

This indicates that the environment variable `VTDATAROOT` is not defined, and you have not put the required vitess environment variables in your `.bashrc` file:

```
./101_initial_cluster.sh
enter etcd2 env
mkdir: cannot create directory ‘/etcd’: Permission denied
```

Make sure the following variables are defined:
```
export VTROOT=~/vitess
export VTTOP=~/vitess/src/vitess.io/vitess
export VTDATAROOT=~/vitess/vtdataroot
export PATH=${VTROOT}/bin:${PATH}
```

