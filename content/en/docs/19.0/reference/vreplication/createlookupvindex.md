---
title: CreateLookupVindex
weight: 60
---

**CreateLookupVindex** is a [VReplication](../../../reference/vreplication/) workflow used to create **and** backfill
a [lookup Vindex](../../../reference/features/vindexes/#lookup-vindex-types) automatically for a table that already
exists, and may have a significant amount of data in it already.

Internally, the [`CreateLookupVindex`](../../../reference/vreplication/createlookupvindex/) process uses
VReplication for the backfill process, until the lookup Vindex is "in sync". Then the normal process for
adding/deleting/updating rows in the lookup Vindex via the usual
[transactional flow when updating the "owner" table for the Vindex](../../../reference/features/vindexes/#lookup-vindex-types)
takes over.

In this guide, we will walk through the process of using the [`CreateLookupVindex`](../../../reference/vreplication/createlookupvindex/)
workflow, and give some insight into what happens underneath the covers.

The `CreateLookupVindex` `vtctl` client command has the following syntax:

```CreateLookupVindex -- [--cells=<source_cells>] [--continue_after_copy_with_owner=false] [--tablet_types=<source_tablet_types>] <keyspace> <json_spec>```

* `<json_spec>`:  Use the lookup Vindex specified in `<json_spec>` along with
  VReplication to populate/backfill the lookup Vindex from the source table.
* `<keyspace>`:  The Vitess keyspace we are creating the lookup Vindex in.
  The source table is expected to also be in this keyspace.
* `--tablet-types`:  Provided to specify the tablet types
  (e.g. `PRIMARY`, `REPLICA`, `RDONLY`) that are acceptable
  as source tablets for the VReplication stream(s) that this command will
  create. If not specified, the tablet type used will default to the value
  of the [`vttablet --vreplication_tablet_type` flag](../../../reference/vreplication/flags/#vreplication_tablet_type)
  value, which defaults to `in_order:REPLICA,PRIMARY`.
* `--cells`: By default VReplication streams, such as used by
  `CreateLookupVindex`, will not cross cell boundaries. If you want the
  VReplication streams to source their data from tablets in cells other
  than the local cell, you can use the `--cells` option to specify a
  comma-separated list of cells (see [VReplication tablet selection](../../../reference/vreplication/tablet_selection/)).
* `--continue_after_copy_with_owner`: By default, when an owner is provided in the `<json_spec>`,
  the VReplication streams will stop after the backfill completes. Specify this flag if
  you don't want this to happen. This is useful if, for example, the owner table is being
  migrated from an unsharded keyspace to a sharded keyspace using
  [`MoveTables`](../../../reference/vreplication/movetables/).

The `<json_spec>` describes the lookup Vindex to be created, and details about
the table it is to be created against (on which column, etc.). However,
you do not have to specify details about the actual lookup table, Vitess
will create that automatically based on the type of the column you are
creating the Vindex column on, etc.