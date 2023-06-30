---
title: Build on macOS
description: Instructions for building Vitess on your machine for testing and development purposes
weight: 1
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

```shell
brew install automake git curl wget mysql nvm
```

Add `mysql` to your `PATH`:

```shell
echo 'export PATH="/usr/local/opt/mysql/bin:$PATH"' >> ~/.bash_profile
```

[Download and install](http://golang.org/doc/install) Golang. For example for `go1.20.2`, at writing:
```shell
curl -LO https://golang.org/dl/go1.20.2.darwin-amd64.pkg
sudo installer -pkg go1.20.2.darwin-amd64.pkg -target /
```

> Vitess is tested and shipped using a specific Golang version for each release.
> For maximum compatibility we encourage you to use the same Golang version as [the one mentioned in our `build.env` file](https://github.com/vitessio/vitess/blob/d1ba6258ea2462d5d28d67661aace7b79bb7e27b/build.env#L20).

Do not install etcd via brew otherwise it will not be the version that is supported. Let it be installed when running make build.

Do not set up MySQL or etcd to restart at login.

[Install node](https://nodejs.org/) >= `16.13.0 LTS` (note you also need `npm >= 8.1.0`, which will come with `node`). For example, using `nvm` (which we installed earlier with homebrew):

```shell
nvm install --lts 16.13.0
nvm use 16.13.0
```

See the [vtadmin README](https://github.com/vitessio/vitess/blob/main/web/vtadmin/README.md) for more details.

## Build Vitess

Navigate to the directory where you want to download the Vitess source code and clone the Vitess GitHub repo:

```shell
cd ~
git clone https://github.com/vitessio/vitess.git
cd vitess
```

Set environment variables that Vitess will require. It is recommended to put these in your `~/.bash_profile` file:

```
# Vitess binaries
export PATH=~/vitess/bin:${PATH}
```

Build Vitess:

```shell
make build
```

Since the addition of [#13263](https://github.com/vitessio/vitess/pull/13262) the `vtadmin` React application will be built when doing a `make build`.
You can skip this step by setting the `NOVTADMINBUILD` environment variable.
```shell
NOVTADMINBUILD=1 make build
```

## Testing your Binaries

The unit tests require that you first install a Java runtime. This is required for running ZooKeeper tests:

```shell
brew tap adoptopenjdk/openjdk
brew install adoptopenjdk8
brew info java
```

You will also need to install `ant` and `maven`:

```shell
brew install ant maven
```

You can then install additional components from `make tools`. If your machine requires a proxy to access the Internet, you will need to set the usual environment variables (e.g. `http_proxy`, `https_proxy`, `no_proxy`) first:

```shell
make tools
make unit_test
```

In addition to running tests, you can try running the [local example](../../get-started/local).

## Common Build Issues

### Key Already Exists

This error is because etcd was not cleaned up from the previous run of the example. You can manually fix this by running `./401_teardown.sh`, removing vtdataroot and then starting again:
```
Error:  105: Key already exists (/vitess/zone1) [6]
Error:  105: Key already exists (/vitess/global) [6]
```

### /tmp/mysql.sock Already In Use
This error occurs because mysql is serving on the same port that vttgate requires. To solve this issue stop mysql service. If you have installed mysql via brew as specified above you should run:
```shell
brew services stop mysql
```
