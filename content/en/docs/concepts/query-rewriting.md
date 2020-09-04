---
title: Query Rewriting
---

Vitess works hard to create an illusion of the user having a single connection to a single database. 
In reality, a single query might have to interact with multiple databases, sometimes using multiple connection to the same database. 
Here we'll go over what Vitess does and how it might impact you.

### Query splitting

A complicated query with a cross shard join might need to first fetch information from a tablet keeping vindex lookup tables, use this information to query two different shards for more data, and then join the incoming results into a single result that the user receives. 
The queries that MySQL gets are often just pieces of the original query, and the final result will get assembled at the vtgate level.

### Connection Pooling

When a tablet talks with a MySQL to execute a query on behalf of a user, it does not use a dedicated connection per user, and instead will share the underlying connection between users. 
This means that it's not safe to store any state in the session - we can't be sure we'll continue executing queries on the same connection, and we can't be sure if this connection will be used by other users later on.

### User defined variables

One if the things that is kept in the session state when working with MySQL are the user defined variables. 
You can assign values to it using SET:

```
SET @my_user_variable = 'foobar'
```

And later they can be queries using for example SELECT:

```
> SELECT @my_user_variable;
+-------------------+
| @my_user_variable |
+-------------------+
| foobar            |
+-------------------+
```

If you execute these queries against a vtgate, that first `SET` query is not sent to MySQL.
Instead, it is evaluated in the VTGATE, and it will keep this state for you.
The second query is also not sent down - trivial queries such as this one is actually fully executed on VTGATE.

If we try a more complicated query that requires data from MySQL, vtgate will rewrite the query before sending it down.
If we were to write something like :

```WHERE col = @my_user_variable```, 

what MySQL will see is 

```WHERE col = 'foobar'```. 

This way, the connection to MySQL doesn't need to hold any state for us.


**Related Vitess Documentation**

* [VTGate](../vtgate)
