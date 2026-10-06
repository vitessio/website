---
title: Reserved Connections
description:
weight: 20
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
Any client requesting a connection with or without settings is provided a connection that has the correct settings.
With this enhancement, we reduce the likelihood of MySQL running out of connections due to reserved connections, 
because the scenarios where we still need reserved connections have drastically reduced.

There are still cases like [temporary tables](#temporary-tables-and-reserved-connections) and [advisory locks](#get_lock-and-reserved-connections) where reserved connections will continue to be used.

### Temporary tables and reserved connections

Temporary tables exist only in the context of a particular MySQL connection.
If using a temporary table, Vitess will mark the session as needing a
reserved connection. It will continue to use the reserved connection
until the user disconnects. Note that removing the temporary table is not enough to reset the connection.
More info can be found [here](../../compatibility/mysql-compatibility/#temporary-tables).

**Keeping the connection alive for a live session.** Previously, a reserved connection holding temporary tables could be closed by the tablet's own idle timeout even while the `vtgate` session was still connected, dropping the session's temporary tables. Vitess now keeps such a connection alive with a low-frequency background keepalive, much like the connection behind an [advisory lock](#get_lock-and-reserved-connections), so a still-live session no longer loses its temporary tables to the tablet's internal idle timeout.

**MySQL parity.** The keepalive refreshes only the tablet's own reserved-connection timers; it sends nothing to `mysqld`. MySQL's `wait_timeout` therefore keeps counting only real session traffic, so an idle session still loses its connection — and its temporary tables — at `wait_timeout`, exactly as it would on a direct MySQL connection.

**Tuning the keepalive.** The [`--temp-table-heartbeat-time`](../../programs/vtgate/) VTGate flag (a duration, default `10s`) controls the keepalive interval for sessions on the MySQL protocol. Setting it to `0` disables the keepalive, in which case temp-table reserved connections are reclaimed at the tablet's transaction timeout, as they were before this feature. The interval must stay below the tablet's effective reserved-connection timeout (`--queryserver-config-transaction-timeout`, or `--queryserver-config-olap-transaction-timeout` for OLAP sessions) by at least one keepalive round-trip (against whichever of the two is smaller, since one interval covers both session types). As a rule of thumb, keep the interval under half that timeout. There is no hard minimum or maximum. Because `--temp-table-heartbeat-time` is set at `vtgate` startup, changing it means restarting `vtgate`, which disconnects that `vtgate`'s sessions and drops their temporary tables (see [Shutting down reserved connections](#shutting-down-reserved-connections)).

**gRPC-API sessions.** Sessions that use the gRPC API travel with each request and have no wire connection for `vtgate` to anchor a heartbeat to, so the tablet covers their temp-table reserved connections instead, through the [`--queryserver-config-temp-table-idle-timeout`](../../programs/vttablet/) VTTablet flag (a duration, default `-1`):

- `-1` (auto) mirrors the tablet's `mysqld` `@@global.wait_timeout`.
- `0` (disabled) means these reserved connections are reclaimed at the transaction timeout, the fallback that restores the behavior from before this feature.
- A value greater than `0` (explicit) sets an idle timeout, which should be kept at or above the transaction timeout and at or below `mysqld`'s `wait_timeout`.

{{< warning >}}
With the `-1` default, an abandoned gRPC temp-table session (for example, one left behind by a crashed client) now lingers for up to `wait_timeout` rather than the transaction timeout. By default that is 8h for `wait_timeout` (though you may have tuned it) versus 30s for the transaction timeout. These connections occupy the stateful pool capped by [`--queryserver-config-transaction-cap`](../../features/connection-pools/) (default 20), so a burst of such sessions can pin most of that pool for the full window. Size the cap and the flag together, or set the flag to `0`, to bound this.
{{< /warning >}}

**Resilience and upgrade order.** If `vtgate` stops sending keepalives (because it died, for instance), the tablet reclaims the affected connections at its normal timeout, so nothing leaks. Upgrade `vttablet`s before `vtgate`s: a tablet running a version from before this feature simply falls back to the old tablet-timeout behavior and never closes a reserved connection because of the keepalive.

**Observability.** The tablet exposes two metrics: `TempTableUnmanagedConnections` (a gauge counting temp-table connections that have no keepalive coverage) and `TempTableIdleTimeoutKills` (a counter of connections reclaimed when this idle timeout elapsed). A nonzero or growing `TempTableIdleTimeoutKills` means gRPC-API sessions are reaching the idle timeout and losing their temporary tables; if that is unexpected, raise `--queryserver-config-temp-table-idle-timeout` or investigate clients that abandon sessions. `TempTableUnmanagedConnections` shows how many temp-table connections currently rely on that tablet-side timeout rather than the vtgate keepalive.

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
