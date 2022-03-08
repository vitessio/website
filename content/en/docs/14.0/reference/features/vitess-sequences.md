---
title: Sequences
weight: 3
aliases: ['/docs/reference/vitess-sequences/']
---

This document describes the Vitess Sequences feature, and how to use it.

## Motivation

MySQL provides the `auto_increment` feature to assign monotonically incrementing
IDs to a column in a table. However, when a table is sharded across multiple
instances, maintaining the same feature is a lot more tricky.

Vitess Sequences fill that gap:

* Inspired from the usual SQL sequences (implemented in different ways by
  Oracle, SQL Server and PostgreSQL).

* Very high throughput for ID creation, using a configurable in-memory block allocation.

* Transparent use, similar to MySQL `auto_increment`: when the field is omitted in
  an `insert` statement, the next sequence value is used.

## When *not* to use `auto_increment`

Let us start by exploring the limitations and drawbacks of using an
`auto_increment` column.

### Security Considerations

Using `auto_increment` can leak confidential information about a service. Take
the example of a web site that store user information, and assign user IDs
to its users as they sign in. The user ID is then passed in a cookie for all
subsequent requests.

The client then knows their own user ID. It is now possible to:

* Try other user IDs and expose potential system vulnerabilities.

* Get an approximate number of users of the system (using the user ID).

* Get an approximate number of sign-ups during a week (creating two accounts a
  week apart, and diffing the two IDs).

Auto-incrementing IDs should be reserved for either internal applications, or
exposed to the clients only when safe.

### Alternatives

Alternative to auto-incrementing IDs are:

* Using a 64 bit random generator number. Try to insert a new row with that
  ID. If taken (because the statement returns an integrity error), try another
  ID.

* Using a UUID scheme, and generate truly unique IDs.

