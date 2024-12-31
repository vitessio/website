---
title: Compatibility
weight: 2
---

## What versions of MySQL or MariaDB work with Vitess?

Please refer to our [Supported Databases](https://vitess.io/docs/overview/supported-databases/) for the most up-to-date information.

## What does it mean to say that Vitess "is MySQL compatible"? Will my application "just work"?

Vitess supports much of MySQL, with some limitations. **Depending on your MySQL setup you will need to adjust queries that utilize any of the current unsupported cases.**

For SQL syntax there is a list of example [unsupported queries](https://github.com/vitessio/vitess/blob/main/go/vt/vtgate/planbuilder/testdata/unsupported_cases.json). 

There are some further [compatibility issues](https://vitess.io/docs/reference/mysql-compatibility/) beyond pure SQL syntax.

## How is Vitess different from MySQL?

MySQL is a popular open source database solution. MySQL delivers a fast, multi-threaded, multi-user, and robust SQL (Structured Query Language) database server. 
However, MySQL starts running into limitations with large data sizes or large numbers of concurrent users.

Vitess is a database scaling system designed to be used with MySQL. It enables deploying, scaling and managing large clusters of MySQL instances with built-in sharding, high availability and connection pooling.

## How is Vitess different from RDS for MySQL?

RDS for MySQL is a managed service from AWS which has many of the same limitations as open source or enterprise MySQL.

## How is Vitess different from AWS Aurora for MySQL?

AWS Aurora for MySQL is a managed service from AWS which can scale beyond the limitations of RDS for MySQL. However, it cannot scale to the same extent as Vitess.

## Are foreign keys supported in Vitess?

We generally discourage the use of foreign keys, and more specifically foreign key constraints. There may be unexpected consequences when using them in sharded keyspaces.
However, you can use foreign key constraints when their scope is contained within a shard or unsharded keyspace. You will need to [configure](https://vitess.io/docs/user-guides/vschema-guide/foreign-keys/) Vitess with the desired level of support.
Please note that if you do shard or re-shard an existing keyspqce with foreign keys, you will need to take extra steps to confirm they are working as intended. 

