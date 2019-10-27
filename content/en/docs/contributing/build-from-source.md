---
title: Build From Source
description: Instructions for building Vitess on your machine for testing and development purposes
---

{{< info >}}
If you run into issues or have questions, we recommend posting in our [Slack channel](https://vitess.slack.com), click the Slack icon in the top right to join. This is a very active community forum and a great place to interact with other users.
{{< /info >}}

The following sections explain the process for manually building Vitess on Linux and macOS. If you are new to Vitess, it is recommended to start with the [local install](../../get-started/local) guide instead.

## Install Dependencies

Many of the Vitess developers use Ubuntu or macOS desktops. If you would like to extend this guide for `yum` based distributions, please [send us a pull request](https://github.com/vitessio/website).

### Ubuntu and Debian

In addition, Vitess requires the following software and libraries:

#### Install Go 1.12+

[Install Go 1.12+](http://golang.org/doc/install).
The version included in your OS distribution may be older than this. You can check by running `go version`.

#### Disable AppArmor

We recommend that you uninstall or disable AppArmor since it may cause permission failures when Vitess initializes MySQL instances through the `mysqlctl` tool. This is an issue only in test environments. If AppArmor is necessary in production, you can configure the MySQL instances appropriately without using `mysqlctl`:

```sh
sudo service apparmor stop
sudo service apparmor teardown # safe to ignore if this errors
sudo update-rc.d -f apparmor remove
```
Reboot to be sure that AppArmor is fully disabled.

#### Install Dependencies

Install dependencies required to build and run Vitess:

```sh
sudo apt-get install -y mysql-server mysql-client make unzip g++ etcd curl
```

**Notes:**
* Vitess currently has some tests written in Python, but this dependency can be avoided by running the tests in Docker (recommended).
* We will be using etcd as the topology service. The `bootstrap.sh` script can also install Zookeeper or Consul for you, which requires additional dependencies.

#### Install Docker

[Install Docker](https://docs.docker.com/install/). This is only required to run the Vitess testsuite. Should you decide to skip this step, you will still be able to compile and run Vitess.

### macOS

#### Install Xcode

[Install Xcode](https://developer.apple.com/xcode/).

#### Install Homebrew

[Install Homebrew](http://brew.sh/). If your `/usr/local` directory is not empty and you haven't yet used Homebrew, you need to run the following command:

```sh
sudo chown -R $(whoami):admin /usr/local
```

#### Install Dependencies

Run the following command:

```sh
brew install go automake git curl wget mysql57 etcd
```

#### Install Docker

[Install Docker](https://docs.docker.com/docker-for-mac/). This is only required to run the Vitess testsuite. Should you decide to skip this step, you will still be able to compile and run Vitess.

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

## Common Build Issues

{{< info >}}
If you run into issues or have questions, we recommend posting in our [Slack channel](https://vitess.slack.com), click the Slack icon in the top right to join. This is a very active community forum and a great place to interact with other users.
{{< /info >}}

### Python Errors

The end-to-end test suite currently requires Python 2.7. We are working on removing this dependency, but in the mean time you can run tests from within Docker. The MySQL 5.7 container provided includes the required dependencies:

```bash
make docker_test flavor=mysql57
```

## Next steps

Congratulations! You now have Vitess built locally. You can complete additional exercises by following along with [Run Vitess Locally](../../get-started/local) guide.
