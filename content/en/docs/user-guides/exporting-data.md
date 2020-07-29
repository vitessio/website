	---
title: Exporting data from Vitess
weight: 8
---

Since [VTGate](../../concepts/vtgate/) supports the MySQL protocol, in many cases it is possible to use existing client utilities when connecting to Vitess. This includes using logical dump tools such as `mysqldump`, in certain cases.

This guide provides instructions on the required options when using these tools against a VTGate server for the purposes of exporting data from Vitess. It is recommended to follow the [Backup and Restore](../backup-and-restore/) guide for regular backups, since this method is performed directly on the tablet servers and is more efficient and safer databases of any significant size.  Keep in mind that Vitess also does not implement all the locking constructs across a sharded database that is necessary to do a consistent logical backup using these tools if the database is being written to while the backup is running. As a result these methods are typically not suitable for production backups.

### mysqldump

The default invocation of `mysqldump` attempts to execute statements which are [not supported by Vitess](../../reference/mysql-compatibility/), such as attempting to lock tables and dump GTID coordinates. The following options are required when using the `mysqldump` binary from MySQL 5.7 to export data from the `commerce` keyspace:

* `--lock-tables=off`: VTGate currently prohibits the syntax `LOCK TABLES` and `UNLOCK TABLES`.
* `--set-gtid-purged=OFF`: `mysqldump` attemps to dump GTID coordinates of a server, but in the case of VTGate this does not make sense since it could be routing to multiple servers.
* `--no-tablespaces`: This option disables dumping InnoDB tables by tablespace. This functionality is not yet supported by Vitess.
* `--skip-network-timeout`: This option is required when using `mysqldump` from MySQL 8.0 ([#5401](https://github.com/vitessio/vitess/issues/5401)).

For example to export the `commerce` keyspace using the `mysqldump` binary from MySQL 5.7:

```
mysqldump  --lock-tables=off --set-gtid-purged=OFF --no-tablespaces commerce > commerce.sql
```

Note that if you are using the `mysqldump` binary from MySQL 8.0, this will not work, since the newer version `mysqldump` sends additional commands to the server, which are not yet supported by Vitess.

To restore dump files created by `mysqldump`, you can just replay it against a Vitess server (or potentially a normal MySQL server) using the `mysql` commandline client.

### go-mydumper

Alternatively, you can use a slight modification of the `go-mydumper` tool to export logical dumps of a Vitess keyspace. `go-mydumper` has the advantage of being multi-threaded, and so can run faster on a database that has many tables.  For a database with just one or a handful of large tables, `go-mydumper` may not be that much faster than `mysqldump`.

For information on the Vitess-compatible fork of `go-mydumper` see https://github.com/aquarapid/go-mydumper . Examples and instructions are available in the [README.md](https://github.com/aquarapid/go-mydumper/README.md) in that repo.  You will need to be able to compile golang binaries to use this tool.

`go-mydumper` creates multiple files for each backup.  To restore a backup, you can use the `mysql` commandline client, but using the `myloader` tool as described in the `go-mydumper` repo above is easier and can be faster, since the loader is also multithreaded.
