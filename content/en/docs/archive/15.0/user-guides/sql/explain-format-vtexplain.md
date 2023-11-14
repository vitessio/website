---
title: Analyzing a SQL statement using EXPLAIN FORMAT=vtexplain
weight: 1
aliases: ['/docs/user-guides/vtexplain/']
---

# Introduction

To see which queries are run on your behalf on the MySQL instances when you execute a query on vtgate, you can use `explain format=vtexplain`.  
It returns an output similar to what the command line application [`vtexplain`](../../../reference/programs/vtexplain) returns - a list of the queries that have been run on MySQL, and against which shards they were issued.

# How it works

Unlike normal `EXPLAIN` queries, `format=vtexplain` actually runs your query, and logs the interactions with the tablets.
After running your query using this extra logging, the result you get is a table with all the interactions listed.

# How to read the output

The output has four columns:
* The first column, `#` groups queries that were sent in a single call together.
* Keyspace - which keyspace was this query sent to.
* Shard - for sharded keyspaces, this column will show which shard a query is sent to.
* Query - the actual query used.

## Example 1:
```mysql
mysql> explain format=vtexplain select * from user where id = 4;
+------+----------+-------+-----------------------------------------------------------+
| #    | keyspace | shard | query                                                     |
+------+----------+-------+-----------------------------------------------------------+
|    0 | ks       | c0-   | select id, lookup, lookup_unique from `user` where id = 4 |
+------+----------+-------+-----------------------------------------------------------+
1 row in set (0.00 sec)
```

Here we have a query where the planner can immediately see which shard to send the query to.

## Example 2:
```mysql
mysql> explain format=vtexplain select * from user where lookup = 'apa';
+------+----------+-------+-------------------------------------------------------------------+
| #    | keyspace | shard | query                                                             |
+------+----------+-------+-------------------------------------------------------------------+
|    0 | ks       | -40   | select lookup, keyspace_id from lookup where lookup in ('apa')    |
|    1 | ks       | c0-   | select id, lookup, lookup_unique from `user` where lookup = 'apa' |
|    2 | ks       | 40-80 | select id, lookup, lookup_unique from `user` where lookup = 'apa' |
+------+----------+-------+-------------------------------------------------------------------+
3 rows in set (0.02 sec)
```

This is a query where the planner has to do a vindex lookup to find which shard the data might live on.

# Safety for DML

The normal behaviour for `EXPLAIN` is to not actually run the query - it usually only plans the query and presents the produced plan.
Since `explain format=vtexplain` really runs your queries, you need to add a query directive to show that you are aware that your DML will actually run.

## Example 3:

```mysql
mysql> explain format=vtexplain insert into user (id,lookup,lookup_unique) values (34,'Mr Fox','fox');
ERROR 1105 (HY000): explain format = vtexplain will actually run queries. `/*vt+ ACTUALLY_RUN_QUERIES */` must be set to run DML queries in vtexplain. Example: `explain /*vt+ ACTUALLY_RUN_QUERIES */ format = vtexplain delete from t1`
```

This is the error you will get is you do not add the comment directive to your `EXPLAIN` statement.

## Example 4:

```mysql
mysql> explain /*vt+ ACTUALLY_RUN_QUERIES */ format=vtexplain insert into user (id,lookup,lookup_unique) values (34,'Mr Fox','fox');
+------+----------+-------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| #    | keyspace | shard | query                                                                                                                                                                             |
+------+----------+-------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|    0 | ks       | -40   | insert into lookup(lookup, id, keyspace_id) values ('Mr Fox', 34, '�C�+.lk[') on duplicate key update lookup = values(lookup), id = values(id), keyspace_id = values(keyspace_id)   |
|    1 | ks       | c0-   | insert into lookup_unique(lookup_unique, keyspace_id) values ('fox', '�C�+.lk[')                                                                                                    |
|    2 | ks       | c0-   | insert into `user`(id, lookup, lookup_unique) values (34, 'Mr Fox', 'fox')                                                                                                        |
+------+----------+-------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
3 rows in set (0.02 sec)
```

Here we can see how vtgate will insert rows to the main table, but also to the two lookup vindexes declared for this table.
