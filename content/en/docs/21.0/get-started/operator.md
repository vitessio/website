---
title: Vitess Operator for Kubernetes
weight: 1
featured: true
aliases: ['/docs/tutorials/kubernetes/','/user-guide/sharding-kubernetes.html', '/docs/get-started/scaleway/','/docs/get-started/kubernetes/']
---

PlanetScale provides a [Vitess Operator for Kubernetes](https://github.com/planetscale/vitess-operator), released under the Apache 2.0 license. The following steps show how to get started using Minikube:

## Prerequisites

{{<info>}}Information on the versions of Kubernetes supported can be [found here](https://github.com/planetscale/vitess-operator#compatibility).{{</info>}}

Before we get started, let’s get a few pre-requisites out of the way:

1. Install [Docker Engine](https://docs.docker.com/engine/install/) locally.

1. Install [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) and start a Minikube engine:
    ```bash
    minikube start --kubernetes-version=v1.28.5 --cpus=4 --memory=11000 --disk-size=32g
    ```

    {{<warning>}}Allocating less memory than specified will cause crashes in subsequent steps and break the process{{</warning>}}

1. Install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) and ensure it is in your `PATH`.

1. Install [the MySQL client](https://dev.mysql.com/doc/mysql-getting-started/en/) locally.

1. Install [vtctldclient](https://vitess.io/docs/get-started/local/#install-vitess) locally.

## Install the Operator

Change to the operator example directory:

```bash
git clone https://github.com/vitessio/vitess
cd vitess/examples/operator
```

Install the operator:

```bash
kubectl apply -f operator.yaml
```

## Bring up an initial cluster

In this directory, you will see a group of yaml files. The first digit of each file name indicates the phase of example. The next two digits indicate the order in which to execute them. For example, `101_initial_cluster.yaml` is the first file of the first phase. We shall execute that now:

```bash
kubectl apply -f 101_initial_cluster.yaml
```

### Verify cluster

You can check the state of your cluster with `kubectl get pods`. After a few minutes, it should show that all pods are in the status of running:

```bash
$ kubectl get pods
NAME                                                         READY   STATUS    RESTARTS        AGE
example-commerce-x-x-zone1-vtorc-c13ef6ff-5db4c77865-l96xq   1/1     Running   2 (2m49s ago)   5m16s
example-etcd-faf13de3-1                                      1/1     Running   0               5m17s
example-etcd-faf13de3-2                                      1/1     Running   0               5m17s
example-etcd-faf13de3-3                                      1/1     Running   0               5m17s
example-vttablet-zone1-2469782763-bfadd780                   3/3     Running   1 (2m43s ago)   5m16s
example-vttablet-zone1-2548885007-46a852d0                   3/3     Running   1 (2m47s ago)   5m16s
example-zone1-vtadmin-c03d7eae-7c6f6c98f8-f4f5z              2/2     Running   0               5m17s
example-zone1-vtctld-1d4dcad0-57b9d7bc4b-2tnqd               1/1     Running   2 (2m53s ago)   5m17s
example-zone1-vtgate-bc6cde92-7d445d676-x6npk                1/1     Running   2 (3m ago)      5m17s
vitess-operator-5f47c6c45d-bgqp2                             1/1     Running   0               6m52s
```

## Setup Port-forward

{{< warning >}}
The port-forward will only forward to a specific pod. Currently, `kubectl` does not automatically terminate a port-forward as the pod disappears due to apply/upgrade operations. You will need to manually restart the port-forward.
{{</ warning >}}

For ease-of-use, Vitess provides a script to port-forward from Kubernetes to your local machine. This script also recommends setting up aliases for `mysql` and `vtctldclient`:

```bash
./pf.sh &
alias vtctldclient="vtctldclient --server=localhost:15999"
alias mysql="mysql -h 127.0.0.1 -P 15306 -u user"
```

Setting up aliases changes `mysql` to always connect to Vitess for your current session. To revert this, type `unalias mysql && unalias vtctldclient` or close your session.

Once the port-forward starts running, the VTAdmin UI will be available at [http://localhost:14000/](http://localhost:14000/)

## Create Schema

Load our initial schema:

```bash
vtctldclient ApplySchema --sql-file="create_commerce_schema.sql" commerce
vtctldclient ApplyVSchema --vschema-file="vschema_commerce_initial.json" commerce
```

### Connect to your cluster

You should now be able to connect to the VTGate Server in your cluster with the MySQL client:

```text
~/vitess/examples/operator$ mysql
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 3
Server version: 8.0.30-Vitess MySQL Community Server (GPL)

Copyright (c) 2000, 2020, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| commerce           |
| information_schema |
| mysql              |
| sys                |
| performance_schema |
+--------------------+
5 rows in set (0.01 sec)

mysql>
```

### Summary

In this example, we deployed a single unsharded keyspace named `commerce`. Unsharded keyspaces have a single shard named `0`. The following schema reflects a common ecommerce scenario that was created by the script:

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

The schema has been simplified to include only those fields that are significant to the example:

* The `product` table contains the product information for all of the products.
* The `customer` table has a `customer_id` that has an `auto_increment`. A typical customer table would have a lot more columns, and sometimes additional detail tables.
* The `corder` table (named so because `order` is an SQL reserved word) has an `order_id` auto-increment column. It also has foreign keys into `customer(customer_id)` and `product(sku)`.

## Common Issues and Solutions

<b>Issue:</b> Starting Minikube produces the following error:
```sh
The "docker" driver should not be used with root privileges. If you wish to continue as root, use --force. 
If you are running minikube within a VM, consider using --driver=none: 
https://minikube.sigs.k8s.io/docs/reference/drivers/none
Exiting due to to DRV_AS_ROOT: The "docker" driver should not be used with root privileges.
``` 

<b>Solution:</b> Create a new user and add it to your [docker group](https://docs.docker.com/engine/install/linux-postinstall).


## Next Steps

You can now proceed with [MoveTables](../../user-guides/migration/move-tables).

Or alternatively, if you would like to teardown your example:

```sh
kubectl delete -f 101_initial_cluster.yaml
```
Congratulations on completing this exercise!
