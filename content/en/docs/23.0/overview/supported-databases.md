---
title: Supported Databases  
weight: 2
featured: true
---

## Supported Databases In Vitess

Vitess deploys, scales and manages clusters of open-source SQL database instances. Currently, Vitess supports the [MySQL](https://www.mysql.com/) and [Percona Server for MySQL](https://www.percona.com/software/mysql-database/percona-server) databases.

The [VTGate](../../concepts/vtgate/) proxy server advertises its version as MySQL 8.0.

### MySQL 8.0

Vitess supports the core features of MySQL 8.0.\*,
with [some limitations](../../reference/compatibility/mysql-compatibility/). Vitess also
supports [Percona Server for MySQL](https://www.percona.com/software/mysql-database/percona-server) 8.0.\*.

### Experimental MySQL 8.4 support

Vitess has experimental MySQL 8.4 support with
[the same limitations](../../reference/compatibility/mysql-compatibility/) as 8.0.\*.

## Supported Databases For Imports

Vitess supports importing from a wide range of databases that include: 

- [MySQL](https://www.mysql.com/) version 5.7 to 8.0. Experimental support for 8.4.
- [Percona Server for MySQL](https://www.percona.com/software/mysql-database/percona-server) version 5.7 to 8.0. Experimental support for 8.4.
- [MariaDB](https://mariadb.com) versions 10.10+

## See also

+ [MySQL Compatibility](../../reference/compatibility/mysql-compatibility/)