Now that this is out of the way, let's examine the specifics of
[MySQL auto_increment](https://dev.mysql.com/doc/refman/en/example-auto-increment.html).

## MySQL `auto_increment` Feature

Comparing `auto_increment` features, properties, and behaviors that Vitess Sequences share:

* A row that has no value provided for the `auto_increment` column will be given the next ID.

* The current ID value is stored in table metadata.

* Values may be ‘burned’ (by rolled back transactions) and gaps in the generated and stored values are possible.

* The value stored by the primary instance resulting from the original statement is sent in the replication stream,
  so replicas will have the same value when re-playing the stream.

* There is no strict guarantee about ordering: two concurrent statements may
  have their commit time in one order, but their auto-incrementing ID in the
  opposite order (as the value for the ID is reserved when the statement is
  issued, not when the transaction is committed).

* When inserting a row in a table with an `auto_increment` column, if the value
  for the `auto_increment` column is generated (not explicitly specified in the
  statement), the value for the column is returned to the client alongside the
  statement result (which can be queried with [`LAST_INSERT_ID()`](https://dev.mysql.com/doc/refman/en/information-functions.html#function_last-insert-id)).

## Vitess Sequences

Each sequence has a backing MySQL table — which **must** be in an unsharded keyspace — and
uses a single row in that table to describe which values the sequence should have next.
To improve performance we also support block allocation of IDs: each update to
the MySQL table is only done every N IDs (N being configurable) and in between those writes
only the in-memory structures within the primary vttablet serving the unsharded keyspace 
where the backing table lives are updated, making the QPS only limited by the RPC latency
between the vtgates and the the serving vttablet for the sequence table.

So the sequence table is an unsharded single row table that Vitess can use to generate monotonically increasing ids.
The VSchema then allows you to associate a column in your table with the sequence. Once they are associated, an `insert`
on that table will transparently fetch an ID from the sequence, fill in the value, and route the row to the appropriate shard.

### Creating a Sequence

To create a sequence, a backing table must first be created. The table structure must have
the following columns and SQL comment in order to provide sequences (in the examples here the sequence is for a user table):

``` sql
create table user_seq(id bigint, next_id bigint, cache bigint, primary key(id)) comment 'vitess_sequence';
```

<p> 
{{< info >}}
Note: the vttablet in-memory structure uses `int64` types so `bigint unsigned` types are not supported for these columns in the backing table
{{< /info >}}
</p> 

Then the sequence has to be defined in the VSchema for the unsharded keyspace where the backing table lives:

``` json
{
  "sharded": false,
  "tables": {
    "user_seq": {
      "type": "sequence"
    },
    ...
  }
}
```

<p>
Now any table that will be using the new sequence can reference it in its VSchema as shown here:
</p>

``` json
{
  ...
  "tables" : {
    "user": {
      "column_vindexes": [
           ...
      ],
      "auto_increment": {
        "column": "user_id",
        "sequence": "user_seq"
      }
    },
```

## Initializing a Sequence
The sequence backing table needs to be pre-populated with a single row where:

* `id` must always be 0.
* `next_id` should be set to the next (starting) value of the sequence.
* `cache` is the number of values to be reserved and cached in each block allocation of IDs served by the primary vttablet of the
unsharded keyspace where the sequence backing table lives. This value should be set to a fairly large number like 1000 for improved write
latency and throughput (the tradeoff being that this chunk of reserved IDs could be lost if e.g. the tablet crashes, resulting in a
potential ID gap up to that size).

For example:

``` sql
insert into user_seq(id, next_id, cache) values(0, 1, 1000);
```

### Accessing a Sequence directly

If a sequence is used to fill in an ID column for a table, nothing further needs to
be done. Just sending no value for the column will make vtgate insert the next
sequence value in its place.

It is also possible, however, to access the sequence directly with the following SQL constructs:

``` sql
/* Returns the next value for the sequence */
select next value from user_seq;

/* Returns the next value for the sequence, and also reserve 4 values after that. */
select next 5 values from user_seq;
```

### Sequence limitations

Vitess sequences do not behave like a MySQL `auto_increment` column in all
ways.  One significant example is if you mix cases where you provide values
for the auto-incrementing column, and cases where you do not.  In a case
like this, a MySQL `auto_increment` will keep track of the highest value you
have used, and thus what the "next" value for the column would be.  Vitess
sequences do not do this.  Here is an example:

MySQL mixed insert case (`c1` is the auto-incrementing column):
``` sql
mysql> create table t1 (c1 bigint not null auto_increment, c2 bigint default null, primary key (c1)) engine=innodb;
Query OK, 0 rows affected (0.03 sec)

mysql> insert into t1 (c1,c2) values (1,1),(2,2),(3,3);
Query OK, 3 rows affected (0.01 sec)
Records: 3  Duplicates: 0  Warnings: 0

mysql> insert into t1 (c2) values (4);
Query OK, 1 row affected (0.01 sec)

mysql> select * from t1;
+----+------+
| c1 | c2   |
+----+------+
|  1 |    1 |
|  2 |    2 |
|  3 |    3 |
|  4 |    4 |
+----+------+
4 rows in set (0.00 sec)
```


Vitess sequence mixed insert case (`c1` is the sequence column):
``` sql
mysql> insert into t1 (c1,c2) values (1,1),(2,2),(3,3);
Query OK, 3 rows affected (0.04 sec)

mysql> select * from t1;
+----+------+
| c1 | c2   |
+----+------+
|  1 |    1 |
|  2 |    2 |
|  3 |    3 |
+----+------+
3 rows in set (0.01 sec)

mysql> insert into t1 (c2) values (4);
ERROR 1062 (23000): transaction rolled back to reverse changes of partial DML execution: target: sharded.-80.primary: vttablet: Duplicate entry '1' for key 't1.PRIMARY' (errno 1062) (sqlstate 23000) (CallerID: user): Sql: "insert into t1(c2, c1) values (:_c2_0, :_c1_0)", BindVars: {__seq0: "type:INT64 value:\"1\""_c1_0: "type:INT64 value:\"1\""_c2_0: "type:INT64 value:\"4\""vtg1: "type:INT64 value:\"4\""}
mysql> select * from t1;
+----+------+
| c1 | c2   |
+----+------+
|  1 |    1 |
|  2 |    2 |
|  3 |    3 |
+----+------+
3 rows in set (0.01 sec)
```

It is arguably bad practice to mix use-cases like this. If you avoid mixing use-cases you will not run into this issue.
