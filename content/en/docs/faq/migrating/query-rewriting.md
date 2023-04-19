---
title: Query Rewriting
description: Frequently Asked Questions about Vitess
weight: 3
---

## How can tables be migrated from using auto-increment to sequences?

Auto-increment columns do not work very well for sharded tables. Instead you will need to use Vitess sequences to solve this problem. 

Sequences are based on a MySQL table and use a single value in that table to describe which values the sequence should have next. Thus, the sequence table is an unsharded single row table that Vitess can use to generate monotonically increasing ids. 

Sequence tables must be specified in the VSchema, and then tied to table columns. Once they are associated, an insert on that table will transparently fetch an id from the sequence table, fill in the value, and route the row to the appropriate shard. At the time of insert, if no value is specified for such a column, VTGate will generate a number for it using the sequence table.

To create a sequence you will need to follow the steps [here](https://vitess.io/docs/reference/features/vitess-sequences/#creating-a-sequence).

## Is there a list of supported and unsupported queries?

Please see "SQL Syntax" under [MySQL Compatibility](https://vitess.io/docs/reference/compatibility/mysql-compatibility/).

## What special functions can Vitess handle?

We list out the special functions that Vitess handles without delegating to MySQL [here](https://vitess.io/docs/concepts/query-rewriting/#special-functions).

Please note that the Vitess community determined a workaround if you want to use a JPA like Hibernate/Eclipselink to talk to Vitess.  

Rather than using `GenerationType.IDENTITY` you can use Eclipselink QuerySequence to define a query directly to Vitess Sequences tables. This not only prevents `SELECT LAST_INSERT_ID()` call but also can reduce the number of database trips since the application could request a bunch of IDs from Vitess. Potentially around 1000, so this setup will make only one call per 1000 inserts.