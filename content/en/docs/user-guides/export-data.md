	---
title: Export data from Vitess
weight: 8
---

Since [VTGate](../../concepts/vtgate/) supports the MySQL protocol, in many cases it is possible to use existing client utilities when connecting to Vitess.  This includes using logical dump tools such as `mysqldump` or `mydumper`.

This guide provides instructions on the required options when using these tools against a VTGate server for the purposes of exporting data from Vitess. It is recommended to follow the [Backup and Restore](../backup-and-restore/) guide for regular backups, since this method is performed directly on the tablet servers and is more efficient for larger databases. 

### mysqldump

The default invocation of `mysqldump` attempts to execute statements which are [not supported by Vitess](../../reference/mysql-compatibility/), such as attempting to lock tables and dump GTID coordinates. The following options are required when using mysqldump from MySQL 5.7 to export data from the `commerce` keyspace:

```
$ mysqldump  --lock-tables=off --quote-names --set-gtid-purged=OFF --no-tablespaces commerce > commerce.sql
```

The option `--skip-network-timeout` is also required in MySQL 8.0 ([#5401](https://github.com/vitessio/vitess/issues/5401)).

