---
title: LookupVindex
description: Create, backfill, and externalize Lookup Vindexes
weight: 60
---

[`LookupVindex`](../../../reference/programs/vtctldclient/vtctldclient_lookupvindex/) is a command used to create **and** backfill
a [Lookup Vindex](../../../reference/features/vindexes/#lookup-vindex-types) automatically for a table that already
exists, and may have a significant amount of data in it already.

Internally, the [`LookupVindex create`](../../../reference/programs/vtctldclient/vtctldclient_lookupvindex/vtctldclient_lookupvindex_create/) command uses
VReplication for the backfill process, until the lookup Vindex is "in sync". Then the normal process for
adding/deleting/updating rows in the lookup Vindex via the usual
[transactional flow when updating the "owner" table for the Vindex](../../../reference/features/vindexes/#lookup-vindex-types)
takes over.

## Command

Please see the [`LookupVindex` command reference](../../../reference/programs/vtctldclient/vtctldclient_lookupvindex/) for a full list of sub-commands and their flags.

## Interaction with MoveTables and Reshard

A lookup Vindex backfill (the `CreateLookupIndex` VReplication workflow that [`LookupVindex create`](../../../reference/programs/vtctldclient/vtctldclient_lookupvindex/vtctldclient_lookupvindex_create/) starts) keeps replicating from its original source keyspace, which is the owner table's keyspace. If a [`MoveTables`](../movetables/) workflow switches that keyspace's traffic with `SwitchTraffic` or `ReverseTraffic`, the backfill does not follow the moved tables to the other keyspace; it keeps reading from where it started. The paired `MoveTables` workflow keeps that source keyspace fed through reverse replication, which is on by default (`--enable-reverse-replication` defaults to `true`), so the backfill keeps working through the traffic switch.

Before sequencing this work, run `MoveTables show` (or `status`) against the workflow's target keyspace to confirm whether a `MoveTables` workflow moving the owner keyspace's tables is in progress, and whether its paired `_reverse` workflow exists.

{{< warning >}}
Because the backfill still reads from its original source keyspace, complete or externalize the lookup Vindex backfill (with [`LookupVindex externalize`](../../../reference/programs/vtctldclient/vtctldclient_lookupvindex/vtctldclient_lookupvindex_externalize/)) before you run [`MoveTables Complete`](../movetables/#complete) on that keyspace. `Complete` drops the source tables the backfill reads from; running it while the backfill is still in progress means the lookup Vindex must be rebuilt.
{{< /warning >}}

If you run `SwitchTraffic` with `--enable-reverse-replication=false`, nothing feeds the backfill's source keyspace after the switch. An active backfill sourcing that keyspace keeps running but silently goes stale. It can catch up only if reverse replication is started (or the switch is reversed) while the source tables and the needed binary logs still exist; otherwise the lookup Vindex must be rebuilt.

A [`Reshard`](../reshard/) of the owner keyspace is not affected. This only applies to `MoveTables`, which moves the owner table to a different keyspace; a `Reshard` keeps it in the same keyspace, so the backfill is carried across the reshard.

## Additional Information

Please see the user guide for examples of [Creating a Lookup Vindex](../../../user-guides/configuration-advanced/createlookupvindex/) for more information on how to use this command.
