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

### Cells

By default the `TabletPicker` will only look for viable (healthy and serving) source tablets within the local cell of the calling process — the `vtgate`
managing the VStream or the target `vttablet` for the VReplication stream — and it will select a random one from the candidate list. If you want to support
cross-cell streams then you will need to specify the list of cells or any [CellAlias](https://vitess.io/docs/reference/programs/vtctl/cell-aliases/) that
contain the list of potential cells using the `--cells` flag in your VReplication workflow commands like [`MoveTables`](../movetables/) or the
[`VStreamFlags.Cell`](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/vtgate#VStreamFlags) field in a
[`VStreamRequest`](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/vtgate#VStreamRequest).

### Tablet Types

#### VReplication
For VReplication, the server side default which determines the candidate types made available for potential selection in a stream is set using the
[`vttablet` `--vreplication_tablet_type` flag](../flags/#vreplication_tablet_type) (default value is `in_order:REPLICA,PRIMARY`). The target tablet will
provide this value to the `TabletPicker` to determine the viable source tablet candidates. You can override this default on the client side using your
workflow command's `--tablet_types` flag.

You can also specify an order of preference for the tablet types using the `in_order:` prefix in both the server and client flags. For example,
`--tablet_types "in_order:REPLICA,PRIMARY"` would cause a replica source tablet to be used whenever possible and a primary tablet would only be used as
a fallback in the event that there are no viable replica tablets available at the time.

#### VStream
For a VStream there is no default tablet type, you must specify an individual tablet type using the
[`VStreamRequest.TabletType`](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/vtgate#VStreamRequest) field.