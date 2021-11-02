---
title: Reserved Connections
description:
weight: 1
---

## Feature Description

Vitess uses connection pooling to minimize the memory usage of the underlying
MySQL servers. This means that different users connecting to a `vtgate` can be
sharing a connection session to MySQL. To make this as invisible as possible
to users, Vitess works hard removing all query constructs that would normally
need to change the state in the MySQL connection. A simple example are user
defined ariables. When a user sets or evaluates an user defined variable,
the `vtgate` will rewrite the query so that it does not actually do anything
with user variables, and keep the state in the Vitess layer.

For some things a user might want to do, this is not enough, and in those
cases, Vitess will use something called reserved connections. This means a
dedicated connection is maintained for the `vtgate` session from the `vttablet`
to the MySQL server. Reserved connections are used when changing system
variables, using temporary tables, or when a user uses MySQL locking functions
to acquire advisory locks.  In general, it is desirable to use reserved
connections sparingly, because they reduce the effectiveness of the `vttablet`
connection pooling, and may reduce (or even eliminate) the advantages of
using connection pooling between `vttablet` and MySQL. As such, it is critical
to be aware of the `SET` statements that your application's MySQL connector
and/or ORM sends to MySQL/`vtgate`, and if those settings will result in
reserved connections being employed for some/all of the application's sessions.

### System variables and reserved connections

If a user does change a system variable (and reserved connections are enabled,
see below), the user connection will be marked as needing reserved connections,
and for all subsequent calls to Vitess, connection pooling is turned off for
this particular session. This only applies to certain system settings. For more
details see [here](/docs/design-docs/query-serving/set-stmt/). Any queries to a
tablet from this session will create a reserved connection on that tablet that
is reserved for this session and no one else.

Connection pooling is an important part of what makes Vitess performant, so
using constructs that turn it off should only be done in rare circumstances.
If you are using an application or library that is issues these kind of `SET`
statements, the best way to avoid reserved connections is to make sure the
global MySQL settings match the one the application is trying to set (e.g.
`sql_mode`, or `wait_timeout`). When Vitess discovers that you are changing
a system setting to the global value, Vitess just ignores those `SET`s.

Once a session has been marked as reserved, it remain reserved until the user
disconnects from `vtgate`.

### Enabling reserved connections

Use of reserved connections are controlled by the `vtgate` flag
`-enable_system_settings`.  This flag has traditionally defaulted to **false**
(or off) in release versions (i.e. `x.0` and `x.0.y`) of Vitess, and to
**true** (or on) in development versions. From Vitess 12.0 onwards, it
defaults to **true** in all release and development versions
(see https://github.com/vitessio/vitess/issues/9125).  It is therefore
advisable that you specify this flag explicitly, so you are sure whether
it is enabled or not, independent of which Vitess release/build/version
you are running.

If you have reserved connections disabled, you get the "old" Vitess behavior,
where most setting most system settings (e.g. `sql_mode`) are just silently
ignored by Vitess. In situations where you know your backend MySQL defaults
are acceptable, this may be the correct tradeoff to ensure best possible
performance of the `vttablet` <-> MySQL connection pools. As noted above,
this comes down to a trade-off between compatibility and
performance/scalability. Also review [this](#number-of-vttablet---mysql-connections)
when deciding on whether to enable reserved connections.

### Temporary tables and reserved connections

Temporary tables exist only in the context of a particular MySQL connection.
If a user a temporary table, Vitess will mark the session as needing a
reserved connection. It will continue to use the reserved connection
until the user disconnects - removing the temp table is not enough.
More info can be found [here](/docs/reference/compatibility/mysql-compatibility/#temporary-tables).

### GET_LOCK() and reserved connections

The MySQL locking functions allow users to work with user level locks. Since
the locks are tied to the connection, and the lock must be released in the
same connection as it was acquired, use of these functions will force a
connection to become a reserved connection. This connection is also kept alive
so it does not time out due to inactivity.  More information can be found
[here](/docs/design-docs/query-serving/locking-functions/).

### Shutting down reserved connections

Whenever a connection gets transformed into a reserved connection, a fresh
connection is created in the connection pool to replace it. Once the `vtgate`
session that initiated the reserved connections disconnects, all reserved
connections created for this session between the `vttablet`s and MySQL
are terminated.

### Number of `vttablet` <-> MySQL connections

As a result of how reserved connections work, it is quite possible for there
to be signficantly more `vttablet` <-> MySQL connections than the limit you
set by sizing the `vttablet` connection pools. This is because the connection
pools are still being maintained, resulting in a set maximum number of
connections, plus then the number of reserved connections, which is at
least partially based on the number of connected vtgate clients that are using
reserved connections. As such, it might be challenging to size you MySQL
`max_connections` configuration setting appropriately to deal with the
potentially (much) larger number of connections.

We recommend you review the value of this setting carefully, and keep this
in might when you decide whether to enable reserved connections.
