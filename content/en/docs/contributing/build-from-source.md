---
title: Build From Source
description: Instructions for building Vitess on your machine for testing and development purposes
---

{{< info >}}
If you run into issues or have questions, we recommend posting in our [Slack channel](https://vitess.slack.com), click the Slack icon in the top right to join. This is a very active community forum and a great place to interact with other users.
{{< /info >}}

The following sections explain the process for manually building Vitess on Linux and macOS. If you are new to Vitess, it is recommended to start with the [local install](../../get-started/local) guide instead.

### Install Dependencies

Many of the Vitess developers use Ubuntu or macOS desktops. If you would like to extend this guide for `yum` based distributions, please [send us a pull request](https://github.com/vitessio/website).

#### Ubuntu and Debian

In addition, Vitess requires the following software and libraries:

1.  [Install Go 1.12+](http://golang.org/doc/install).

The version included in your OS distribution may be older than this. You can check by running `go version`.

2.  We recommend that you uninstall or disable AppArmor since it may cause permission failures when Vitess initializes MySQL instances through the `mysqlctl` tool. This is an issue only in test environments. If AppArmor is necessary in production, you can configure the MySQL instances appropriately without using `mysqlctl`:

    ```sh
    sudo service apparmor stop
    sudo service apparmor teardown # safe to ignore if this errors
    sudo update-rc.d -f apparmor remove
    ```

    Reboot to be sure that AppArmor is fully disabled.

3.  Install dependencies required to build and run Vitess:

    ```sh
    # On Apt based systems
    sudo apt-get install -y mysql-server mysql-client make unzip g++ etcd curl
    ```

    **Notes:**
    * Vitess currently has some tests written in Python, but this dependency can be avoided by running the tests in Docker (recommended).
    * The `bootstrap.sh` script can also install Zookeeper for you, which requires additional dependencies. For this guide, we will use etcd instead and skip this step.

4. [Install Docker](https://docs.docker.com/install/)

Docker is required to run the Vitess testsuite. Should you decide to skip this step, you will still be able to compile and run Vitess.

#### Mac OS

1.  [Install Homebrew](http://brew.sh/). If your `/usr/local` directory is not empty and you haven't yet used Homebrew, you need to run the following command:

    ```sh
    sudo chown -R $(whoami):admin /usr/local
    ```

2.  Install [Xcode](https://developer.apple.com/xcode/).

3.  Install [etcd v3.0+](https://github.com/coreos/etcd/releases). Remember to include `etcd` command on your path.

4.  Run the following commands:

    ```sh
    brew install go automake git curl wget mysql57
    ```

5.  The Vitess bootstrap script makes some checks for the go runtime, so it is recommended to have the following commands in your `~/.profile`, `~/.bashrc`, `~/.zshrc`, or `~/.bash_profile`:

    ```sh
    export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"
    export PATH=/usr/local/go/bin:$PATH
    export GOROOT=/usr/local/go
    ```

6.  For the Vitess hostname resolving functions to work correctly, a new entry has to be added into the /etc/hosts file with the current LAN IP address of the computer (preferably IPv4) and the current hostname, which you get by typing the 'hostname' command in the terminal.

    It is also a good idea to put the following line to [force the Go DNS resolver](https://golang.org/doc/go1.5#net) in your `~/.profile` or `~/.bashrc` or `~/.zshrc`:

    ```sh
    export GODEBUG=netdns=go
    ```

## Build Vitess

1. Navigate to the directory where you want to download the Vitess source code and clone the Vitess GitHub repo. After doing so, navigate to the `src/vitess.io/vitess` directory.

    ```sh
    cd $WORKSPACE
    git clone https://github.com/vitessio/vitess.git \
        src/vitess.io/vitess
    cd src/vitess.io/vitess
    ```
2. Build Vitess using the commands below. Note that the `bootstrap.sh` script needs to download some dependencies. If your machine requires a proxy to access the Internet, you will need to set the usual environment variables (e.g. `http_proxy`, `https_proxy`, `no_proxy`).

    Run the boostrap.sh script:

    ```sh
    BUILD_PYTHON=0 BUILD_JAVA=0 ./bootstrap.sh
    ```

    Build Vitess:

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

This error may mean your disk is too slow. If you don't have access to an SSD, you can try testing on a RAM disk.

##### Connection refused to tablet, MySQL socket not found, etc.

These errors might indicate that the machine ran out of RAM and a server crashed when trying to allocate more RAM. Some of the heavier tests require up to 8GB RAM.

##### Running out of disk space

Some of the larger tests use up to 4GB of temporary space on disk.

##### Too Many Open Files

Some Linux distributions ship with default file descriptor limits that are too low for database servers. This issue could show up as the database crashing with the message “too many open files”. Check the system-wide file-max setting as well as user-specific ulimit values. We recommend setting them above 100K to be safe. The exact procedure may vary depending on your Linux distribution.

### Next steps

Congratulations! You now have Vitess built locally. You can complete additional exercises by following along with [Run Vitess Locally](../../get-started/local) guide.
