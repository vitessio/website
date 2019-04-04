---
title: Building from Source
description: Instructions for building Vitess from source for testing and development purposes
weight: 3
featured: true
---

You can build Vitess using the [manual](#manual) build process outlined below.

{{< info >}}
If you run into issues or have questions, we recommend posting in our [Slack channel](https://vitess.slack.com), click the Slack icon in the top right to join. This is a very active community forum and a great place to interact with other users.
{{< /info >}}

## Manual Build

The following sections explain the process for manually building Vitess on Linux without using Docker.

### Install Dependencies

We currently test Vitess regularly on Ubuntu 14.04 (Trusty) and Debian 8 (Jessie).
macOS 10.11 (El Capitan) should work as well. The installation instructions are [below](#macos).

#### Ubuntu and Debian

In addition, Vitess requires the software and libraries listed below.

1.  [Install Go 1.11+](http://golang.org/doc/install).

2.  Install [MariaDB 10.0 (or later)](https://downloads.mariadb.org/) or [MySQL 5.6 (or later)](http://dev.mysql.com/downloads/mysql). You can use any installation method (src/bin/rpm/deb), but be sure to include the client development headers (`libmariadbclient-dev` or `libmysqlclient-dev`).

    Vitess tests are written to run against all MySQL and MariaDB flavors (mysql 5.6, MySql 5.7, MariaDB 10.2, MariaDB 10.3, Percona 5.6, Percona 5.7 as of this writing), however the CI system only uses the MySQL 5.7 images to run the official tests.

    If you are installing MariaDB, note that you must install version 10.0 or higher. If you are using `apt-get`, confirm that your repository offers an option to install that version. You can also download the source directly from [mariadb.org](https://downloads.mariadb.org/mariadb/).

    If you are using Ubuntu 14.04 with MySQL 5.6, the default install may be missing a file too, `/usr/share/mysql/my-default.cnf`. It would show as an error like `Could not find my-default.cnf`. If you run into this, just add
    it with the following contents:

    ``` sh
    conf
	  [mysqld]
	  sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
    ```

3.  Uninstall or disable [AppArmor](https://wiki.ubuntu.com/AppArmor). Some versions of MySQL come with default AppArmor configurations that the Vitess tools don't yet recognize. This causes various permission failures when Vitess initializes MySQL instances through the `mysqlctl` tool. This is an issue only in test environments. If AppArmor is necessary in production, you can configure the MySQL instances appropriately without going through `mysqlctl`.

    ```sh
    $ sudo service apparmor stop
    $ sudo service apparmor teardown
    $ sudo update-rc.d -f apparmor remove
    ```

    Reboot to be sure that AppArmor is fully disabled.


4.  Select a lock service from the options listed below. It is technically possible to use another lock server, but plugins currently exist only for [ZooKeeper](https://zookeeper.apache.org), [etcd](https://coreos.com/etcd/), and [Consul](https://www.consul.io/).

    - ZooKeeper 3.4.10 is included by default.
    - Install [etcd v3.0+](https://github.com/coreos/etcd/releases). If you use etcd, remember to include the `etcd` command on your path.
    - Install [Consul](https://www.consul.io/). If you use Consul, remember to include the `consul` command on your path.

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

6.  If you've opted to use ZooKeeper in step 3, you also need to install a
    Java runtime, such as [OpenJDK](https://openjdk.java.net/).

    ```sh
    $ sudo apt-get install openjdk-8-jre
    ```

#### Mac OS

1.  [Install Homebrew](http://brew.sh/). If your `/usr/local` directory is not empty and you haven't yet used Homebrew, you need to run the following command:

    ```sh
    sudo chown -R $(whoami):admin /usr/local
    ```

2.  On Mac OS, you must use MySQL 5.6, as MariaDB does not yet work. MySQL should be installed using Homebrew
    (install steps are below).

3.  If [Xcode](https://developer.apple.com/xcode/) is installed (with Console tools, which should be bundled
    automatically since version 7.1), all the dev dependencies should be satisfied in this step. If Xcode isn't present, you'll need to install [pkg-config](https://www.freedesktop.org/wiki/Software/pkg-config/).

    ```sh
    brew install pkg-config
    ```

4.  ZooKeeper is used as a lock service.

5.  Run the following commands:

    ```sh
    brew install go automake libtool python git bison curl wget mysql56
    pip install --upgrade pip setuptools
    pip install virtualenv
    pip install MySQL-python
    pip install tox
    ```

6.  The Vitess bootstrap script makes some checks for the go runtime, so it is recommended to have the following commands in your `~/.profile`, `~/.bashrc`, `~/.zshrc`, or `~/.bash_profile`:

    ```sh
    export PATH="/usr/local/opt/mysql@5.6/bin:$PATH"
    export PATH=/usr/local/go/bin:$PATH
    export GOROOT=/usr/local/go
    ```

7.  For the Vitess hostname resolving functions to work correctly, a new entry has to be added into the /etc/hosts file with the current LAN IP address of the computer (preferably IPv4) and the current hostname, which you get by typing the 'hostname' command in the terminal.

    It is also a good idea to put the following line to [force the Go DNS resolver](https://golang.org/doc/go1.5#net) in your ~/.profile or ~/.bashrc or ~/.zshrc:

    ```sh
    export GODEBUG=netdns=go
    ```

### Build Vitess

1. Navigate to the directory where you want to download the Vitess source code and clone the Vitess Github repo. After doing so, navigate to the `src/vitess.io/vitess` directory. For go to work correctly, you should create a symbolic link to this inside your `${HOME}/go/src`

    ```sh
    cd $WORKSPACE
    git clone https://github.com/vitessio/vitess.git \
        src/vitess.io/vitess
    ln -s $(pwd)/src/vitess.io ${HOME}/go/src/vitess.io
    cd ${HOME}/go/src/vitess.io/vitess
    ```

2. Set the `MYSQL_FLAVOR` environment variable. Choose the appropriate value for your database. This value is case-sensitive.

    ```sh
    # export MYSQL_FLAVOR=MariaDB
    # or (mandatory for macOS)
    export MYSQL_FLAVOR=MySQL56
    ```

3. If your selected database installed in a location other than `/usr/bin`, set the `VT_MYSQL_ROOT` variable to the root directory of your MariaDB installation. For example, if mysql is installed in `/usr/local/mysql`, run the following command.

    ```sh
    # export VT_MYSQL_ROOT=/usr/local/mysql

    # on macOS, this is the correct value:
    export VT_MYSQL_ROOT=/usr/local/opt/mysql@5.6
    ```

    Note that the command indicates that the `mysql` executable should be found at `/usr/local/opt/mysql@5.6/bin/mysql`.

4. Run `mysqld --version` and confirm that you are running the correct version of MariaDB or MySQL. The value should be 10 or higher for MariaDB and 5.6.x for MySQL.

5. Build Vitess using the commands below. Note that the `bootstrap.sh` script needs to download some dependencies. If your machine requires a proxy to access the Internet, you will need to set the usual environment variables (e.g. `http_proxy`, `https_proxy`, `no_proxy`).

    Run the boostrap.sh script:

    ```sh
    ./bootstrap.sh
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

#### Common Test Issues

Attempts to run the full developer test suite (`make test`) on an underpowered machine often results in failure. If you still see the same failures when running the lighter set of tests (`make site_test`), please let the development team know in the [vitess@googlegroups.com](https://groups.google.com/forum/#!forum/vitess) discussion forum.

##### Node already exists, port in use, etc.

A failed test can leave orphaned processes. If you use the default settings, you can use the following commands to identify and kill those processes:

```sh
pgrep -f -l '(vtdataroot|VTDATAROOT)' # list Vitess processes
pkill -f '(vtdataroot|VTDATAROOT)' # kill Vitess processes
```

##### Too many connections to MySQL, or other timeouts

This error often means your disk is too slow. If you don't have access to an SSD, you can try [testing against a ramdisk](https://github.com/vitessio/vitess/blob/master/doc/TestingOnARamDisk.md).

##### Connection refused to tablet, MySQL socket not found, etc.

These errors might indicate that the machine ran out of RAM and a server crashed when trying to allocate more RAM. Some of the heavier tests require up to 8GB RAM.

##### Connection refused in zkctl test

This error might indicate that the machine does not have a Java Runtime installed, which is a requirement if you are using ZooKeeper as the lock server.

##### Running out of disk space

Some of the larger tests use up to 4GB of temporary space on disk.
