---
title: Tablet selection
weight: 300
---

### Introduction

For [VReplication streams](../../../concepts/vstream/), we must choose a tablet to serve the role of source (vstreamer) and target (vapplier) in the replication stream and this is done automatically.

To select the tablets we get a set of viable -- healthy and serving -- candidates for the source and target of the stream:
  * **Source**: a random tablet is selected from the viable candidates of the specified types (see [tablet types](./#tablet-types))
  * **Target**: a viable primary tablet is chosen, as we need to do writes that are then replicated within the target shard

### Cell considerations

VReplication will only look for tablet pairings within the same cell. If you want to have cross-cell streams then you will need to [create a CellAlias](https://vitess.io/docs/reference/programs/vtctl/cell-aliases/) that contains the list of potential cells and specify that using the `-cell` flag in your VReplication workflow commands.

### Tablet types

The server side default which determines the candidate types made available for potential selection in a stream is set using the [vttablet's `-vreplication_tablet_type` flag](../flags/#vreplication_tablet_type) (default value is `in_order:REPLICA,PRIMARY`). The target tablet will use this when finding the viable source tablet candidates.

You can override this on the client side using your workflow command's `-tablet_types` flag.

In Vitess 12.0 and later you can specify an order of preference for the tablet types using the `in_order:` prefix in both the server and client flags. For example, `-tablet_types "in_order:REPLICA,PRIMARY"` would cause a replica source tablet to be used whenever possible and a primary would only be used as a fallback in the event that there are no viable replicas available at the time.
