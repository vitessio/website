---
title: Build From Source
description: Instructions for building Vitess on your machine for testing and development purposes
weight: 1
featured: true
---

{{< info >}}
If you run into issues or have questions, we recommend posting in our [Slack channel](https://vitess.slack.com), click the Slack icon in the top right to join. This is a very active community forum and a great place to interact with other users.
{{< /info >}}

## Build From Source

The following sections explain the process for manually building Vitess on Linux and macOS. If you are new to Vitess, it is recommended to start with the [local install](../../tutorial/local) guide instead.

### Install Dependencies

We currently test Vitess regularly on Ubuntu 14.04 (Trusty) and Debian 8 (Jessie). macOS 10.11 (El Capitan) and above should work as well. The installation instructions are [below](#macos).

#### Ubuntu and Debian

In addition, Vitess requires the following software and libraries:

1.  [Install Go 1.11+](http://golang.org/doc/install).

2. Install MySQL:
```bash
# Apt based
sudo apt-get install mysql-server
# Yum based
sudo yum install mysql-server
```

_Vitess supports MySQL 5.6+ and MariaDB 10.0+. We recommend MySQL 5.7 if your installation method provides a choice._

3.  Uninstall or disable [AppArmor](https://wiki.ubuntu.com/AppArmor). Some versions of MySQL come with default AppArmor configurations that the Vitess tools don't yet recognize. This causes various permission failures when Vitess initializes MySQL instances through the `mysqlctl` tool. This is an issue only in test environments. If AppArmor is necessary in production, you can configure the MySQL instances appropriately without going through `mysqlctl`.

    ```sh
    sudo service apparmor stop
    sudo service apparmor teardown # safe to ignore if this errors
    sudo update-rc.d -f apparmor remove
    ```

    Reboot to be sure that AppArmor is fully disabled.

4.  Install [etcd v3.0+](https://github.com/coreos/etcd/releases). Remember to include `etcd` command on your path.

    We will use ectd for the [topology service](../../overview/concepts). Vitess also includes built-in support for [ZooKeeper](https://zookeeper.apache.org) and [Consul](https://www.consul.io/).

5.  Install the following other tools needed to build and run Vitess:

    - make
    - automake
    - libtool
    - python-dev
    - python-virtualenv
    - python-mysqldb
    - libssl-dev
    - g++
    - git
    - pkg-config
    - bison
    - curl
    - unzip

    These can be installed with the following apt-get command:

    ```sh
    $ sudo apt-get install make automake libtool python-dev python-virtualenv python-mysqldb libssl-dev g++ git pkg-config bison curl unzip
    ```

#### Mac OS

1.  [Install Homebrew](http://brew.sh/). If your `/usr/local` directory is not empty and you haven't yet used Homebrew, you need to run the following command:

    ```sh
    sudo chown -R $(whoami):admin /usr/local
    ```

2.  If [Xcode](https://developer.apple.com/xcode/) is installed (with Console tools, which should be bundled
    automatically since version 7.1), all the dev dependencies should be satisfied in this step. If Xcode isn't present, you'll need to install [pkg-config](https://www.freedesktop.org/wiki/Software/pkg-config/).

    ```sh
    brew install pkg-config
    ```

3.  Install [etcd v3.0+](https://github.com/coreos/etcd/releases). Remember to include `etcd` command on your path.

    We will use ectd for the [topology service](../../overview/concepts). Vitess also includes built-in support for [ZooKeeper](https://zookeeper.apache.org) and [Consul](https://www.consul.io/).

5.  Run the following commands:

    ```sh
    brew install go ant automake libtool python git bison curl wget mysql57
    pip install --upgrade pip setuptools
    pip install virtualenv
    pip install MySQL-python
    pip install tox
    ```

6.  The Vitess bootstrap script makes some checks for the go runtime, so it is recommended to have the following commands in your `~/.profile`, `~/.bashrc`, `~/.zshrc`, or `~/.bash_profile`:

    ```sh
    export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"
    export PATH=/usr/local/go/bin:$PATH
    export GOROOT=/usr/local/go
    ```

7.  For the Vitess hostname resolving functions to work correctly, a new entry has to be added into the /etc/hosts file with the current LAN IP address of the computer (preferably IPv4) and the current hostname, which you get by typing the 'hostname' command in the terminal.

    It is also a good idea to put the following line to [force the Go DNS resolver](https://golang.org/doc/go1.5#net) in your `~/.profile` or `~/.bashrc` or `~/.zshrc`:

    ```sh
    export GODEBUG=netdns=go
    ```

## Build Vitess

1. Navigate to the directory where you want to download the Vitess source code and clone the Vitess Github repo. After doing so, navigate to the `src/vitess.io/vitess` directory.

    ```sh
    cd $WORKSPACE
    git clone https://github.com/vitessio/vitess.git \
        src/vitess.io/vitess
    cd src/vitess.io/vitess
    ```

2. Set the `MYSQL_FLAVOR`:
```sh
# It is recommended to use MySQL56 even for MySQL 5.7 and 8.0. For MariaDB you can use MariaDB:
export MYSQL_FLAVOR=MySQL56
```

3. If your selected database installed in a location other than `/usr/bin`, set the `VT_MYSQL_ROOT` variable to the root directory of your MySQL installation:

    ```sh
    # For generic tarballs on Linux
    export VT_MYSQL_ROOT=/usr/local/mysql

    # On macOS with Homebrew
    export VT_MYSQL_ROOT=/usr/local/opt/mysql@5.7
    ```

    Note that the command indicates that the `mysql` executable should be found at `/usr/local/opt/mysql@5.7/bin/mysql`.

4. Run `mysqld --version` and confirm that you are running MySQL 5.7.

5. Build Vitess using the commands below. Note that the `bootstrap.sh` script needs to download some dependencies. If your machine requires a proxy to access the Internet, you will need to set the usual environment variables (e.g. `http_proxy`, `https_proxy`, `no_proxy`).

    Run the boostrap.sh script:

    ```sh
    BUILD_TESTS=0 ./bootstrap.sh
    ### example output:
    # skipping zookeeper build
    # go install golang.org/x/tools/cmd/cover ...
    # Found MariaDB installation in ...
    # creating git pre-commit hooks
    #
    # source dev.env in your shell before building
    ```

    ```sh
    # Remaining commands to build Vitess
    source ./dev.env
    make build
    ```

#### Common Build Issues

{{< info >}}
If you run into issues or have questions, we recommend posting in our [Slack channel](https://vitess.slack.com), click the Slack icon in the top right to join. This is a very active community forum and a great place to interact with other users.
{{< /info >}}

##### Python Errors

The end-to-end test suite currently requires Python 2.7. We are working on removing this dependency, but in the mean time you can run tests from within Docker. The MySQL 5.7 container provided includes the required dependencies:

```bash
make docker_test flavor=mysql57
```

##### Node already exists, port in use, etc.

A failed test can leave orphaned processes. If you use the default settings, you can use the following commands to identify and kill those processes:

```sh
pgrep -f -l '(vtdataroot|VTDATAROOT)' # list Vitess processes
pkill -f '(vtdataroot|VTDATAROOT)' # kill Vitess processes
```

##### Too many connections to MySQL, or other timeouts

This error may mean your disk is too slow. If you don't have access to an SSD, you can try [testing against a ramdisk](https://github.com/vitessio/vitess/blob/master/doc/TestingOnARamDisk.md).

##### Connection refused to tablet, MySQL socket not found, etc.

These errors might indicate that the machine ran out of RAM and a server crashed when trying to allocate more RAM. Some of the heavier tests require up to 8GB RAM.

##### Running out of disk space

Some of the larger tests use up to 4GB of temporary space on disk.

##### Too Many Open Files

Some Linux distributions ship with default file descriptor limits that are too low for database servers. This issue could show up as the database crashing with the message “too many open files”. Check the system-wide file-max setting as well as user-specific ulimit values. We recommend setting them above 100K to be safe. The exact procedure may vary depending on your Linux distribution.

## Starting a single keyspace cluster

You can quickly test out your Vitess build by using one of the included local examples. `101_initial_cluster.sh` starts an initial Vitess cluster with a single keyspace:

``` sh
cd examples/local
./101_initial_cluster.sh
```

### Verify cluster

Once successful, you should see the following state:

``` sh
$ pgrep -fl vtdataroot
5451 zksrv.sh
5452 zksrv.sh
5453 zksrv.sh
5463 java
5464 java
5465 java
5627 vtctld
5762 mysqld_safe
5767 mysqld_safe
5799 mysqld_safe
10162 mysqld
10164 mysqld
10190 mysqld
10281 vttablet
10282 vttablet
10283 vttablet
10447 vtgate
```

You should now be able to connect to the cluster using the following command:

``` sh
$ mysql -h 127.0.0.1 -P 15306
Welcome to the MySQL monitor.  Commands end with ; or \g.
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

You can also browse to the vtctld console using the following URL:

```
http://localhost:15000
```

### Next steps

Congratulations! You now have a local vitess cluster up and running. You can complete additional exercises by following along with [Run Vitess Locally](../../tutorial/local) guide.
