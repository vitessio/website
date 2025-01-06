---
title: VTGate Buffering
weight: 5
aliases: ['/docs/user-guides/buffering/','/docs/reference/programs/vtgate']
---

VTGate in Vitess supports the **buffering** of queries in certain situations.
The original intention of this feature was to **reduce**, not necessarily
eliminate, downtime during planned fail overs PlannedReparentShard (PRS). VTGate
has been extended to provide buffering in some additional fail over situations,
e.g. during resharding.

Note that buffering is not intended for, nor active during, unplanned failovers
or other unplanned issues with a `PRIMARY` tablet during normal operations.
There are some new heuristics built in the `keyspace_events` implementation
for scenarios where the `PRIMARY`is offline. However, you should not rely on
these at this time.

Buffering can be somewhat involved, and there are a number of tricky edge cases.
We will discuss these in the context of an application's experience, starting
with the simplest case: that of buffering during a PRS (PlannedReparentShard)
operation. Examples of various edge cases can be found in
[Buffering Scenarios](../../../user-guides/configuration-advanced/buffering-scenarios/).

{{< warning >}}
The buffering feature is not guaranteed to eliminate errors sent to the application, but
rather reduce them or make them less frequent. The application should still endeavor to
handle errors appropriately if/when they occur (e.g. unplanned outages, planned failovers,
VReplication migrations, etc.)
{{< /warning >}}

## VTGate flags to enable buffering

First, let us cover the flags that need to be set in VTGate to enable
buffering:

  * `--enable_buffer`:  Enables buffering.  **Not enabled by default**
  * `--enable_buffer_dry_run`:  Enable logging of if/when buffering would
  trigger, without actually buffering anything. Useful for testing.
  Default: `false`
  * `--buffer_implementation`:  Default: `keyspace_events`.  More consistent results
  have been seen with `keyspace_events`. However, if the legacy behavior is needed
  you may use `healthcheck`.
  * `--buffer_size`:  Default: `1000` This should be sized to the appropriate
  number of expected request during a buffering event. Typically, if each
  connection has one request then, each connection will consume one buffer slot
  of the `buffer_size` and be put in a "pause" state as it is buffered on the
  vtgate. The resource consideration for setting this flag are memory resources.
  * `--buffer_drain_concurrency`:  Default: `1`.  If the buffer is of any
  significant size, you probably want to increase this proportionally.
  * `--buffer_keyspace_shards`:  Can be used to limit buffering to only
  certain keyspaces. Should not be necessary in most cases, defaults to watching
  all keyspaces.
  * `--buffer_max_failover_duration`:  Default: `20s`.  If buffering is active
  longer than this set duration, stop buffering and return errors to the client.
  * `--buffer_window`: Default: `10s`.  The maximum time any individual request
  should be buffered for. Should probably be less than the value for
  `--buffer_max_failover_duration`. Adjust according to your application
  requirements. Be aware, if your MySQL client has  `write_timeout` or
  `read_timeout` settings those values should be greater than the
  `buffer_max_failover_duration`.
  * `--buffer_min_time_between_failovers`: Default `1m`. If consecutive
  fail overs for a shard happens within less than this duration, do **not**
  buffer again. The purpose of this setting is to avoid consecutive fail over
  events where vtgate may be buffering, but never purging the buffer.

## Types of queries that can be buffered

 * Only requests to tablets of type `PRIMARY` are buffered. In-flight requests
 to a `REPLICA` in the process of transitioning to `PRIMARY` because of a PRS
 should be unaffected, and do not require buffering.

## What happens during a PlannedReparentShard with Buffering

Fundamentally Vitess will:

 * Hold up and buffer any queries sent to the `PRIMARY` tablet for a shard.
 * Wait for replication on a primary candidate `REPLICA` to catch up to the
 current `PRIMARY`.
 * Perform the actions which demote the `PRIMARY` to a `REPLICA` and promote a
 primary candidate `REPLICA` to `PRIMARY`.
 * Drain the buffered queries to the new `PRIMARY` tablet.
 * Begin the countdown timer for `buffer_max_failover_duration`.

## What happens during a MoveTables or Reshard SwitchTraffic or ReverseTraffic with Buffering

Fundamentally Vitess will:

 * Hold up and buffer any queries sent to the tables (MoveTables) or shards (Reshard) for which traffic is being switched.
 * Perform the traffic switching work so that application traffic against the tables (MoveTables) or shards (Reshard) are transparently switched to the new keyspace (MoveTables) or shards (Reshard).
 * Drain the buffered queries to the new keyspace or shards — or if the switch failed then back to the original keyspace or shards.

## How does it work?

The following steps are considerably simplified, but to give a high level
overview of how buffering works:

  * All buffering is done in `vtgate`
  * When a shard begins a fail over or resharding event, and a query is sent
  from `vtgate` to `vttablet`, `vttablet` will return a certain type of error
  to `vtgate` (`vtrpcpb.Code_CLUSTER_EVENT`).
  * This error indicates to `vtgate` that it is appropriate to buffer this
  request.
  * Separately the various timers associated with the flags above are being
  maintained to timeout and return errors to the application when appropriate,
  e.g. if an individual request was buffered for too long; or if buffering
  start "too long" ago.
  * When the failover is complete, and the tablet starts accepting queries
  again, we start draining the buffered queries, with a concurrency as
  indicated by the `buffer_drain_concurrency` value.
  * When the buffer is drained, the buffering is complete.  We maintain a
  timer based on `buffer_min_time_between_failovers` to make sure we
  do not buffer again if another fail over starts within that period.


## What the application sees

When buffering executes as expected the application will see a pause in their
query processing. Each query will consume a slot from the configured
`buffer_size` and will be paused for the duration of `buffer_window` before
errors are returned. Once the failover event completes, the buffer will begin to
drain at a concurrency set by the `buffer_drain_concurrency` value. Next a
countdown timer will start set by `buffer_min_time_between_failovers`. During
this period any future buffers will be disabled. Once the
`buffer_min_time_between_failovers` timer expires, buffering will be enabled
once again.

## Potential Errors

Buffering was implemented to minimize downtime, but there is still potential for
errors to occur, and your application should be configured to handle them
appropriately. Below are a few errors which may occur:

### Lost connection

```
Error Number: 2013
Error Message: Lost connection to MySQL server during query (timed out)
```

Due to the nature of buffering and pausing your queries the MySQL client will see
delays in their query request. If your client has a `read_timeout` or
`write_timeout` set, the value should be greater than the `buffer_window` value set
in vtgate.

### Primary not serving

```
Error Number: 1105
Error Message: target: ${KEYSPACE}.0.primary: primary is not serving, there is a reparent operation in progress
```

This is the most common error you will see in regards to buffering. You may get
this result in the application for a variety of reasons:

* `enable_buffer` is not configured; by default buffers are disabled.
* `enable_buffer_dry_run` is configured to be true; no buffering actions are
taken when this setting is enabled.
* `buffer_keyspace_shards` is not configured for the keyspace on which the
PRS event is being executed.
* `buffer_size` is set to be lower than the number of incoming queries; any
incoming request over the `buffer_size` will see this error.
* A new buffering event occurs before the `buffer_min_time_between_fail overs`
has expired.
* `buffer_max_failover_duration` has been exceeded; buffering is discontinued
and this error is returned.

## Next Steps

You may want to review the scenarios in
[Buffering Scenarios](../../../user-guides/configuration-advanced/buffering-scenarios/).
