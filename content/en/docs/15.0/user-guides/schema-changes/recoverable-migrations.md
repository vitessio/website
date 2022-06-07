---
title: Recoverable, failover agnostic migrations
weight: 13
aliases: ['/docs/user-guides/schema-changes/recoverable-migrations/']
---

Vitess's [managed schema changes](../managed-online-schema-changes/) offer _failover agnostic_ migrations in `vitess` strategy (VReplication based).

Normally, schema migrations are coupled with the original MySQL server they operate on. A `gh-ost` or a `pt-online-schema-change`, as well as plain direct migrations, may only complete on the same server where they started. Any form of failover, whether planned or unplanned, either breaks the migration or makes it obsolete.

`vitess` strategy migrations are agnostic to server promotion. A migration can begin on one `primary` tablet, and complete on another tablet which was promoted as `primary` throughout the migration. In large part this is a direct result of the nature of VReplication. 

`vitess` migrations will auto-survive:

- A planned failover (via [PlannedReparentShard](../../configuration-advanced/reparenting/#plannedreparentshard-planned-reparenting))
- An emergency reparent ([EmergencyReparentShard](../../configuration-advanced/reparenting/#emergencyreparentshard-emergency-reparenting))
- An unexpected external reparent
- As long as no more than `10` minutes pass between failure/demotion of previous `primary` tablet and the promotion of the new `primary` tablet. 

## Behavior and limitations

Whether by planned operation or an unplanned failure, a `vitess` migration's VReplication stream is interrupted while copying/applying data. VReplication's mechanism persists the state of data transfer transactionally with the transfer itself. Any replica will have a _consistent_ state of the migration, even if that replica lags behind the primary.

When a replica tablet is promoted as `primary`, it notices the VReplication stream, which is meant to be active and running. It sets up the connections and processes to resume its work. It is possible that some retries will take place as the stream re-evaluates its source of data.

The [Online DDL Scheduler](../../../design-docs/online-ddl/scheduler) detects the running stream, and identifies it as having been created by a different tablet. It assumes ownership of the stream and proceeds to follow its progress till completion.

The stream must be no more than `10` minutes stale, otherwise the scheduler marks the migration as failed.

There is no limitation on the number of failovers a `vitess` migration can survive.

No user action is required. Immediately after promotion/failover the migration will present as making no progress. It is likely to present progress within 1 or 2 minutes after promotion.
