	---
title: Exporting data from Vitess
weight: 8
---

Since [VTGate](../../concepts/vtgate/) supports the MySQL protocol, in many cases it is possible to use existing client utilities when connecting to Vitess. This includes using logical dump tools such as `mysqldump`.

This guide provides instructions on the required options when using these tools against a VTGate server for the purposes of exporting data from Vitess. It is recommended to follow the [Backup and Restore](../backup-and-restore/) guide for regular backups, since this method is performed directly on the tablet servers and is more efficient for larger databases. 

### mysqldump

The default invocation of `mysqldump` attempts to execute statements which are [not supported by Vitess](../../reference/mysql-compatibility/), such as attempting to lock tables and dump GTID coordinates. The following options are required when using mysqldump from MySQL 5.7 to export data from the `commerce` keyspace:

* `--lock-tables=off`: VTGate currently prohibits the syntax `LOCK TABLES` and `UNLOCK TABLES`.
* `--set-gtid-purged=OFF`: mysqldump attemps to dump GTID coordinates of a server, but in the case of VTGate this does not make sense since it could be routing to multiple servers.
* `--no-tablespaces`: This option disables dumping InnoDB tables by tablespace. This functionality is not yet supported by Vitess.
* `--skip-network-timeout`: This option is required when using mysqldump from MySQL 8.0 ([#5401](https://github.com/vitessio/vitess/issues/5401)).

For example to export the `commerce` keyspace using mysqldump from MySQL 5.7:

```
mysqldump  --lock-tables=off --set-gtid-purged=OFF --no-tablespaces commerce > commerce.sql
```

