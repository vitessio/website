---
title: Query Serving
weight: 1
description: Errors a users might encounter while querying Vitess
---

{{< info >}}
These error messages are internal to Vitess. If you are getting other errors from MySQL you can check them on this MySQL error [page](https://dev.mysql.com/doc/mysql-errors/5.7/en/server-error-reference.html).
{{< /info >}}

<!-- start -->
## Errors

| ID | Description | Error | MySQL Error Code | SQL State |
| --- | --- | --- | --- | --- |
| VT03001 | The planner accepts aggregate functions that take a single argument only. | aggregate functions take a single argument '%s' | 1149 | 42000 |
| VT03002 | aa | Changing schema from '%s' to '%s' is not allowed | 1450 | HY000 |
| VT03003 | aa | Unknown table '%s' in MULTI DELETE | 1109 | 42S02 |
| VT03004 | aa | The target table %s of the DELETE is not updatable | 1288 | HY000 |
| VT05001 | aa | Can't drop database '%s'; database doesn't exists | 1008 | HY000 |
| VT05002 | aa | Can't alter database '%s'; unknown database | 1049 | 42000 |
| VT06001 | aa | Can't create database '%s'; database exists | 1007 | HY000 |
| VT12001 | aa | unsupported: %s |  |  |
| VT13001 | aa | [BUG] %s |  |  |
| VT13002 | aa | [BUG] %s |  |  |
<!-- end -->
