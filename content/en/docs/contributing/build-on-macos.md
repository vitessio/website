---
title: Build on macOS
description: Instructions for building Vitess on your machine for testing and development purposes
---

{{< info >}}
If you run into issues or have questions, we recommend posting in our [Slack channel](https://vitess.slack.com), click the Slack icon in the top right to join. This is a very active community forum and a great place to interact with other users.
{{< /info >}}

The following has been verified to work on __TODO__. If you are new to Vitess, it is recommended to start with the [local install](../../get-started/local) guide instead.

## Install Dependencies

### Install Xcode

[Install Xcode](https://developer.apple.com/xcode/).

### Install Homebrew

[Install Homebrew](http://brew.sh/). If your `/usr/local` directory is not empty and you haven't yet used Homebrew, you need to run the following command:

```
sudo chown -R $(whoami):admin /usr/local
```

### Install Dependencies

Run the following command:

```
brew install go automake git curl wget mysql57 etcd
```

### Install Docker

Running the testsuite requires that you [install Docker](https://docs.docker.com/docker-for-mac/). Should you decide to skip this step, you will still be able to compile and run Vitess.

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
# TODO: macOS no longer uses bash. Check what we should do here...

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
# Remaining commands to build Vitess
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
TODO: do a new paste here
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

