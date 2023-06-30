---
title: 本机运行Vitess 
description: 如何本机构建和测试Vitess
weight: 4
featured: true
---

本指南涵盖了从预编译的二进制本地文件安装文件，进行本地测试。我们启3个mysqld。建议使用大于4GB的RAM，以及20GB的可用磁盘空间。

## 安装包

PlanetScale 提供 [每周构建](https://github.com/planetscale/vitess-releases/releases) 适用于64位Linux的Vitess。

1. 从 GitHub 上下载解压 [最近发布的`.tar.gz`](https://github.com/planetscale/vitess-releases/releases) 。
2. 安装 MySQL:
```bash
# Apt based
sudo apt-get install mysql-server
# Yum based
sudo yum install mysql-server
```

_Vitess支持MySQL 5.6+和MariaDB 10.0+。我们建议使用MySQL 5.7。_

## 禁用 AppArmor

我们建议您卸载或禁用Apparmor。有些版本的MySQL提供了Vitess工具尚未识别的默认Apparmor配置。当vitess通过mysqlctl工具初始化mysql实例时，这会导致各种权限失败。这只是测试环境中的一个问题。如果生产中需要apparmor，则可以适当配置mysql实例，而不必使用`mysqlctl`：

```bash
sudo service apparmor stop
sudo service apparmor teardown # safe to ignore if this errors
sudo update-rc.d -f apparmor remove
```

重新启动以确保完全禁用Apparmor。

## 配置环境

将以下内容添加到您的`.bashrc`文件中。确保将`/path/to/extracted-tarball`替换为解压最新版本文件的实际路径：

```bash
export VTROOT=/path/to/extracted-tarball
export VTTOP=$VTROOT
export MYSQL_FLAVOR=MySQL56
export VTDATAROOT=${HOME}/vtdataroot
export PATH=${VTROOT}/bin:${PATH}
```

准备好开始您的第一个集群了吗？let's go !

## 启动单个 Keyspace 集群

首先将 Vitess 中包含的本地示例复制到你喜欢的位置。对于第一个例子，我们将部署一个[单个不分片 keyspace](../../concepts/keyspace). 文件 `101_initial_cluster.sh` 是第`1`阶段的第`01`个例子。让我们现在执行它:

```sh
cp -r /usr/local/vitess/examples/local ~/my-vitess-example
cd ~/my-vitess-example
./101_initial_cluster.sh
```

您应该看到类似于以下内容的输出：

```bash
~/...vitess/examples/local> ./101_initial_cluster.sh
enter zk2 env
Starting zk servers...
Waiting for zk servers to be ready...
Started zk servers.
Configured zk servers.
enter zk2 env
Starting vtctld...
Access vtctld web UI at http://ryzen:15000
Send commands with: vtctlclient -server ryzen:15999 ...
enter zk2 env
Starting MySQL for tablet zone1-0000000100...
Starting MySQL for tablet zone1-0000000101...
Starting MySQL for tablet zone1-0000000102...
```
您还可以使用`pgrep`验证进程是否已启动：

``` sh
~/...vitess/examples/local> pgrep -fl vtdataroot
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

如果您遇到任何错误，例如已在使用的端口，您可以终止进程并重新开始：

```bash
pkill -f '(vtdataroot|VTDATAROOT)' # kill Vitess processes
```

## 连接集群

您现在应该可以使用以下命令连接到集群：

``` sh
~/...vitess/examples/local> mysql -h 127.0.0.1 -P 15306
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

``` sh
http://localhost:15000
```

### 拓扑

在这个例子中，我们使用单片keyspace：`commerce`。单分片的keysoace有一个名为`0`的分片。

注意：keyspace/shards是集群的全局实体，
keyspaces/shard对于单元来说是一个独立的概念——所以理想情况下，它们应该与cell分开显示。例如：您应该先创建keyspace，然后再决定将它们部署到何处。

在此次部署中，我们启动两个`replica`类型表和一个`rdonly`类型的tablet。部署后，其中一个`replica` tablet 类型将自动被选为主服务器。在vtctld控制台中，你应该看到一个`master`，一个`replica`和一个`rdonly` vttablets。

设置replicat角色的tablet的目的是为OLTP提供读流量，rdonly角色的tablet是做分析使用，或者用于执行集群的日常维护工作，如备份、重新分片。rdonly副本容忍和主之间有较大延迟，因为上述维护工作需要暂停主从复制。

在我们的用例中，我们为每个shard提供一个rdonly副本，以便执行resharding(重新分片)操作。

### Schema

``` sql
create table product(
  sku varbinary(128),
  description varbinary(128),
  price bigint,
  primary key(sku)
);
create table customer(
  customer_id bigint not null auto_increment,
  email varbinary(128),
  primary key(customer_id)
);
create table corder(
  order_id bigint not null auto_increment,
  customer_id bigint,
  sku varbinary(128),
  price bigint,
  primary key(order_id)
);
```

为简化示例，我们只建少量几张表，每张表少量字段。能够说明流程就好：

*  `product` 表包含所有产品的产品信息。
*  `customer` table有一个具有自动增量的customer_id。典型的customer表将包含更多列，有时还有更多详细信息表。
*  `corder` 表 (这么命名这张表是因为 `order` 是SQL 保留字段) 有一个 order_id 自增列。它同样也是customer(customer_id) 和 product(sku)的外键。

### VSchema

由于Vitess是一个分布式系统，因此通常需要VSchema (Vitess schema)来描述keyspaces的组织方式。

``` json
{
  "tables": {
    "product": {},
    "customer": {},
    "corder": {}
  }
}
```
对于但分片的keyspace来说, VSchema非常简单; 它只是展示出keyspace的所有table。

注意：在单分片keyspace情况下，VSchema不是严格意义上需要定义的，因为Vitess知道没有其他的keyspaces，所以会将所有的查询流量转发到当前的keyspace上。

## 垂直拆分

由于改革开放的深入，自贸区生意红红火火。单品马黛茶摆上了你网站的货架，尝鲜者蜂拥而至前来购买。
随着越来越多的用户涌向你的网站和应用程序，`customer`和`corder`表开始以惊人的速度增长。为了跟上进度，您需要将`customer`和`corder` 移动到它们自己的keyspace中来分隔这些表。由于产品数量与马黛茶类型数量一致(不会有太多的马黛茶类型)，因此您无需对产品表进行分片。


让我们在数据表中添加一些数据来说明垂直分割的工作原理.

``` sql
mysql -h 127.0.0.1 -P 15306 < ../common/insert_commerce_data.sql
```

我们可以看看刚插入的内容：

``` sh
mysql -h 127.0.0.1 -P 15306 --table < ../common/select_commerce_data.sql
Using commerce/0
Customer
+-------------+--------------------+
| customer_id | email              |
+-------------+--------------------+
|           1 | alice@domain.com   |
|           2 | bob@domain.com     |
|           3 | charlie@domain.com |
|           4 | dan@domain.com     |
|           5 | eve@domain.com     |
+-------------+--------------------+
Product
+----------+-------------+-------+
| sku      | description | price |
+----------+-------------+-------+
| SKU-1001 | Monitor     |   100 |
| SKU-1002 | Keyboard    |    30 |
+----------+-------------+-------+
COrder
+----------+-------------+----------+-------+
| order_id | customer_id | sku      | price |
+----------+-------------+----------+-------+
|        1 |           1 | SKU-1001 |   100 |
|        2 |           2 | SKU-1002 |    30 |
|        3 |           3 | SKU-1002 |    30 |
|        4 |           4 | SKU-1002 |    30 |
|        5 |           5 | SKU-1002 |    30 |
+----------+-------------+----------+-------+
```

注意我们在使用 keyspace `commerce/0` 从我们的表中查询数据。

### Create Keyspace

对于垂直拆分，我们首先需要创建一个特殊的`served_from`keyspace。该keyspace作为`commerce`keyspace的别名。发送到此keyspace的任何查询都将重定向到`commerce`。创建后，我们可以将表垂直拆分到新的keyspace，而无需让应用程序感知此更改：

``` sh
./201_customer_keyspace.sh
```

This creates an entry into the topology indicating that any requests to master, replica, or rdonly sent to `customer` must be redirected to (served from) `commerce`. These tablet type specific redirects will be used to control how we transition the cutover from `commerce` to `customer`.
这会在拓扑中创建一个条目，指示必须将对master，replica或rdonly发送给`customer`的任何请求重定向到（来自）`commerce`。这些tablet的指定重定向将用于控制我们如何从`commerce`转换为`customer`。

### Customer Tablets

现在，您必须创建vtTablet实例来备份这个新的keyspace，您将在其中移动必要的表：

``` sh
./202_customer_tablets.sh
```
当然，最显著的变化是为新的keyspace实例化vtablet。此外：

* 你将customer和corder从commerce的 VSchema中挪至customer的VSchema中。注意物理表仍然在commerce中。
* 您请求使用`copySchema`指令将customer和corder的架构复制到customer。

vschema中的改变没造成任何影响，因为发送给客户的任何查询仍然被重定向到commerce库上，在commerce库中所有的数据仍然存在。

### 垂直拆分克隆

下一步：

``` sh
./203_vertical_split.sh
```

开始将数据从commerce迁移到customer的过程。

对于大型表，此作业可能会运行很多天，如果失败，则可能会重新启动。此作业执行以下任务：

* 从commerce库中的customer表和corder表脏拷贝数据到customer库中的表。
* 停止在Commerce的RDOnly vttablet上的复制并执行最终同步。
* 从commerce-> customer启动过滤复制过程，使customer库的表与commerce库中的表保持同步。

注意：在生产环境中，你可能希望在开始切换之前多次运行`SplitDiff`作业，对复制执行多次健全性检查：

我们可以通过检查customer keyspace中的数据来查看VerticalSplitClone的结果。请注意，`customer`和`corder`表中的所有数据都已复制过来。

``` sh
mysql -h 127.0.0.1 -P 15306 --table < ../common/select_customer0_data.sql
Using customer/0
Customer
+-------------+--------------------+
| customer_id | email              |
+-------------+--------------------+
|           1 | alice@domain.com   |
|           2 | bob@domain.com     |
|           3 | charlie@domain.com |
|           4 | dan@domain.com     |
|           5 | eve@domain.com     |
+-------------+--------------------+
COrder
+----------+-------------+----------+-------+
| order_id | customer_id | sku      | price |
+----------+-------------+----------+-------+
|        1 |           1 | SKU-1001 |   100 |
|        2 |           2 | SKU-1002 |    30 |
|        3 |           3 | SKU-1002 |    30 |
|        4 |           4 | SKU-1002 |    30 |
|        5 |           5 | SKU-1002 |    30 |
+----------+-------------+----------+-------+

```

### 切换

一旦您确认customer和corder表正在从commerce库中不断更新，您就可以切断流量。这通常分三步执行：`rdonly`, `replica` 和 `master`:

切 rdonly 和 replica:

``` sh
./204_vertical_migrate_replicas.sh
```

切 master:

``` sh
./205_vertical_migrate_master.sh
```

完成此操作后，`commerce`和`corder`表在`commerce`库中将不能访问。您可以尝试从中进行读取来验证这一点。

``` sql
mysql -h 127.0.0.1 -P 15306 --table < ../common/select_commerce_data.sql
Using commerce/0
Customer
ERROR 1105 (HY000) at line 4: vtgate: http://vtgate-zone1-5ff9c47db6-7rmld:15001/: target: commerce.0.master, used tablet: zone1-1564760600 (zone1-commerce-0-replica-0.vttablet), vttablet: rpc error: code = FailedPrecondition desc = disallowed due to rule: enforce blacklisted tables (CallerID: userData1)
```

replica和rdonly可以回切，但，切主是单向的，不可反转。这是垂直拆分的限制。未来不久会解决这个问题。目前，应注意在转换完成后不会发生数据丢失或可用性丢失。

### 清理

在庆祝您第一次成功的`垂直拆分`之后，您需要清理剩余的组件：

``` sh
./206_clean_commerce.sh
```

这些表由customer库提供，现在，它们应该从commerce中删除。

这些‘控制’记录在切换期间`MigrateServedFrom`命令添加，以防止commerce表意外接受写入。现在可以删除它们。

在此步骤之后，`customer`和`corder`表不再存在于`commerce` 库中。

``` sql
mysql -h 127.0.0.1 -P 15306 --table < ../common/select_commerce_data.sql
Using commerce/0
Customer
ERROR 1105 (HY000) at line 4: vtgate: http://vtgate-zone1-5ff9c47db6-7rmld:15001/: target: commerce.0.master, used tablet: zone1-1564760600 (zone1-commerce-0-replica-0.vttablet), vttablet: rpc error: code = InvalidArgument desc = table customer not found in schema (CallerID: userData1)
```

## 水平拆分

你花重金雇佣的DBA此时已经吓坏了，MYSQL性能在下降，他们想做点儿什么，又不知从何入手，只有不停的微信轰炸你：老板，Keyspace中的数据量已经越来越大了，QPS快抗不住了，咋整？！你微微一笑，小手一挥，别怕，咱有Vitess！咋整，水平拆呀！
玩笑归玩笑，虽然Vitess为非拆分的单片keyspace提供查询保护和连接池功能，[不懂的看这里看这里](https://vitess.io/blog/2019-06-17-unsharded-vitess-benefits/)，但Vitess真正的价值在于水平分片。

### 准备工作

在开始重新分片过程之前，您需要做出一些决定并准备系统以进行水平重新分片。重要提示，这是在开始垂直拆分之前应该完成的事情。但是，这是一个很好的你会来解释在这个过程的早期通常会决定什么。

#### 序列表

要解决的第一个问题:customer和corder表都有自增列。然而，分片的情况下并不适用。vitess通过序列提供了一个等价的特性。

序列表是一个非拆分单行表，Vitess可以使用它来生成单调递增的id。生成id的语法是：
`select next :n values from customer_seq`。 提供此表的vttablet能够为大量此类ID提供服务，因为值被缓存的，并且服务于内存之外。缓存值是可配置的。

vschema允许您将表的列与序列表相关联。完成后，该表上的insert将透明地从sequence表中获取一个ID，填充该值，并将该行路由到适当的shard。此设计向后兼容mysql的`auto_increment`属性的工作方式。

由于序列是非拆分表，因此它们将存储在commerce数据库中。架构如下：

``` sql
create table customer_seq(id int, next_id bigint, cache bigint, primary key(id)) comment 'vitess_sequence';
insert into customer_seq(id, next_id, cache) values(0, 1000, 100);
create table order_seq(id int, next_id bigint, cache bigint, primary key(id)) comment 'vitess_sequence';
insert into order_seq(id, next_id, cache) values(0, 1000, 100);
```

请注意create table语句中`vitess_sequence`注释。 VTTablet将使用此元数据将此表视为序列。

* `id` 总是 0
* `next_id` 设置为 `1000`: 该值应该比目前使用的`auto_increment`最大值设置的大一些。
* `cache` :`cache`指定在vttablet在更新`next_id`之前缓存的值的数量。

较高的缓存值会获取更高性能。但是，如果通过reparent切换主，那么缓存的值将丢失。新主将从旧主人写入表中的`next_id`值开始计算。

VTGate服务器知道谁是序列表。这是通过更新commerce库的VSchema来完成的，如下所示：

``` json
{
  "tables": {
    "customer_seq": {
      "type": "sequence"
    },
    "order_seq": {
      "type": "sequence"
    },
    "product": {}
  }
}
```

#### Vindexes

下一个决定是关于分片键，又称作主Vindex。关于Vindex你可以理解为一个方法，这个方法决定根据什么条件将一行数据放置到不同的分片中。如何选择分片键需要综合考虑才能得出结果，涉及以下考虑因素：

* 什么是QPS最高的查询，以及它们的where子句是什么？
* 列的[索引基数](https://blog.csdn.net/tiansidehao/article/details/78931765)，一定要分散
* 你是否想要对模式建模，以便知道有些行在分片中可以进行join，而不需要跨越分片？
* 你是否希望同一事务中的某些行能够在一个分片内聚合？

综上考虑，在我们的用例中，我们可以确定：

* 对于customer表，最常见的where子句使用`customer_id`。所以，它应该有一个主Vindex。
* 鉴于它拥有大量用户，其索引基数也很高。
* 对于corder表，我们可以选择`customer_id`和`order_id`。鉴于我们的应用程序经常在`customer_id`列上将`customer`与`corder`连接起来，选择`customer_id`作为`corder`表的主Vindex将是有益的。
* 巧合的是，事务还会更新`corder`表及其对应的`customer`行。这进一步强化了将'customer_id`用作主Vindex的决定。

注意：在`corder.order_id`上创建辅助查找Vindex可能是值得的。这不是示例的一部分。我们将在高级部分讨论这个问题。

注意：对于某些用例，`customer_id`实际上可能映射到`tenant_id`。在这种情况下，租户ID的基数可能太低。这种系统在其where子句中使用其他高基数列的查询也很常见。在决定采用哪列作为主Vindex时，应考虑这些因素。

总而言之，我们为`customer`提供了以下VSchema:

``` json
{
  "sharded": true,
  "vindexes": {
    "hash": {
      "type": "hash"
    }
  },
  "tables": {
    "customer": {
      "column_vindexes": [
        {
          "column": "customer_id",
          "name": "hash"
        }
      ],
      "auto_increment": {
        "column": "customer_id",
        "sequence": "customer_seq"
      }
    },
    "corder": {
      "column_vindexes": [
        {
          "column": "customer_id",
          "name": "hash"
        }
      ],
      "auto_increment": {
        "column": "order_id",
        "sequence": "order_seq"
      }
    }
  }
}
```

请注意，我们现在已将keyspace标记为分片。这种改变同样会改变Vitess处理这个keyspace的方式。以前工作的一些复杂查询可能不再起作用。这是进行全面测试以确保所有查询都有效的好时机。如果任何查询失败，您可以暂时将keyspace恢复为未分片(单片)。

由于主vindex列是`BIGINT`，我们选择`hash`作为主vindex，这是一种将行分配到各种分片的伪随机方式。

注意：对于`VARCHAR`列，请使用`unicode_loose_md5`。对于`VARBINARY`，使用`binary_md5`。

注意：Vitess中的所有vindex都是插件。如果预定义的vindexs都不符合您的需求，您可以开发自己的自定义vindex。

既然我们做出了所有重要的决定，那么就应该应用这些变化：

``` sh
./301_customer_sharded.sh
```

### Create new shards

此时，您已完成分片VSchema并且检查了您业务的所有SQL以确保它们在多分片上仍然有效。现在，是时候开始水平拆分了。

水平分片过程的工作原理是将现有分片拆分为较小的分片。这种类型的重新分片最适合Vitess。在某些用例中，您可能希望启动新分片并在最近创建的分片中添加新行。Vitess也可以做到这一点，假设按数值进行分割（office_id）。将会有一个新的办公室编号205.目前，分片定义会将其插入到碎片4中，但尚未插入205的值。所以我们改变定义，说数字>=205要去一个新的分片，然后我们开始插入。这样，office_id大于205的就会去到我们新的分片中，只要我们提前设定好vindex方法。

我们必须创建新的目标分片：

``` sh
./302_new_shards.sh
```
Shard 0已经存在了。我们现在添加了分片`-80`和`80 -`。我们还添加了`copySchema`指令，该指令请求将分片0中的模式复制到新的分片中。

#### 分片命名

`-80` 和 `80-`是什么玩意儿? 分片名字具有下列特征:

* 表示一个范围，包括左边界，右边界不包括在内。
* 十六进制
* 左对齐
* 左`-` 前缀表示: 任何小于右值的值
* 右`-` 前缀: 任何大于或等于左值的值
* 普通的 `-` 表示全部范围

这是什么意思: `-80` == `00-80` == `0000-8000` == `000000-800000`

`80-` 和 `80-FF` 是不一样的。 这是因为：

`80-FF` == `8000-FF00`. 因此 `FFFF` 会超出 `80-FF` 范围.

`80-` 意味着: 大于或等于`0x80`的任何值。

`hash` vindex产生一个8字节的数。这意味着所有小于“0x8000000000000000”的数字都将落在分片`-80`中。任何具有最高位集的> =`0x8000000000000000`的数字，属于shard`80-`。

这种左对齐的方法允许您拥有任意长度的keyspace ID。但是，最重要的位是左边的位。

例如，“md5”哈希产生16个字节。也可以用作keyspace的ID。

任意长度的`varbinary`也可以按原样映射到keyspace id。这就是`binary`vindex所做的。

在上面的例子中，我们创建了两个shard：任何没有其最左边位集的keyspace id都将转到`-80`。其他人都会去“80-”。

应用上述更改将导致创建另外六个vttablet实例。

此时，表已在新分片中创建但尚未包含数据。

``` sql
mysql -h 127.0.0.1 -P 15306 --table < ../common/select_customer-80_data.sql
Using customer/-80
Customer
COrder
mysql -h 127.0.0.1 -P 15306 --table < ../common/select_customer80-_data.sql
Using customer/80-
Customer
COrder
```

### SplitClone

SplitClone的过程类似于VerticalSplitClone。它启动水平重新分割过程：

``` sh
./303_horizontal_split.sh
```

这开始了以下工作：
 "SplitClone -min_healthy_rdonly_tablets=1 customer/0":

对于大表，此作业可能会运行很多天，如果失败可以重新启动。此作业执行以下任务：

* 将customer/0的数据脏拷贝到两个新分片中。但行是根据目标分片拆分的。
* 停止在customer/0 rdonly tablet上复制并执行最终同步。
* 根据行所属的分片，向其中一个或另一个分片发送更改，从而启动从customer/0到两个碎片的过滤复制过程。开启过滤复制，Vitess会根据某行数据的路由字段数值根据路由算法计算出一个数值，如果此数值<-80,此行将落到第一个分片，如果此数值>-80，那么此行将去到另一个分片。


一旦 `SplitClone` 完成， 你会看到如下信息:


与`VerticalSplitDiff`对应的操作是 `SplitDiff`。它可用于验证重新分片过程的数据完整性。

注意：此示例实际上不运行此命令。

请注意，SplitDiff的最后一个参数是目标分片。您需要为每个目标分片运行一个作业。此外，您无法并行运行它们，因为它们需要`rdonly`实例从集群中摘掉（停止主从复制）才能执行比较。

注意：SplitDiff可用于分割分片以及合并分片。

### 切换

现在您已验证表中数据是从源分片持续更新的，您可以切换流量。这通常分三步执行：`rdonly`，`replica`和`master`：

切 rdonly 和 replica:

``` sh
./304_migrate_replicas.sh
```

切 master:

``` sh
./305_migrate_master.sh
```

在*master*迁移期间，原始分片主先停写。接下来，程序将等待新的分片主追平过滤复制，然后再允许它们开始服务。由于源分片的replica mysql上的binlog被实时过滤复制消费到不同分片上，因此切主时的延迟应该不会太高，因此只会有几秒钟的主不可用性。

replica和rdonly切换可以自由逆转。与垂直拆分不同，水平拆分也是可逆的。您只需在切主时添加一个`-reverse_replication`标志即可。你可以理解成建立反方向的过滤复制，如果带着这个标志，你发现用新片有问题的时候，你就可以随时切换回去，因为反向的过滤复制保证新旧分片上的数据是完全一致的。

现在应该可以看到复制到新分片上的数据了。

``` sh
mysql -h 127.0.0.1 -P 15306 --table < ../common/select_customer-80_data.sql
Using customer/-80
Customer
+-------------+--------------------+
| customer_id | email              |
+-------------+--------------------+
|           1 | alice@domain.com   |
|           2 | bob@domain.com     |
|           3 | charlie@domain.com |
|           5 | eve@domain.com     |
+-------------+--------------------+
COrder
+----------+-------------+----------+-------+
| order_id | customer_id | sku      | price |
+----------+-------------+----------+-------+
|        1 |           1 | SKU-1001 |   100 |
|        2 |           2 | SKU-1002 |    30 |
|        3 |           3 | SKU-1002 |    30 |
|        5 |           5 | SKU-1002 |    30 |
+----------+-------------+----------+-------+

mysql -h 127.0.0.1 -P 15306 --table < ../common/select_customer80-_data.sql
Using customer/80-
Customer
+-------------+----------------+
| customer_id | email          |
+-------------+----------------+
|           4 | dan@domain.com |
+-------------+----------------+
COrder
+----------+-------------+----------+-------+
| order_id | customer_id | sku      | price |
+----------+-------------+----------+-------+
|        4 |           4 | SKU-1002 |    30 |
+----------+-------------+----------+-------+
```

### 清理

在庆祝第二次成功水平拆分之后，您现在准备清理剩余的组件：

``` sh
./306_down_shard_0.sh
```

在这个脚本中，我们刚停止了分片0中的所有的tablet实例。这将导致所有那些vttablet和`mysqld`进程停止。但是分片元数据仍然存在。我们可以用这个命令清理它（在所有的vttablet进程退出之后）：


``` sh
./307_delete_shard_0.sh
```
此脚本运行如下命令：
"`DeleteShard -recursive customer/0`".

除此之外，您还需要手动删除与此分片关联的磁盘。

### 拆除 (可选)

如果您不继续进行其他练习，则可以删除整个示例。

``` sh
./401_teardown.sh
```
