---
title: 从源码构建
description: 如何从本机构建、开发及测试Vitess
weight: 1
featured: true
---



{{< info >}}
如果您遇到问题或有疑问，我们建议您在我们的[Slack 频道](https://vitess.slack.com)上发帖，点击右上角的Slack图标加入。这是一个非常活跃的社区论坛，也是与其他用户互动的好地方。当然，你也可以加入微信群组**vitess中国**寻求帮助，这里的人们也很热心，时刻准备好回答您的任何问题。
{{< /info >}}

## 源码编译

以下部分介绍了在Linux和macOS上手动构建Vitess的过程。如果您是Vitess的新手，建议先从[本地部署](../../tutorials/local) 指南开始。

### 安装依赖

我们目前正在Ubuntu 14.04（Trusty）和Debian 8（Jessie）上定期测试Vitess。 macOS 10.11（El Capitan）及以上版本也可以使用。安装说明[如下所示](#macos).

#### Ubuntu and Debian

 Vitess依赖如下软件和库:

1.  [Install Go 1.15+](http://golang.org/doc/install).

2. Install MySQL:
```bash
# Apt based
sudo apt-get install mysql-server
# Yum based
sudo yum install mysql-server
```

_Vitess支持MySQL 5.6+和MariaDB 10.0+。我们建议使用MySQL 5.7。_

3.  卸载或者禁用 [AppArmor](https://wiki.ubuntu.com/AppArmor)。某些版本的MySQL带有Vitess工具尚未识别的默认AppArmor配置。当Vitess通过`mysqlctl`工具初始化MySQL实例时，这会导致各种权限失败。这仅在测试环境中存在问题。如果在生产中需要AppArmor，则可以在不通过`mysqlctl`的情况下适当地配置MySQL实例。

    ```sh
    sudo service apparmor stop
    sudo service apparmor teardown # safe to ignore if this errors
    sudo update-rc.d -f apparmor remove
    ```

    重新启动以确保完全禁用AppArmor。

4.  安装 [etcd v3.0+](https://github.com/coreos/etcd/releases). 请记住在您的路径中包含`etcd`命令。

    我们将使用ectd作为[拓扑服务](../../overview/concepts)。 Vitess还包括对[ZooKeeper](https://zookeeper.apache.org) 和 [Consul](https://www.consul.io/)的内置支持。

5.  安装构建和运行Vitess所需的以下工具：

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

    可以使用以下apt-get命令安装它们
    ```sh
    $ sudo apt-get install make automake libtool python-dev python-virtualenv python-mysqldb libssl-dev g++ git pkg-config bison curl unzip
    ```

#### Mac OS

1.  [安装 Homebrew](http://brew.sh/)。如果您的`/usr/local`目录不为空且尚未使用Homebrew，则需要运行以下命令：

    ```sh
    sudo chown -R $(whoami):admin /usr/local
    ```

2.  您可以通过安装[Xcode](https://developer.apple.com/xcode/)(推荐)或   [pkg-config](https://www.freedesktop.org/wiki/Software/pkg-config/)来满足Vitess的依赖关系。如果没有安装Xcode，那么采用如下命令安装pkg-config

    ```sh
    brew install pkg-config
    ```

3.  安装 [etcd v3.0+](https://github.com/coreos/etcd/releases). 将`etcd` 命令放置在您的环境变量路径中。

    我们将使用ectd作为[拓扑服务](../../overview/concepts)。Vitess 同时还包括对 [ZooKeeper](https://zookeeper.apache.org) 和 [Consul](https://www.consul.io/) 的内置支持。


4.  运行如下命令:

    ```sh
    brew install go ant automake libtool python git bison curl wget mysql57
    pip install --upgrade pip setuptools
    pip install virtualenv
    pip install MySQL-python
    pip install tox
    ```

5.  Vitess引导程序脚本对go运行时环境进行了一些检查，因此建议在您在 `~/.profile`, `~/.bashrc`, `~/.zshrc`, 或者`~/.bash_profile`文件中包含如下命令:

    ```sh
    export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"
    export PATH=/usr/local/go/bin:$PATH
    export GOROOT=/usr/local/go
    ```

6.   要使Vitess主机名能够正常解析，需要在/etc/hosts文件中添加一个新的映射关系，其中包含计算机的当前LAN IP地址（最好是IPv4）和当前主机名，您可以通过在终端键入'hostname'获得主机名。
 将如下命令放到 [强制使用 Go DNS 解析器](https://golang.org/doc/go1.5#net)  `~/.profile` 或者 `~/.bashrc` 或者 `~/.zshrc`文件中也是一个好主意:

    
```sh
    export GODEBUG=netdns=go
 ```

## 编译 Vitess

1. cd到你想cloen vitess源码的目录，clone之。完成后进入到 `src/vitess.io/vitess` 目录中。

    ```sh
    cd $WORKSPACE
    git clone https://github.com/vitessio/vitess.git \
        src/vitess.io/vitess
    cd src/vitess.io/vitess
    ```

2. 设置 `MYSQL_FLAVOR`:
```sh
# It is recommended to use MySQL56 even for MySQL 5.7 and 8.0. For MariaDB you can use MariaDB:
export MYSQL_FLAVOR=MySQL56
```

3. 如果你的MYSQL数据库安装在 `/usr/bin`之外的位置， 请将`VT_MYSQL_ROOT` v变量设置为Mysql安装的根目录:

    ```sh
    # 通过tar包安装的设置参考
    export VT_MYSQL_ROOT=/usr/local/mysql

    # 通过Homebrew安装的设置参考
    export VT_MYSQL_ROOT=/usr/local/opt/mysql@5.7
    ```

    请注意上述命令设置生效的前提 `mysql` 可执行文件在 `/usr/local/opt/mysql@5.7/bin/mysql`这里。

4. 运行 `mysqld --version` 确保你使用的是 MySQL 5.7版本。

5. 使用以下命令构建Vitess。请注意，`bootstrap.sh`脚本需要下载一些依赖项。如果您的计算机需要代理才能访问Internet，则需要设置常用的环境变量 (e.g. `http_proxy`, `https_proxy`, `no_proxy`).

    运行 boostrap.sh 脚本:

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

#### 编译遇到问题怎么办

{{< info >}}
如果您遇到问题或有疑问，我们建议您在我们的[Slack 频道](https://vitess.slack.com)上发帖，点击右上角的Slack图标加入。这是一个非常活跃的社区论坛，也是与其他用户互动的好地方。当然，你也可以加入微信群组**vitess中国**寻求帮助，这里的人们也很热心，时刻准备好回答您的任何问题。
{{< /info >}}

##### Python 报错

端到端测试套件目前需要Python 2.7。我们正在努力消除这种依赖关系，你也可以在Docker中运行测试。MySQL 5.7容器包含如下依赖项

```bash
make docker_test flavor=mysql57
```

##### Node 已存在, port 报错

测试过程失败可能会导致一堆不相关的进程。如果使用默认设置，则可以使用以下命令识别并终止这些进程：


```sh
pgrep -f -l '(vtdataroot|VTDATAROOT)' # 展示 Vitess 相关进程
pkill -f '(vtdataroot|VTDATAROOT)' # 干掉 Vitess 相关进程
```

##### 太多建立到MySQL的连接, 其他超时报错

此错误可能意味着您的磁盘太慢。如果你用不起SSD，可以尝试[针对ramdisk进行测试](https://github.com/vitessio/vitess/blob/master/doc/TestingOnARamDisk.md).

##### tablet连接拒绝， MySQL socket 找不到等问题

这些错误可能表示当尝试分配更多RAM时，计算机耗尽RAM并且服务器崩溃。一些较重的测试需要高达8GB的RAM。


##### 硬盘资源耗尽

一些较大的测试在磁盘上使用高达4GB的临时空间。

##### 文件打开过多

ome Linux发行版附带的默认文件描述符限制对于数据库服务器而言太低。此问题可能会显示为数据库因“太多打开文件”消息而崩溃。检查系统范围的file-max设置以及用户特定的ulimit值。我们建议将它们设置在100K以上是安全的。确切的过程可能因您的Linux发行版而异。

## 启动单分片集群

你可以使用本地测试脚本`101_initial_cluster.sh` 快速启动一个单分片Vitess集群，命令如下：

``` sh
cd examples/local
./101_initial_cluster.sh
```

### 验证集群工作是否正常

如果集群工作正常，您应该看到以下状态：

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

您现在应该可以使用以下命令连接到群集：

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

您还可以使用以下URL浏览到vtctld控制台：

```
http://localhost:15000
```

### 下一步的工作

恭喜！您现在已启动并运行本地vitess群集。您可以按照以下步骤完成其他练习 [Run Vitess Locally](../../tutorials/local)。

笔者在Mac上也尝试安装了一次Vitess，大家也可以参考下，附上链接如下 : [Vitess build on Mac](https://www.jianshu.com/p/fb1b1007a095)
