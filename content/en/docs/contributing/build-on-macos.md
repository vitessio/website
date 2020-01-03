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
brew install go@1.12 automake git curl wget mysql@5.7 etcd
```

Add `mysql@5.7` and `go@1.12` to your `PATH`:
```
echo 'export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"' >> ~/.bash_profile
echo 'export PATH="/usr/local/opt/go@1.12/bin:$PATH"' >> ~/.bash_profile
```

Do not setup MySQL or etcd to restart at login.

## Build Vitess

Navigate to the directory where you want to download the Vitess source code and clone the Vitess GitHub repo:

```
cd ~
git clone https://github.com/vitessio/vitess.git
cd vitess
```

Set environment variables that Vitess will require. It is recommended to put these in your `~/.bash_profile` file:

```
# Vitess
export VTROOT=~/vitess
export PATH=${VTROOT}/bin:${PATH}
```

Build Vitess:

```
make build
```

## Testing your Binaries

The unit tests require that you first install a Java runtime. This is required for running ZooKeeper tests:

```
brew tap adoptopenjdk/openjdk
brew cask install adoptopenjdk8
brew cask info java
```

You will also need to install `ant` and `mvn`:
```
brew install ant mvn
```

You can then install additional components from `make tools`. If your machine requires a proxy to access the Internet, you will need to set the usual environment variables (e.g. `http_proxy`, `https_proxy`, `no_proxy`) first:

```
make tools
make test
```

In addition to running tests, you can try running the [local example](../../get-started/local).

## Common Build Issues

### Key Already Exists

This error is because etcd was not cleaned up from the previous run of the example. You can manually fix this by running `./401_teardown.sh` and then start again:
```
Error:  105: Key already exists (/vitess/zone1) [6]
Error:  105: Key already exists (/vitess/global) [6]
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
export PATH=${VTROOT}/bin:${PATH}
```

### Cannot create dir /etcd

This indicates that the environment variable `VTROOT` is not defined, and you have not put the required vitess environment variables in your `.bashrc` file:

```
./101_initial_cluster.sh
enter etcd2 env
mkdir: cannot create directory ‘/etcd’: Permission denied
```

Make sure the following variables are defined:
```
export VTROOT=~/vitess
export PATH=${VTROOT}/bin:${PATH}
```

