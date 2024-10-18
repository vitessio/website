---
title: Overview
description: Frequently Asked Questions about Vitess
weight: 1
---

## How much resources (memory, CPU, disk) does Vitess use?

**CPU**

Vitess components (excluding the underlying MySQL server) tend to be CPU-bound processes. It is recommended to: 

* Allocate 2-4 CPU cores for each VTGate server. 
* And allocate the same number of cores for VTTablet as with MySQLd. 
	* If you are provisioning for a new workload, we recommend projecting that MySQLd will require 1 core per 1500 QPS.

Assuming tablets are kept to the recommended size of 250GB:
* Start with a baseline CPU requirement of 2-4 cores for MySQLd 
* And allocate 2-4 cores for the VTTablet process.

{{< info >}}
Note that this is very workload-dependent. We recommend testing the configuration for yourself as performance can vary depending on your query pattern, query size, concurrency, etc.
{{< /info >}}

**Memory**

The memory requirements for VTGate and VTTablet servers will depend on QPS and query result set sizes. We recommend:

* Provisioning a baseline of 1GB per core.
* Allocating additional memory if you are increasing the Vitess default row limits and/or expect many concurrent queries returning large result sets. Note that this may not be necessary if your large result set queries use streaming.

**Latency**

The impact of network latency can be a factor when migrating from MySQL to Vitess. A simple rule of thumb is to estimate 2ms of round trip latency added to each query.  This may be higher in a cloud environment, depending on your choice of load balancer, availability zone placement, etc.

**Topology Service**

For estimating CPU/memory/disk requirements of your chosen Topology Service, you can use the minimum requirements recommended by the topology server implementation.

## What is Vitess?

**Vitess is a database solution for deploying, scaling and managing large clusters of database instances.** 

It is architected to run as effectively in a public or private cloud architecture as it does on dedicated hardware. It combines and extends many SQL features with the scalability of a NoSQL database. Vitess can help you with the following problems:

* Scaling a SQL database by allowing you to shard it, while keeping your application changes to a minimum.
* Migrating from bare metal to a private or public cloud.
* Deploying and managing a large number of SQL database instances.

## What is Vitess and MySQL's relationship?

**Vitess is not a database system itself, instead it is an overlay on top of MySQL.**

Vitess provides a sharding system for MySQL, as well as some operational management for its instances. Vitess will assist with actions like sharding, managing backup and restore, and splitting, combining, and adding replicas. 

However, it is important to note that implementers of Vitess will need to provide their own MySQL and perform their own MySQL management.  The amount of MySQL management required depends on if Vitess is configured to run with "integrated" MySQL (i.e. MySQL managed by Vitess) or "external" MySQL.

Vitess can run against various flavors/implementations of MySQL, e.g. MySQL Community Edition, MySQL Enterprise Edition, Percona Server, MariaDB Server.  Vitess can also be used with many Cloud deployments of MySQL, e.g. AWS RDS, AWS Aurora, GCP Cloud SQL, etc.

## How can I migrate out of Vitess? 

In order to migrate out of Vitess you will need to take a backup of your data using one of the three possible methods: backup and restore, mysqldump, and go-mydumper.

We recommend following the [Backup and Restore](https://vitess.io/docs/user-guides/operating-vitess/backup-and-restore/) guide for regular backups in order to migrate out of Vitess. This method is performed directly on the tablet servers and is more efficient and safer for databases of any significant size. The downside is that this is a physical MySQL instance backup, and needs to be restored accordingly.

Both mysqldump and go-mydumper are not typically suitable for production backups. This is because Vitess does not implement all the locking constructs across a sharded database that are necessary to do a consistent logical backup while writing to the database.  However, it may be appropriate if you are able to stop all writes to Vitess for the period that the dump process is running;  or you are just backing up tables that are not receiving any writes. You can read more about exporting data from Vitess [here](https://vitess.io/docs/user-guides/configuration-basic/exporting-data/).

## How do Vitess replicas stay in sync? Do replicas use VReplication?

Every shard in Vitess uses normal MySQL replication to replicate changes from the primary for that shard to the replica(s). Vitess can use asynchronous MySQL replication (the default), but can also be configured to use semi-synchronous MySQL replication for environments with higher durability requirements.

VReplication is used internally in Vitess for items like resharding, moving tables, and materialized views. It is not used directly to keep replicas in sync with a primary.

## What are the main components of Vitess? 

Vitess consists of a number of server processes and command-line utilities and is backed by a consistent metadata store. The main server components consist of: 

* vtgate
* Topology server 
* vtctld 
* Tablets which are made up of vttablets and mysqld

The diagram below illustrates Vitess’ components and their location within Vitess’ architecture:

<img alt="Vitess Components" src="../img/vitess-components.png"  width=100%>

## Are microservices recommended for scaling? 

It’s better to think of microservices as a design principle rather than as a scaling trick. This architecture is more tailored to improving resilience and flexibility for deployment, by breaking up monolithic deployments into more loosely coupled, isolated elements. The complexity of managing resources for horizontal sharding aligns closely with the challenges of managing resources in a microservices architecture.

Because of this added management complexity, Vitess is a good fit for a container orchestration environment to offset some of this additional complexity. Vitess is commonly deployed/managed in containers using the Vitess Operator for Kubernetes.

In short, horizontally scaling MySQL is made possible by Vitess, both in microservices architectures, as well as more traditional environments.

It is not unusual for a well-configured single-server MySQL installation to serve hundreds of thousands of queries per second, so keep in mind that any scaling challenges you might face could also be resolved by optimizing your code, queries, schema and/or MySQL configuration.

One common challenge faced by users implementing a large-scale microservices architecture, while still keeping a unified database architecture, is that the number of MySQL protocol client connections to the central database can become overwhelming, even with client-side connection pooling.  Vitess handles this by effectively introducing additional layers of connection pooling, ensuring that the backend MySQL instances are not overwhelmed.