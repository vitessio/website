---
title: Components
weight: 3
---

## What is VTGate and how does it work?

VTGate is a lightweight proxy server that sits between your application and your shards, which contain your data. VTGates are essentially stateless and in many cases, you can scale with query load by adding more VTGate instances.
Some of the main functions performed by VTGate are as follows:
* Keeps track of the Vitess cluster state, and route traffic accordingly.
* Parses SQL queries fully, and combines that understanding with Vitess VSchema to direct queries to the appropriate VTTablet (or set of VTTablets) and returns consolidated results back to the client.
* Supports both the MySQL Protocol and the gRPC protocol. Thus, your applications can connect to VTGate as if it is a MySQL Server.
* Is aware of failovers in underlying shards, and performs buffering of queries to reduce application impact.

## What is VTTablet? How does it work with MySQL?

A VTTablet is the Vitess component that both front-ends and, optionally, controls a running MySQL server. It accepts queries over gRPC and translates the queries back to MySQL, as well as speaking to MySQL to issue commands to control replication, take backups, etc.

Things to note about VTTablet are:
* Each mysqld needs a VTTablet that manages it.
* VTTablet tracks long running queries and kills them when they exceed a defined threshold.
* The combination of a VTTablet process and a MySQL process is called a Tablet.

Please note that in some cases VTTablets may be deployed as [unmanaged/remote or partially managed](https://vitess.io/docs/reference/programs/vttablet/#managed-mysql).
The recommendation is to start with unmanaged mode but eventually migrate to managed mode. Operations like resharding are possible only with vitess-managed MySQL servers.

## What is VTCtld?

VTCtld is a Vitess server component that can perform various Vitess cluster- and component-level operations on behalf of an administrative user. You can interact with VTCtld via a web UI, or via an gRPC interface using the vtctldclient CLI tool.
It has an administrative UI called VTAdmin.

Some of the administrative actions VTCtld can perform include: reparents (failovers), backups, shard splits, resharding, and shard merges.

## What is a keyspace? 

A keyspace is a logical database. Typically, a keyspace maps to multiple MySQL instances regardless of sharding. This is because it is recommended to run multiple replicas even for an unsharded keyspace. In other words, a keyspace appears as a single database from the application's viewpoint.

Reading data from a keyspace is just like reading from a MySQL database.

## What is vtctldclient?

This is a Vitess CLI used to execute gRPC commands against VTCtld. It is the most common way to perform administrative commands against a running Vitess cluster. 

## What is a cell? How does it work?

A cell is a group of servers and associated network infrastructure co-located in an area, and isolated from failures in other cells. It is typically either a full data center or a subset of a data center, sometimes called a zone or availability zone. Vitess gracefully handles cell-level failures, such as when a cell is isolated from other cells by a network failure. A useful way to think of a cell is as a failure domain.

Each cell in a Vitess implementation has a local Topology Service, which is hosted in that cell. The Topology Service contains most of the information about the Vitess tablets in its cell. This enables a cell to be taken down and rebuilt as a unit.

Vitess limits cross-cell traffic for both data and metadata. Vitess currently serves reads only from the local cell. Writes will go cross-cell as necessary, to wherever the primary for that shard resides.

## What is a tablet? What are the types?

A tablet is a combination of a mysqld process and a corresponding VTTablet process, usually running on the same machine. Each tablet is assigned a tablet type, which specifies what role it currently performs. The main tablet types are listed below:

* PRIMARY - A tablet that contains a MySQL instance that is currently the MySQL primary for its shard.
* REPLICA - A tablet that contains a MySQL replica that is eligible to be promoted to primary. Conventionally, these are reserved for serving live, user-facing read-only requests (like from the website’s frontend).
* RDONLY - A tablet that contains a MySQL replica that cannot be promoted to primary. Conventionally, these are used for background processing jobs, such as taking backups, dumping data to other systems, heavy analytical queries, and resharding.

There are some other tablet types like `BACKUP` and `RESTORE`. For information on how to use tablets please review this [user guide](https://vitess.io/docs/user-guides/configuration-basic/vttablet-mysql/).

## What is a shard?

A shard is a physical division within a keyspace;  i.e. how data is split across multiple MySQL instances. A shard typically consists of one MySQL primary and one or more MySQL replicas.

Each MySQL instance within a shard has the same data, if the effect of MySQL replication lag is ignored. The replicas can serve read-only traffic, execute long-running queries from data analysis tools, or perform administrative tasks.

An unsharded keyspace always has only a single shard.
