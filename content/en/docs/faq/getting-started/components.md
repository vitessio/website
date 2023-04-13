---
title: Components
description: Frequently Asked Questions about Vitess
weight: 3
---

## What is vtgate and how does it work? 

VTGate is a lightweight proxy server that sits between your application and your shards, which contain your data. VTGates are essentially stateless, extremely scalable, and not very resource intensive on memory.

Some of VTGate’s main functions are as follows:
* Keeps track of the Vitess cluster state, and routes traffic accordingly.
* Parse SQL queries fully, and combines that understanding with Vitess VSchema direct queries correct VTTablet (or set of VTTablets) and returns consolidated results back to the client. 
* It speaks both the MySQL Protocol and the Vitess gRPC protocol. Thus, your applications can connect to VTGate as if it is a MySQL Server.
* Aware of failovers in underlying shards, allowing buffering of queries to allow for reduced application impact.

## What is vttablet? How does it work with MySQL? 

A VTTablet is the Vitess component that both front-ends and, optionally, controls a running MySQL server. It accepts queries over gRPC and translates the queries back to MySQL, as well as speaking to MySQL to issue commands to control replication, take backups, etc.

Things to note about VTTablet are:
* There needs to be a one to one mapping of MySQLd and each VTTablet. 
* VTTablet will track long running queries and for how long they have run. It also will kill the long running queries itself.
* VTTablet will create a sidecar database when running to store the local state of the cluster. 
* The combination of a VTTablet process and a MySQL process is called a Tablet.


Please do note that in some cases VTTablets may be deployed as unmanaged/remote or partially managed. You can read about that [here](https://vitess.io/docs/reference/programs/vttablet/#managed-mysql).

## What is vtctld? 

vtctld is a Vitess server component that can perform various Vitess cluster- and component-level operations on behalf of an administrative user. You can interact with vtctld via a web UI, or via an gRPC interface using the vtctlclient CLI tool. The web UI allows you to browse the information stored in the Topology Service, and can be useful for troubleshooting or for getting a high-level overview of the cluster components and their current states.

Some of the administrative actions vtctld can perform include: reparents (failovers), backups, sharding, shard splits, resharding, and shard combines.

## What is a keyspace? 

A keyspace is a logical database. If you’re using sharding, a keyspace maps to multiple MySQL instances; if you’re not using sharding, a keyspace maps directly to a single MySQL database in a single MySQL instance. In either case, a keyspace appears as a single database from the application's viewpoint.

Reading data from a keyspace is just like reading from a MySQL database. However, depending on the consistency requirements of the read operation, Vitess might fetch the data from a primary database or from a replica. By routing each query to the appropriate database, Vitess allows your code to be structured as if it were reading from a single MySQL database.

## What is vtctlclient?

This is a Vitess CLI used to execute gRPC commands against vtctld. It is the most common way to perform administrative commands against a running Vitess cluster. 

## What is a cell? How does it work?

A cell is a group of servers and associated network infrastructure collocated in an area, and isolated from failures in other cells. It is typically either a full data center or a subset of a data center, sometimes called a zone or availability zone. Vitess gracefully handles cell-level failures, such as when a cell is isolated from other cells by a network failure. A useful way to think of a cell is as a failure domain.

Each cell in a Vitess implementation has a local Topology Service, which is hosted in that cell. The Topology Service contains most of the information about the Vitess tablets in its cell. This enables a cell to be taken down and rebuilt as a unit.

Vitess limits cross-cell traffic for both data and metadata. Vitess currently serves reads only from the local cell. Writes will go cross-cell as necessary, to wherever the primary for that shard resides.

## What is a tablet? What are the types?

A tablet is a combination of a MySQLd process and a corresponding vttablet process, usually running on the same machine. Each tablet is assigned a tablet type, which specifies what role it currently performs. The main tablet types are listed below:

* primary - A tablet that contains a MySQL instance that is currently the MySQL primary for its shard.
* replica - A tablet that contains a MySQL replica that is eligible to be promoted to primary. Conventionally, these are reserved for serving live, user-facing read-only requests (like from the website’s frontend).
* rdonly - A tablet that contains a MySQL replica that cannot be promoted to primary. Conventionally, these are used for background processing jobs, such as taking backups, dumping data to other systems, heavy analytical queries, MapReduce, and resharding.

There are a few more tablet types that you can read about here. For information on how to use tablets please review the user guide here for more information.

## What is a shard?

A shard is a physical division within a keyspace;  i.e. how data is split across multiple MySQL instances. A shard typically consists of one MySQL primary and one or more MySQL replicas.

Each MySQL instance within a shard has the same data, if the effects of MySQL replication lag is ignored. The replicas can serve read-only traffic, execute long-running queries from data analysis tools, or perform administrative tasks.

An unsharded keyspace always has only a single shard.