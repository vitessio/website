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
so that it does not actually do anything with user variables. Instead, it keeps 
the state in the Vitess layer.

In other cases, this approach is not enough, and Vitess can use **reserved connections**.
A dedicated connection is maintained for the `vtgate` session 
from the relevant `vttablet` to its underlying MySQL server. Reserved connections are used when using 
temporary tables, or when using MySQL locking functions to acquire advisory locks. 
In general, it is better to use reserved connections sparingly, because they reduce the 
effectiveness of the `vttablet` connection pooling. This may also reduce, or even 
eliminate, the advantages of using connection pooling between `vttablet` and 
MySQL.

### Reserved connections

`SET` statements used to cause use of `reserved connections`. This is no longer the case with the new connection pool implementation used by vttablet.
The connection pool now tracks connections with modified settings instead of pinning connections to specific client sessions. 
Any client requesting connection with or without settings are provided the connection accordingly.
With this enhancement, we reduce the likelihood of MySQL running out of connections due to reserved connections, 
because the scenarios where we still need reserved connections have drastically reduced.

There are still cases like [temporary tables](#temporary-tables-and-reserved-connections) and [advisory locks](#get_lock-and-reserved-connections) where reserved connections will continue to be used.

### Temporary tables and reserved connections

Temporary tables exist only in the context of a particular MySQL connection.
If using a temporary table, Vitess will mark the session as needing a
reserved connection. It will continue to use the reserved connection
until the user disconnects. Note that removing the temporary table is not enough to reset the connection.
More info can be found [here](../../compatibility/mysql-compatibility/#temporary-tables).

### GET_LOCK() and reserved connections

The MySQL locking functions allow users to work with user level locks. Since
the locks are tied to the connection, and the lock must be released in the
same connection as it was acquired, use of these functions will force a
connection to become a reserved connection. This connection is also kept alive
so it does not time out due to inactivity.  More information can be found
[here](../../../../design-docs/query-serving/locking-functions/).

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
