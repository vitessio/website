---
title: 用Vagrant跑Vitess
description: 使用Vagrant在机器上构建Vitess以进行测试和开发的说明
weight: 4
featured: true
---

[Vagrant](https://www.vagrantup.com/) 是一个在单个工作流程中构建和管理虚拟机环境的工具。通过易于使用的工作流程并专注于自动化，Vagrant降低了开发环境的设置时间，提高了生产力，并使“在我的机器上工作”成为历史。

下面的指南将向您展示如何使用此工具在本地环境中构建和运行vitess。

{{< info >}}
如果您遇到问题或有疑问，我们建议您在[Slack channel](https://vitess.slack.com)中发布，单击右上角的Slack图标加入。这是一个非常活跃的社区论坛，也是与其他用户互动的好地方
{{< /info >}}

## Install dependencies

1. 在OS上安装 [Vagrant](https://www.vagrantup.com/downloads.html) 
1. 安装 [Virtual Box](https://www.virtualbox.org/)


## 编译 Vitess {#build-vitess-vagrant}

1. 将vitess repo克隆到本地环境中：

    ```sh
    git clone https://github.com/vitessio/vitess.git 
    ```

2. 从repo目录运行以下命令：

    ```sh
    vagrant up
    ```
    
    这将使用所有Vitess依赖项来引导VM。

3. 完成引导程序后，运行以下命令：

    ```sh
    vagrant ssh
    ```

    第一次连接到VM时，它会自动为您构建vitess。

4. 展望未来，如果您想构建项目，您只需要运行：
    ```sh
    make build
    ```

## Run Tests

{{< info >}}
如果您正在使用etcd，请设置以下环境变量：

```sh
export VT_TEST_FLAGS='--topo-server-flavor=etcd2'
```

如果您使用的是Consul，请设置以下环境变量：

```sh
export VT_TEST_FLAGS='--topo-server-flavor=consul'
```
{{< /info >}}

运行`make test`时的默认目标包含一整套测试，旨在帮助Vitess开发人员验证代码更改是否有错。这些测试通过在本地计算机上启动许多服务器来模拟小型Vitess集群。为顺利测试，它们需要大量的资源;建议至少使用8GB RAM和SSD来运行测试。

如果您只想检查Vitess是否在您的环境中正常工作，您可以运行一组更轻松的测试：

```sh
make site_test
```

## Start a Vitess cluster

After completing the instructions above to [build Vitess](#build-vitess-vagrant), you can use the example scripts in the GitHub repo to bring up a Vitess cluster on your local machine. These scripts use `etcd2` as the default [topology service](../../concepts/topology-service) plugin.

按照指导完成上述[build Vitess](#build-vitess-vagrant)的操作步骤之后，您可以使用GitHub存储库中的示例脚本在本地计算机上开启Vitess集群。这些脚本使用`etcd2`作为默认的[拓扑服务](../../concepts/topology-service)插件。


1. **启动集群**

    ```sh
    (local) vagrant@vitess:/vagrant/src/vitess.io/vitess$ vagrant-scripts/vitess/start.sh
    ```
    **注意:**这将启动一个完整的Vitess集群，其中包含一个分片和五个tablet。

2. **连接到VTGate**
   
    
    在VM上，您可以使用MySQL协议使用以下命令连接到VTGate
    
    ```sh
    mysql -umysql_user -pmysql_password -h vitess -P 15306
    ``` 
    有一个消息表可供您使用：

    ```sh
    mysql> select count(*) from messages;
    +----------+
    | count(*) |
    +----------+
    |        0 |
    +----------+
    1 row in set (0.01 sec)
    ```

    此外，vtgate管理UI可通过 http://localhost:15001 访问
   
3. **连接到Vtctld**
    
    Vitess集群管理控制UI可通过 http://localhost:15000访问
   

### 运行客户端应用程序

`client.py`文件是一个简单的示例应用程序，它连接到`vtgate`并执行一些查询。要运行它，您需要

* 使用`client.sh`脚本，它会设置临时环境，然后运行`client.py`。


    ```sh
    export VTROOT=/vagrant
    export VTDATAROOT=/tmp/vtdata-dev
    export MYSQL_FLAVOR=MySQL56
    cd "$VITESS_WORKSPACE"/examples/local
    ./client.sh
    ### example output:
    # Inserting into master...
    # Reading from master...
    # (5L, 1462510331910124032L, 'V is for speed')
    # (15L, 1462519383758071808L, 'V is for speed')
    # (42L, 1462510369213753088L, 'V is for speed')
    # ...
    ```
Java，PHP和Go的同一目录中也有客户端示例。有关使用说明，请参阅每个示例文件顶部的注释。

### 拆除集群

完成测试后，可以使用以下脚本拆除群集： 

```sh
(local) vagrant@vitess:/vagrant/src/vitess.io/vitess$ vagrant-scripts/vitess/stop.sh
```

## 故障排除

如果出现任何问题，请检查`$VTDATAROOT/tmp`目录中的日志以获取错误消息。还有一些特定于平板电脑的日志，以及各种 `$VTDATAROOT/vt_*`目录下的MySQL日志。

如果您需要帮助来诊断问题，请发送消息到我们的[Slack channel](https://vitess.slack.com)。除了您在命令行中看到的任何错误之外，还可以将`VTDATAROOT`目录的存档上传到文件共享服务并提供指向它的链接。

