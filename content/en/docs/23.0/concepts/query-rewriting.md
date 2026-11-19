---
title: Query Rewriting
---

Vitess works hard to create an illusion of the user having a single connection to a single database. 
In reality, a single query might interact with multiple databases and may use multiple connections to the same database.
Here we'll go over what Vitess does and how it might impact you.

### Query splitting

A complicated query with a cross shard join might need to first fetch information from a tablet keeping vindex lookup tables. Then use this information to query two different shards for more data and subsequently join the incoming results into a single result that the user receives.
The queries that MySQL gets are often just pieces of the original query, and the final result will get assembled at the vtgate level.

### Connection Pooling

When a tablet talks with a MySQL to execute a query on behalf of a user, it does not use a dedicated connection per user, and instead will share the underlying connection between users. 
This means that it's not safe to store any state in the session as you can't be sure it will continue executing queries on the same connection, and you can't be sure if this connection will be used by other users later on.

### User-Defined Variables

User defined variables are kept in the session state when working with MySQL.
You can assign values to them using SET:

```sql
SET @my_user_variable = 'foobar'
```

And later there can be queries using for example SELECT:

```sql
> SELECT @my_user_variable;
+-------------------+
| @my_user_variable |
+-------------------+
| foobar            |
+-------------------+
```

If you execute these queries against a VTGate, the first `SET` query is not sent to MySQL.
Instead, it is evaluated in the VTGate, and VTGate will keep this state for you.
The second query is also not sent down. Trivial queries such as this one are actually fully executed on VTGate.

If we try a more complicated query that requires data from MySQL, VTGate will rewrite the query before sending it down.
If we were to write something like:

```sql
WHERE col = @my_user_variable
```

What MySQL will see is:

```sql
WHERE col = 'foobar'
```

This way, no session state is needed to evaluate the query in MySQL.

### Server System Variables

A user might also want to change one of the many different system variables that MySQL exposes.
Since VTGate shares MySQL connections between sessions, it handles each system variable in one of these ways:

  * *Vitess-aware*. These are settings that change Vitess' behaviour, such as `workload` or `transaction_mode`. VTGate keeps them in the session and doesn't send them down to MySQL.
  * *Connection setting*. These are settings such as `sql_mode` or `time_zone` that change how MySQL runs queries. If the new value differs from the one MySQL already uses, VTGate applies it to every query of the session, either with a `SET_VAR` query hint or by having VTTablet run the queries on pooled connections that have the setting applied. Connection pooling works best if the global variable in MySQL is set to the same value the application sets it to. You can read more about it [here](../../reference/query-serving/reserved-conn/).
  * *Ignored*. For some settings, VTGate accepts the `SET` statement but silently ignores it.
  * *Read-only* and *Not supported*. For these settings, attempting to change them will always result in an error.

In addition to this, Vitess makes sure that @@version includes both the emulated MySQL version and the Vitess version, such as: `8.4.6-Vitess`. This value can be changed by using the vtgate flag `--mysql-server-version`.

See [System Variables](../../reference/compatibility/system-variables/) for how VTGate handles each system variable, and for the values of the Vitess-aware ones.

### Special functions

There are a few special functions that Vitess handles without delegating to MySQL.

  * `DATABASE()` - The keyspace name and the underlying database names do not have to be equal. Vitess will rewrite these calls to use the literal string for the keyspace name. (This also applies to the synonym `SCHEMA()`) 
  * `ROW_COUNT()` and `FOUND_ROWS()` - These functions returns how many rows the last query affected/returned. Since this might have been executed on a different connection, these get rewritten to use the literal value of the number of returned rows.
  * `LAST_INSERT_ID()` - Much like `FOUND_ROWS()`, we can't trust a pooled connection for these function calls, so they get rewritten before hitting MySQL.

**Related Vitess Documentation**

* [VTGate](../vtgate)
