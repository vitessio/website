---
title: Reserved Connections
description:
weight: 1
---

## Feature Description

Vitess uses connection pooling to minimize the memory usage of the underlying MySQL servers. 
This means that different users connecting to a vtgate can be sharing a connection session to MySQL.
To make this as invisible as possible to users, Vitess works hard removing all query constructs that would normally need to change the state in the MySQL connection.
A simple example are user defined variables.
When a user sets or evaluates an UDV, the vtgate will rewrite the query so that it doesn't actually do anything with user variables, and keep the state on the Vitess layer.

For some things a user might want to do, this is not enough, and in those cases, Vitess will use something called reserved connections.
This means a dedicated connection from the vttablet to the MySQL server.
Reserved connections are used when changing system variables, using temporary tables, or when a user uses the locking functions to acquire advisory locks.

### System variables and reserved connections

If a user does change a system variable, the user connection will be marked as needing reserved connections, and for all sub-sequent calls to Vitess, connection pooling is turned off for this particular session.
This only applies to some system settings. See more details [here.](../set-stmt/)
Any queries to a tablet from this session will create a reserved connection on that tablet that is reserved for the user and no one else.

Connection pooling is an important part of what makes Vitess fast, so using constructs that turn it off should only be done in rare circumstances.
If you are using an application or library that is issues these kind of `SET` statements, the best way to avoid reserved connections is to make sure the global MySQL settings match the one the application is trying to set. When Vitess discovers that you are changing a system setting to the global value, Vitess just ignores those `SET`s.

Once a session has been marked for reserved connections, it will stay as such until the user disconnects.

### Temporary tables and reserved connections

Temporary tables exist only in the context of a particular MySQL connection.
If a user uses temporary tables, Vitess will mark the session as needing a reserved connection. It will continue to require a reserved connection until the user disconnects - removing the temp table is not enough. More info can be found [here.](/docs/reference/compatibility/mysql-compatibility/#temporary-tables)

### GET_LOCK() and reserved connections

The MySQL locking functions allow users to work with user level locks. Since the locks are tied to the connection, and the lock must be released in the same connection as it was acquired, use of these functions will force a connection to become a reserved connection. This connection is also kept alive so it does not time out due to inactivity. More information can be found [here.](../locking-functions/).

### Shutting down reserved connections

Whenever a connection gets transformed into a reserved connection, a fresh, clean connections is returned to the connection pool to replace it.
Once the vtgate session that initiated the reserved connections disconnects, all reserved connections between the vttablets and MySQL are terminated.