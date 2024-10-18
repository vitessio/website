---
title: Advanced Migrations
description: Frequently Asked Questions about Vitess
weight: 2
---

## How do I migrate to Vitess from a hosted MySQL?

If you are running a hosted MySQL like RDS on AWS, CloudSQL on GCP, or Azure managed MySQL, because you are not coming from MySQL you have to use either the ‘Stop-the-world’ method or the method using VReplication setup in front of the existing external database.  You can read more about those two methods [here](https://vitess.io/docs/user-guides/migration/migrate-data/).

There is no option to do an application level migration. 

The biggest challenge with this sort of migration is you must be able to access the source database from the location where you want to put the target database. You will need to ensure this configuration constraint is resolved and set up prior to any sort of migration.

## What is Gh-ost and how does it work?

Gh-ost is a trigger-less online schema migration solution for MySQL. It functions similarly to other existing online-schema-change tools that create a ghost table to perform migration, but opts to not use triggers.

Instead Gh-ost uses the binary log stream to capture table changes and asynchronously applies them onto the ghost table.

You can read a detailed description of Gh-ost here, as well as check out the documentation [here](https://github.com/github/gh-ost/tree/master/doc).

## What is Vstream and how does it work?

VStream is a change notification service accessible via VTGate. The purpose of VStream is to provide equivalent information to the MySQL binary logs from the underlying MySQL shards. 

gRPC clients, including Vitess components like VTTablets, can subscribe to a VStream to receive change events from other shards. The VStream pulls events from one or more VStreamer instances on VTTablet instances, which in turn pulls events from the binary log of the underlying MySQL instance. 

This allows for efficient execution of functions such as VReplication where a subscriber can indirectly receive events from the binary logs of one or more MySQL instance shards, and then apply it to a target instance. 

## How can Gh-ost be used with both sharded & unsharded keyspaces?

You can view the Vschema or the topology server to determine the location of each keyspace. However, we recommend that instead you use the steps outlined here. 

## Can online migrations be done while using LegacySplit?

Yes, as the migration steps are still the same. LegacySplit is just a different way of copying data that works when text columns are the primary key.