---
title: Migrating Data Into Vitess
weight: 1
aliases: ['/docs/user-guides/migrate-data/'] 
---

# Introduction 

There are two main parts to migrating your data to Vitess: migrating the actual data and repointing the application. This page will focus primarily on the methods that can be used to migrate *your data* into Vitess.

## Overview

There are different methods to migrate your data into Vitess. Choosing the appropriate option depends on several factors:
1. The nature of the application accessing the MySQL database
1. The size of the MySQL database to be migrated
1. The load, especially the write load, on the MySQL database
1. Your tolerance for downtime during the migration of data
1. Whether you require the ability to reverse the migration if needed
1. The network level configuration of your components

The two primary methods are:

* Dump and Restore
* VReplication (**Recommended**)

## Dump and Restore

{{< warning >}}
This method likely isn’t viable for most production applications as it will incur significant application downtime.
{{</ warning >}}

The simplest method to migrate data is to do a data dump and restore (AKA "stop-the-world"). For this we recommend using [`mysqldump`](https://dev.mysql.com/doc/refman/en/mysqldump.html) or
[`go-mydumper`](https://github.com/aquarapid/go-mydumper). To execute this method you would follow these steps:
1. Stop writing to the source MySQL database
1. Take a logical dump of the database
1. Apply any simple transformations on the output if needed
1. Import the data into Vitess via the frontend [Vitess Gateway](../../../concepts/vtgate/) (`vtgate`)
1. Repoint your application to the new database via a [Vitess Gateway](../../../concepts/vtgate/) and resume writing

This method is only suitable for migrating small or non-critical databases that can tolerate downtime. The database will be unavailable for writes between the time the dump is started and the time the restore of the dump is completed. For databases of 10’s of GB and up this process could take hours or even days. The amount of downtime scales with the amount of data being migrated.

## VReplication

Vitess provides the [`MoveTables`](../../../reference/vreplication/movetables/) command which allows you to perform
fully online data migrations into Vitess with the ability to (temporarily) revert the migration if needed — all
without incurring application downtime.

An ["unmanaged Vitess tablet"](../../configuration-advanced/unmanaged-tablet/) will be placed in front of your existing MySQL database. This tablet will then be the bridge that allows you to migrate the data into Vitess. This unmanaged tablet ([`vttablet`](../../../reference/programs/vttablet/)) must be able to communicate with your new Vitess cluster over the network.

This method uses a combination of transactional SELECTs and filtered MySQL replication to safely and accurately copy each
of the tables in the source database to Vitess without disrupting normal traffic to your existing database. Once all the
data is copied, the two databases are then kept in sync using a replication stream from the source database. You can
verify that the source and destination are fully in sync using [`VDiff`](../../../reference/vreplication/vdiff/) command
and perform final testing on the Vitess keyspace before cutting over your application traffic.

Once your testing has completed, application traffic can be moved from the source MySQL database itself and switched to the Vitess cluster's [`vtgate`](../../../reference/programs/vtgate/) instance(s). For this switch, a small amount of downtime will likely be necessary. This downtime could be seconds or minutes, depending on the application and application automation.

Once your application traffic is going to Vitess — while your original MySQL instance is still serving the queries — you can prepare to fully cutover all traffic and query serving using the [`SwitchTraffic`](../../../reference/vreplication/movetables/#switchtraffic) action. This will cause the Vitess cluster to start serving all traffic for the tables that were migrated. At this point the VReplication workflow automatically reverses and the original MySQL instance is automatically kept in sync with Vitess. Once the switch is complete and you have confirmed that everything is working
correctly you can complete the migration using the [`Complete`](../../../reference/vreplication/movetables/#complete)
action and the original MySQL instance can be shut down. If for any reason you need to reverse the migration, you
can use the [`ReverseTraffic`](../../../reference/vreplication/movetables/#reversetraffic) action to switch back to
serving data from the original MySQL instance before later attempt another cutover using [`SwitchTraffic`](../../../reference/vreplication/movetables/#switchtraffic).

{{< info >}}
If you require transforming your data while migrating it into Vitess then the [`Materialize`](../../../reference/vreplication/materialize/) command offers an alternative to [`MoveTables`](../../../reference/vreplication/movetables/).
{{</ info >}}

The remaining pages in this guide walk you through an example of the key steps for this native Vitess migration process:
1. [Moving the tables](../move-tables/)
2. [Materializing data if needed](../materialize/)
3. [Troubleshooting](../troubleshooting/)
