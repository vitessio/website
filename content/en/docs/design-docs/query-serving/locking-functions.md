---
title: Locking functions
description:
weight: 1
---
# Locking Functions

Supporting the advisory locking functions in MySQL is important, given that they are used by common applications and frameworks.

## Functions covered

 * __GET_LOCK()__
 * __IS_FREE_LOCK()__
 * __IS_USED_LOCK()__
 * __RELEASE_ALL_LOCKS()__
 * __RELEASE_LOCK()__

## Restrictions

Vitess will initially only support locking functions with these limitations:

 * Can only be used in SELECT queries
 * The queries can either have only the table `dual`, or have no `FROM` clause.

 ## Functionality

Locking function evaluation will have a simple and consistent routing scheme, making sure all requests happen at the same target. This way, locks will be executed on the same `mysqld`.
The locking function evaluation always is routed to the first shard in the first keyspace known to the VTGate, sorted alphabetically.

Using any of the locking functions will force the session to use a reserved connection - a dedicated connection to `mysqld` for that session, so that `get_lock()`/`release_lock()` happen on the same connection, and so that `COM_QUIT` releases any lingering locks.

## Examples of valid queries

```
SELECT GET_LOCK('lock1',10);
SELECT RELEASE_LOCK('lock1');
SELECT GET_LOCK('lock1',10), GET_LOCK('lock2',10);
SELECT RELEASE_ALL_LOCKS()
SELECT GET_LOCK(@customVariable, 10);
```

## Examples of queries not supported in the first implementation

```
SELECT GET_LOCK(user_name,10) FROM users;
INSERT INTO T (id) VALUES (GET_LOCK('lock2',10));
DO GET_LOCK('lock1',10);
```
