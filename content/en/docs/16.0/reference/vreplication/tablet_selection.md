---
title: Tablet Selection
weight: 300
---

### Introduction

For both [VTGate VStreams and VTTablet VReplication streams](../../../concepts/vstream/) we must choose a tablet to serve the role of source (vstreamer). For VReplication streams we must also choose a a tablet to serve the role of target (vapplier). This tablet selection is performed by the internal `TabletPicker` component.

To select the tablets we get a set of viable — healthy and serving — candidates for the source and target of the stream as needed:
  * **Source**: a random tablet is selected from the viable candidates of the specified tablet types in the given cells
  * **Target**: a viable primary tablet is chosen, as we need to do writes that are then replicated within the target shard

### Cells

The `TabletPicker` will only look for source and target tablet tablets within the same cell of the calling process by default — the `vtgate` managing the VStream or the target `vttablet` for a VReplication stream — so e.g. if the target primary tablet is in the `zone1` cell it will only look for source tablets in the `zone1` cell. If you want to have cross-cell streams then you will need to specify the list of cells or any [CellAlias](https://vitess.io/docs/reference/programs/vtctl/cell-aliases/) that contain the list of potential cells using the `--cells` flag in your VReplication workflow commands like [`MoveTables`](../movetables/) or the [`VStreamFlags.Cell`](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/vtgate#VStreamFlags) field in a [`VStreamRequest`](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/vtgate#VStreamRequest).

### Tablet Types

#### VReplication
For VReplication, the server side default which determines the candidate types made available for potential selection in a stream is set using the [`vttablet` `--vreplication_tablet_type` flag](../flags/#vreplication_tablet_type) (default value is `in_order:REPLICA,PRIMARY`). The target tablet will use this when finding the viable source tablet candidates.

You can override this on the client side using your workflow command's `--tablet_types` flag.

You can specify an order of preference for the tablet types using the `in_order:` prefix in both the server and client flags. For example, `--tablet_types "in_order:REPLICA,PRIMARY"` would cause a replica source tablet to be used whenever possible and a primary would only be used as a fallback in the event that there are no viable replicas available at the time.

#### VStream
For a VStream, you specify a single tablet type using the [`VStreamRequest.TabletType`](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/vtgate#VStreamRequest) field.