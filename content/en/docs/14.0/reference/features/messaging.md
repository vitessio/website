---
title: Vitess Messaging
---

Vitess messaging gives the application an easy way to schedule and manage work
that needs to be performed asynchronously. Under the covers, messages are
stored in a traditional MySQL table and therefore enjoy the following
properties:

* **Scalable**: Because of Vitess's sharding abilities, messages can scale to
  very large QPS or sizes.
* **Guaranteed delivery**: A message will be indefinitely retried until a
  successful ack is received.
* **Non-blocking**: If the sending is backlogged, new messages continue to be
  accepted for eventual delivery.
* **Adaptive**: Messages that fail delivery are backed off exponentially with
  jitter to prevent thundering herds.
* **Analytics**: Acknowledged messages are retained for a period of time — dictated
  by the `time_acked` value for the row and the `vt_purge_after` (seconds) value
  provided for the table — and can be used for analytics.
* **Transactional**: Messages can be created or acked as part of an existing
  transaction. The action will complete only if the commit succeeds.

The properties of a message are chosen by the application. However, every
message needs a uniquely identifiable key. If the messages are stored in a
sharded table, the key must also be the primary vindex of the table.

Although messages will generally be delivered in the order they're created,
this is not an explicit guarantee of the system. The focus is more on keeping
track of the work that needs to be done and ensuring that it was performed.
Messages are good for:

* Handing off work to another system.
* Recording potentially time-consuming work that needs to be done
  asynchronously.
* Accumulating work that could be done during off-peak hours.

Messages are not a good fit for the following use cases:

* Broadcasting each event to multiple subscribers.
* Ordered delivery is required.
* Real-time delivery properties are required.

## Creating a message table

The current implementation requires a base fixed schema with properties defined
using Vitess specific table `COMMENT` directives. The message table format is as
follows:

```sql
create table my_message(
  # required columns
  id bigint NOT NULL COMMENT 'often an event id, can also be auto-increment or a sequence',
  priority tinyint NOT NULL DEFAULT '50' COMMENT 'lower number priorities process first',
  epoch bigint NOT NULL DEFAULT '0' COMMENT 'Vitess increments this each time it sends the message, and is used for incremental backoff doubling',
  time_next bigint DEFAULT 0 COMMENT 'the earliest time the message will be sent in epoch nanoseconds. Must be null if time_acked is set',
  time_acked bigint DEFAULT NULL COMMENT 'the time the message was acked in epoch nanoseconds. Must be null if time_next is set',

  # add as many custom fields here as required
  # optional - these are suggestions
  tenant_id bigint COMMENT 'offers a nice way to segment your messages',
  message json,

  # required indexes
  primary key(id),
  index poller_idx(time_acked, priority, time_next desc)

  # add any secondary indexes or foreign keys - no restrictions
) comment 'vitess_message,vt_min_backoff=30,vt_max_backoff=3600,vt_ack_wait=30,vt_purge_after=86400,vt_batch_size=10,vt_cache_size=10000,vt_poller_interval=30'
```

The application-related columns are as follows:

* `id`: can be any type. Must be unique (for sharded message tables, this will typically be your primary vindex column).
* `message`: can be any type.
* `priority`: messages with a lower priority will be processed first.

The noted indexes are recommended for optimum performance. However, some
variation can be allowed to achieve different performance trade-offs.

The comment section specifies additional configuration parameters. The fields
are as follows:

* `vitess_message`: Indicates that this is a message table.
* `vt_min_backoff=30`: Set lower bound, in seconds, on exponential backoff for
  message retries. If not set, defaults to `vt_ack_wait` _(optional)_
* `vt_max_backoff=3600`: Set upper bound, in seconds, on exponential backoff for
  message retries. The default value is infinite backoff _(optional)_
* `vt_ack_wait=30`: Wait for 30 seconds for the *first* message send to be acked.
  If one is not received within this time frame, the message will be resent.
* `vt_purge_after=86400`: Purge acked messages that are older than 86400
  seconds (1 day).
* `vt_batch_size=10`: Send up to 10 messages per gRPC packet.
* `vt_cache_size=10000`: Store up to 10,000 messages in the cache. If the demand
  is higher, the rest of the items will have to wait for the next poller cycle.
