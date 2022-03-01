---
title: Reserved Connections
description:
weight: 1
---

## Feature Description

Vitess uses connection pooling to minimize memory usage and otherwise
optimize the performance of the underlying MySQL servers. Even with 
tens of thousands of client database connections. This means that
different users connecting to a `vtgate` can effectively share a
database session to MySQL. To make this process as transparent as possible
to users, Vitess removes all query constructs that would normally
need to change the state in the MySQL connection. For example, when a user 
sets or evaluates a user defined variable, the `vtgate` will rewrite the query 
so that it does not actually do anything with user variables. Instead it keeps 
the state in the Vitess layer.

In other cases, this approach is not enough, and Vitess can use 
**reserved connections**. This means a dedicated connection is maintained for 
the `vtgate` session from the relevant `vttablet` to the MySQL server. Reserved 
connections are used when changing system variables, using temporary tables, 
or when using MySQL locking functions to acquire advisory locks. In general, it 
is better to use reserved connections sparingly, because they reduce the 
effectiveness of the `vttablet` connection pooling. This may also reduce, or even 
eliminate, the advantages of using connection pooling between `vttablet` and 
MySQL. As such, take note of the `SET` statements that your application's 
MySQL connector and/or ORM sends to MySQL/`vtgate`. Or if those settings will
result in reserved connections being employed for some/all of the application's
sessions.

### System variables and reserved connections

If a user changes a system variable and reserved connections are enabled, 
the user connection will be marked as needing reserved connections.
For all subsequent calls to Vitess, connection pooling is turned off for
a particular session. This only applies to certain system settings. For more
details see [here](../../../reference/query-serving/set-stmt/). Any queries to a
tablet from this session will create a reserved connection on that tablet. This 
means a connection is reserved only for that session.

Connection pooling is an important part of what makes Vitess performant, so
using constructs that turn it off should only be done in rare circumstances.

If you are using an application or library that issues these kind of `SET`
statements, the best way to avoid reserved connections is to make sure the
global MySQL settings match the ones the application is trying to set (e.g.
`sql_mode`, or `wait_timeout`). When Vitess discovers that you are changing
a system setting to the global value, Vitess just ignores those `SET`s.

Once a session has been marked as reserved, it remain reserved until the user
disconnects from `vtgate`.

### Enabling reserved connections

Use of reserved connections are controlled by the `vtgate` flag
`-enable_system_settings`.  This flag has traditionally defaulted to **false**
(or off) in release versions (i.e. `x.0` and `x.0.y`) of Vitess, and to
**true** (or on) in development versions. 

From Vitess 12.0 onwards, it defaults to **true** in all release and 
development versions. You can read more [here](https://github.com/vitessio/vitess/issues/9125). 
Thus you should specify this flag explicitly, so you are sure whether
it is enabled or not, independent of which Vitess release/build/version
you are running.

If you have reserved connections disabled, you will get the "old" Vitess behavior:
where most setting most system settings (e.g. `sql_mode`) are just silently
ignored by Vitess. In situations where you know your backend MySQL defaults
are acceptable, this may be the correct tradeoff to ensure the best possible
performance of the `vttablet` <-> MySQL connection pools. As noted above,
this comes down to a trade-off between compatibility and
performance/scalability. You should also review [this section](#number-of-vttablet---mysql-connections)
when deciding on whether or not to enable reserved connections.

### Avoiding the use of reserved connections

In MySQL80 a new query hint (`SET_VAR`) allows setting the session value of certain system variables during
the execution of a statement. More information about this MySQL feature on the
[MySQL documentation](https://dev.mysql.com/doc/refman/8.0/en/optimizer-hints.html#optimizer-hints-set-var).
Vitess leverages this query hint to reduce the number of reserved connections. When setting a system variable,
instead of creating a reserved connection, the variable and its new value will be sent to MySQL using the
`SET_VAR` query hint. This applies only if the system variable is supported by the `SET_VAR` hint
(list of supported variables [here](https://dev.mysql.com/doc/refman/8.0/en/server-system-variables.html)).


For example, executing: `set @@sql_mode = 'NO_ZERO_DATE'` will not create a reserved connection for future queries.
If we execute a `select` statement like: `select foo from bar`, VTGate will rewrite the query as 
`select /*+ SET_VAR(sql_mode = 'NO_ZERO_DATE') foo from bar */`.

This feature can be disabled using the VTGate flag `-enable_set_var` (by default set to true).

### Temporary tables and reserved connections

Temporary tables exist only in the context of a particular MySQL connection.
If using a temporary table, Vitess will mark the session as needing a
reserved connection. It will continue to use the reserved connection
until the user disconnects. Note that removing the temp table is not enough to reset this.
More info can be found [here](../../compatibility/mysql-compatibility/#temporary-tables).

### GET_LOCK() and reserved connections

The MySQL locking functions allow users to work with user level locks. Since
the locks are tied to the connection, and the lock must be released in the
same connection as it was acquired, use of these functions will force a
connection to become a reserved connection. This connection is also kept alive
so it does not time out due to inactivity.  More information can be found
[here](../../../reference/query-serving/locking-functions/).

### Shutting down reserved connections

Whenever a connection gets transformed into a reserved connection, a fresh
connection is created in the connection pool to replace it. Once the `vtgate`
session that initiated the reserved connections disconnects, all reserved
connections created for this session between the `vttablet`s and MySQL
are terminated. You may want to configure your application or application 
connector to disconnect idle sessions that are likely to use
reserved connections promptly. In order to release resources that cannot
otherwise be reused.

### Number of vttablet <-> MySQL connections

As a result of how reserved connections work, it is possible for there
to be significantly more `vttablet` <-> MySQL connections than the limit you
set by sizing the `vttablet` connection pools. This is because the connection
pools are still being maintained. Which results in a set maximum number of
connections, plus the number of reserved connections. This is at
least partially based on the number of connected vtgate clients that are using
reserved connections. As such, it may be challenging to size your MySQL
`max_connections` configuration setting appropriately in order to deal with the
potentially (much) larger number of connections.

We recommend you review the value of this setting carefully, and keep this
in mind when you decide whether to enable or disable reserved connections.
