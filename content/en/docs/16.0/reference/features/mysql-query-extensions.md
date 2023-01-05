---
title: MySQL Query Language Extensions
weight: 9
aliases: []
---

Vitess uses the MySQL [client server protocol](https://dev.mysql.com/doc/internals/en/client-server-protocol.html) and [query language](https://dev.mysql.com/doc/refman/en/language-structure.html). While there are some [limitations and compatibility mismatches](../../compatibility/mysql-compatibility/), Vitess also expands on the MySQL query language for Vitess specific usage.

## Extensions to the MySQL Query Language

* [SHOW](../show) has some additional functionality.
* [VEXPLAIN](../../../user-guides/sql/explain-format-vtexplain) is similar to `EXPLAIN` but specifically for Vitess plans
* You can use a special `SELECT` query to see the next value from a sequence:

```sql
select next value from user_seq;
```
