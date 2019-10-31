---
title: Build on macOS
description: Instructions for building Vitess on your machine for testing and development purposes
---

{{< info >}}
If you run into issues or have questions, we recommend posting in our [Slack channel](https://vitess.slack.com), click the Slack icon in the top right to join. This is a very active community forum and a great place to interact with other users.
{{< /info >}}

The following has been verified to work on __macOS Mojave__. If you are new to Vitess, it is recommended to start with the [local install](../../get-started/local) guide instead.

## Install Dependencies

### Install Xcode

[Install Xcode](https://developer.apple.com/xcode/).

### Install Homebrew and Dependencies

[Install Homebrew](http://brew.sh/). From here you should be able to install:

```
brew install go automake git curl wget mysql@5.7 etcd ant
```

Add `mysql@5.7` to your `PATH`:
```
echo 'export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"' >> ~/.bash_profile
```

Do not setup MySQL or etcd to restart at login.

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

Set environment variables that Vitess will require. It is recommended to put these in your `~/.bash_profile` file:

```
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

This may result in a warning about `$GOROOT` and an unsupported architecture. It is safe to ignore these errors for now:

```
morgans-mini:vitess morgo$ BUILD_PYTHON=0 BUILD_JAVA=0 ./bootstrap.sh
WARNING: $GOROOT may not be compatible with the used go binary
Please make sure 'go' comes from $GOROOT/bin
go_env: /usr/local/Cellar/go/1.12.6/libexec
go_bin: /usr/local/bin/go
creating git hooks
installing protoc 3.6.1
ERROR: unsupported architecture
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
morgans-mini:local morgo$ ./101_initial_cluster.sh 
enter etcd2 env
add /vitess/global
add /vitess/zone1
add zone1 CellInfo
Error:  client: response is invalid json. The endpoint is probably not valid etcd cluster endpoint
Error:  client: response is invalid json. The endpoint is probably not valid etcd cluster endpoint
etcd start done...
enter etcd2 env
Starting vtctld...
Access vtctld web UI at http://morgans-mini.lan:15000
Send commands with: vtctlclient -server morgans-mini.lan:15999 ...
enter etcd2 env
Starting MySQL for tablet zone1-0000000100...
Starting MySQL for tablet zone1-0000000101...
Starting MySQL for tablet zone1-0000000102...
Starting vttablet for zone1-0000000100...
Access tablet zone1-0000000100 at http://morgans-mini.lan:15100/debug/status
Starting vttablet for zone1-0000000101...
Access tablet zone1-0000000101 at http://morgans-mini.lan:15101/debug/status
Starting vttablet for zone1-0000000102...
Access tablet zone1-0000000102 at http://morgans-mini.lan:15102/debug/status
W1027 20:11:49.555831   35859 main.go:64] W1028 02:11:49.555179 reparent.go:182] master-elect tablet zone1-0000000100 is not the shard master, proceeding anyway as -force was used
W1027 20:11:49.556456   35859 main.go:64] W1028 02:11:49.556135 reparent.go:188] master-elect tablet zone1-0000000100 is not a master in the shard, proceeding anyway as -force was used
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
Access vtgate at http://morgans-mini.lan:15001/debug/status
```

You can continue the remaining parts of this example by following the [local](../../get-started/local) get started guide.

### Full testsuite

To run the testsuite in Docker:

```
make docker_test flavor=mysql57
```

Running the full suite currently takes 2+ hours to complete.

## Common Build Issues

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

