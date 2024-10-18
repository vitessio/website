---
title: Overview
description: Frequently Asked Questions about Vitess
weight: 1
---

## How do I migrate my data to Vitess?

There are two main parts to migrating your data to Vitess: migrating the actual data and repointing the application. The answer here will focus primarily on the methods that can be used to migrate your data into Vitess.

There are three different methods to migrate your data into Vitess. Choosing the appropriate option depends on several factors like:

- The nature of the application accessing the MySQL database
- The size of the MySQL database to be migrated
- The load, especially the write load, on the MySQL database
- Your tolerance for downtime during the migration of data
- Whether you require the ability to reverse the migration if need be
- The network level configuration of your components

The three different methods are:

- ‘Stop-the-world’
- VReplication from Vitess setup in front of the existing external MySQL database
- Application-level migration

Choosing the Right Method

The first and most important point to consider when choosing the right method is whether you can or cannot interconnect between components on your network. If you cannot, or do not wish to, perform extra steps to ensure interconnectivity then you will need to use the ‘Stop-the-world’ method. 

If you can ensure interconnectivity and that the VTTablets are in the same Vitess cluster, then for cases when larger amounts of downtime are not an option you will want to use VReplication with either Movetables or Materialize. 

You can read more about each method [here](https://vitess.io/docs/user-guides/migration/migrate-data/).

## What is VTExplain?

VTExplain is a command line tool which provides information on how Vitess plans to execute a particular query. It can be used to validate queries for compatibility with Vitess.

For a more detailed walkthrough of VTExplain please go [here](https://vitess.io/docs/user-guides/sql/vtexplain/).

## Analyze queries for issues given a Vschema

To check your queries for issues you will need to follow these general steps. For a more detailed process that includes examples please refer to the documentation [here](https://vitess.io/docs/user-guides/sql/vtexplain/).

First you will need to gather most, if not all, of the queries that are sent to your current production database tracked over an extended period of time. You may need to track your sent queries for days or weeks depending on your set up. You will also need to normalize the queries you will be analyzing. To do this you can use any MySQL monitoring tool like VividCortex, Monyog or PMM. 

Once you have the full list of normalized queries you will need to filter out any that are not supported or are coming from other sources. Example unsupported queries are listed in the documentation [here](https://vitess.io/docs/reference/compatibility/mysql-compatibility/).

After filtering the list of queries you will need to generate and populate some fake values. To do this we have an example pipeline in the documentation [here](https://vitess.io/docs/user-guides/sql/vtexplain-in-bulk/#3-populate-fake-values-for-your-queries).

Once you have the fake values in place you can then run the [vtexplain](https://vitess.io/docs/faq/migrating/overview/#what-is-vtexplain) command against every query and then inspect the output for errors. You will likely want to use a script to do this. We have an example script as well as some setup steps in the documentation [here](https://vitess.io/docs/reference/programs/vtexplain/#example-usage).

Further case by case examples are available in the documentation starting [here](https://vitess.io/docs/user-guides/sql/vtexplain-in-bulk/).

vtexplain can also be used to try different sharding scenarios before deciding on one.