* `vt_poller_interval=30`: Poll every 30 seconds for messages that should be
  [re]sent.

If any of the above fields not marked as optional are missing, Vitess will fail to load the table. No
operation will be allowed on a table that has failed to load.

## Enqueuing messages

The application can enqueue messages using a standard `INSERT` statement, for example:

```sql
insert into my_message(id, message) values(1, '{"message": "hello world"}')
```

These inserts can be part of a regular transaction. Multiple messages can be
inserted into different tables. Avoid accumulating too many big messages within a
transaction as it consumes memory on the VTTablet side. At the time of commit,
memory permitting, all messages are instantly enqueued to be sent.

Messages can also be created to be sent in the future:

 ```sql
 insert into my_message(id, message, time_next) values(1, '{"message": "hello world"}', :future_time)
 ```

 `future_time` must be a unix timestamp expressed in nanoseconds.

## Receiving messages

Processes can subscribe to receive messages by sending a `MessageStream`
gRPC request to a `VTGate` or using the `stream * from <table>` SQL statement
(if using the interactive mysql command-line client you must also pass the
`-q`/`--quick` option). If there are multiple subscribers, the messages will be
delivered in a round-robin fashion. Note that *this is not a broadcast*; each
message will be sent to at most one subscriber.

The format for messages is the same as a standard Vitess `Result` received from
a `VTGate`. This means that standard database tools that understand query results
can also be message receivers.

### Subsetting

It's possible that you may want to subscribe to specific shards or groups of
shards while requesting messages. This is useful for partitioning or load
balancing. The `MessageStream` gRPC API call allows you to specify these
constraints. The request parameters are as follows:

* `Name`: Name of the message table.
* `Keyspace`: Keyspace where the message table is present.
* `Shard`: For unsharded keyspaces, this is usually "0". However, an empty
  shard will also work. For sharded keyspaces, a specific shard name can be
  specified.
* `KeyRange`: If the keyspace is sharded, streaming will be performed only from
  the shards that match the range. This must be an exact match.

## Acknowledging messages

A received and processed (you've completed some meaningful work based on the
message contents received) message can be acknowledged using the `MessageAck`
gRPC API call. This call accepts the following parameters:

* `Name`: Name of the message table.
* `Keyspace`: Keyspace where the message table is present. This field can be
  empty if the table name is unique across all keyspaces.
* `Ids`: The list of ids that need to be acked.

Once a message is successfully acked, it will never be resent.

## Exponential backoff

For a message that was successfully sent we will wait for the specified `vt_ack_wait`
time. If no ack is received by then, it will be resent. The next attempt will be 2x
the previous wait and this delay is doubled for every subsequent attempt — bound by
`vt_min_backoff` and `vt_max_backoff` — with some added jitter (up to 33%) to avoid
thundering herds.

## Purging

Messages that have been successfully acked will be deleted after their age
exceeds the time period specified by `vt_purge_after`.

## Advanced usage

The `MessageAck` functionality is currently a gRPC API call and cannot be used
from the SQL interface. However, you can manually ack messages using a regular
DML query like this:

```sql
update my_message set time_acked = :time_acked, time_next = null where id in ::ids and time_acked is null
```

You can also manually change the schedule of existing messages with a statement like
this:

```sql
update my_message set priority = :priority, time_next = :time_next, epoch = :epoch where id in ::ids and time_acked is null
```

This comes in handy if a bunch of messages had chronic failures and got
postponed to the distant future. If the root cause of the problem was fixed,
the application could reschedule them to be delivered as soon as possible. You can
also optionally change the priority and or epoch. Lower priority and epoch values
both increase the relative priority of the message and the back-off is less
aggressive.

You can also view messages using regular `SELECT` queries against the message table.

## Known limitations

Here is a short list of possible limitations/improvements:

* Proactive scheduling: Upcoming messages can be proactively scheduled for
  timely delivery instead of waiting for the next polling cycle.
* Changed properties: Although the engine detects new message tables, it does
  not refresh the properties (such as `vt_ack_wait`) of an existing table.
* No explicit rate limiting.
* Usage of MySQL partitioning for more efficient purging.


