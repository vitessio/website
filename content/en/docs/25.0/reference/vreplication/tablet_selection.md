---
title: Tablet Selection
weight: 300
---

### Introduction

For both [VTGate VStreams and VTTablet VReplication streams](../../../concepts/vstream/) we must choose a tablet to serve the role of *source* (vstreamer). This
tablet selection is performed by the internal `TabletPicker` component.

{{< info >}}
For VReplication streams a tablet also serves the role of *target* (vapplier). These, however, will always be the primary tablets in the target keyspace as we
need to replicate the streamed writes within the target shard.
{{< /info >}}

### Cells and Cell Preference

By default the `TabletPicker` will only look for viable (healthy and serving) source tablets of the specified tablet type(s) within the local cell (or cell alias within which the local cell belongs) of the
calling process — the `vtgate` managing the VStream or the target `vttablet` for the VReplication stream — and it will select a random one from the candidate
list. If you want to support cross-cell streams then you will need to specify the list of cells or any
[CellAlias](../../programs/vtctl/cell-aliases/) that contain a list of cells using the `--cells` flag in your VReplication
workflow commands like [`MoveTables`](../movetables/) or the
[`VStreamFlags.Cells`](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/vtgate#VStreamFlags) field in a
[`VStreamRequest`](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/vtgate#VStreamRequest).

Even with the `--cells` flag specified, by default, the `TabletPicker` will give preference to a healthy and serving tablet within the local cell of the calling process. If there are multiple candidates in the local cell, it will pick one at random. If no healthy tablets exist in the local cell pool, then it will give preference to tablets within cells belonging to the same cell alias as the local cell. If none exist here, then it moves on to selecting candidates from cells provided using the `--cells` flag in your VReplication workflow commands.

When using the [VTGate VStream API](../vstream/), you can override this local cell preference by specifying the `CellPreference` field as `onlyspecified` and a list of cells with `Cells` in the [VStreamFlags](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/vtgate#VStreamFlags) request object. This will then only pick tablets from the cells provided.


### Tablet Types

#### VReplication

For VReplication the tablet types determines the candidate types made available for potential selection as the source for a stream (default value is `in_order:REPLICA,PRIMARY`). The target tablet will provide this value to the `TabletPicker` to determine the viable source tablet candidates. You specify the value on the client side using your
workflow command's `--tablet-types` flag.

You can also specify that the tablet types should be used in the order of preference as listed in the `--tablet-types` flag using the `--tablet-types-in-preference-order` flag. For example `--tablet-types "REPLICA,PRIMARY" --tablet-types-in-preference-order` would cause a replica source tablet to be used whenever possible
and a primary tablet would only be used as a fallback in the event that there are no viable replica tablets
available at the time.

{{< info >}}
When using the [VTGate VStream API](../vstream/) you should instead migrate to using the new `TabletOrder` field in the [VStreamFlags](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/vtgate#VStreamFlags) request object as usage of the "in_order" string hint will eventually be deprecated and removed.
{{< /info >}}

#### VStream

For a VStream there is no default tablet type. You must specify an individual tablet type using the
[`VStreamRequest.TabletType`](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/vtgate#VStreamRequest) field.