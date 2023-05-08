---
title: Supported Databases  
weight: 2
featured: true
---

Vitess deploys, scales and manages clusters of open-source SQL database instances. Currently, Vitess supports the [MySQL](https://www.mysql.com/) and [Percona Server for MySQL](https://www.percona.com/software/mysql-database/percona-server) databases.

The [VTGate](../../concepts/vtgate/) proxy server advertises its version as MySQL 8.0.

## MySQL versions 5.7 to 8.0

Vitess supports the core features of MySQL versions 5.7 to 8.0, with [some limitations](../../reference/compatibility/mysql-compatibility/). Vitess also supports [Percona Server for MySQL](https://www.percona.com/software/mysql-database/percona-server) versions 5.7 to 8.0.

{{< info >}}For new Vitess installations, MySQL or Percona Server for MySQL version 8 are recommended.{{< /info >}}

## See also

+ [MySQL Compatibility](../../reference/compatibility/mysql-compatibility/)
