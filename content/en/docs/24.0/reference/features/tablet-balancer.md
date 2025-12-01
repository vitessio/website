---
title: VTGate Tablet Balancer
---

# VTGate Tablet Balancer

When a VTGate routes a query and has multiple available tablets for a given shard / tablet type (e.g. REPLICA),
it implements a balancing mechanism to pick a candidate tablet to route to. At a high level, this process aims to
maintain an even distribution of query load to each tablet, while preferentially routing to tablets in the same cell
as the VTGate to reduce latency.

In other words, the balancer attempts to achieve two objectives:

1. Balance the load across the available tablets
2. Prefer a tablet in the same cell as the vtgate if possible

## Default Policy

The default behavior is a local cell affinity random choice policy.

This means that when routing a given query, all the available tablets are randomly shuffled while preferring tablets
in the same cell as the VTGate. So if there is one or more available tablets in the same cell as the VTGate, the query
will be routed to one of those tablet(s), otherwise it will randomly pick a tablet in another cell.

In many cases this approach suffices, since if there are a proportional number of local tablets in each cell to
satisfy the inbound traffic to the vtgates in that cell, then in general the queries will be distributed evenly to
each tablet.

## Balancer Modes

However, in some topologies, a simple affinity algorithm does not effectively balance the load.
VTGate provides two additional balancer modes to address different topology and traffic patterns:
**prefer-cell** and **random**.

### When Default Policy is Insufficient

As a simple example:

Given three cells with vtgates, four replicas spread into those cells, where each vtgate
receives an equal query share. If each routes only to its local cell, the tablets will be
unbalanced since two of them receive 1/3 of the queries, but the two replicas in the same
cell will only receive 1/6 of the queries.

```
  Cell A: 1/3 --> vtgate --> 1/3 => vttablet

  Cell B: 1/3 --> vtgate --> 1/3 => vttablet

  Cell C: 1/3 --> vtgate --> 1/6 => vttablet
                         \-> 1/6 => vttablet
```

Other topologies that can cause similar pathologies include cases where there may be cells
containing replicas but no local vtgates, and/or cells that have only vtgates but no replicas.

### Prefer-Cell Balancer

The prefer-cell balancer addresses topologies where tablets and vtgates are unevenly distributed,
but traffic is relatively balanced across vtgate cells. It proportionally assigns the output
flow to each tablet, preferring the local cell where possible, but only as long as the global
query balance is maintained.

To accomplish this goal, the prefer-cell balancer is given:

* The list of cells that receive inbound traffic to vtgates (from configuration)
* The local cell where the vtgate exists (from configuration)
* The set of tablets and their cells (learned from discovery)

The model assumes there is an equal probability of a query coming from each vtgate cell, i.e.
traffic is effectively load balanced between the cells with vtgates.

Given that information, the balancer builds a simple model to determine how much query load
would go to each tablet if vtgate only routed to its local cell. Then if any tablets are
unbalanced, it shifts the desired allocation away from the local cell preference in order to
even out the query load.

Based on this global model, the vtgate then probabilistically picks a destination for each
query to be sent and uses these weights to order the available tablets accordingly.

Assuming each vtgate is configured with and discovers the same information about the topology,
and the input flow is balanced across the vtgate cells (as mentioned above), then each vtgate
should come to the same conclusion about the global flows, and cooperatively should
converge on the desired balanced query load.

**When to use prefer-cell mode:**
* Tablets and vtgates are distributed unevenly across cells
* Traffic is relatively balanced across all vtgate cells
* You want to maintain cell affinity where possible to minimize latency

### Random Balancer

The random balancer addresses a different scenario: when application traffic is concentrated
in fewer cells than where database replicas exist. Unlike the prefer-cell balancer, which
assumes equal traffic distribution across vtgate cells, the random balancer makes no assumptions
about traffic patterns.

The random balancer selects tablets with uniform probability (1/N for N available tablets),
completely ignoring cell affinity. This trades off potential latency optimization for a
guaranteed even load distribution across all tablets, regardless of where traffic originates.

**When to use random mode:**
* Application traffic is highly concentrated in specific cells (e.g., 90% in one cell, 10% in another)
* Cross-cell/cross-zone latency is acceptable for your workload
* Avoiding tablet hotspots is more important than minimizing query latency
* You have a single-AZ application deployment with multi-AZ database replicas

**Example scenario:**

```
  Cell A: 90% --> vtgates --> randomly select from all tablets (1/4 each)
  Cell B: 10% --> vtgates --> randomly select from all tablets (1/4 each)

  Result: All 4 tablets receive ~25% of total load, regardless of cell
```

With the random balancer, you can optionally use `--balancer-vtgate-cells` to restrict the
tablet pool to specific cells, but it's not required.

## Configuration

VTGate provides three balancer modes, controlled by the `--vtgate-balancer-mode` flag:

### Balancer Mode Selection

* **`--vtgate-balancer-mode=cell`** (default): Uses local cell affinity random choice (default policy described above)
* **`--vtgate-balancer-mode=prefer-cell`**: Uses the prefer-cell balancer algorithm
* **`--vtgate-balancer-mode=random`**: Uses uniform random selection across all tablets

### Configuration Flags

* **`--vtgate-balancer-mode`**: Specifies which balancer mode to use (cell, prefer-cell, or random). Defaults to `cell`.

* **`--balancer-vtgate-cells`**: Comma-separated list of cells that contain vtgates.
  * **Required** for `prefer-cell` mode
  * **Optional** for `random` mode (filters tablets to specified cells if provided)
  * Ignored for `cell` mode

* **`--balancer-keyspaces`**: Comma-separated list of keyspaces for which to use the configured balancer mode. If empty, applies to all keyspaces. This allows gradual rollout of balancer modes.

### Deprecated Flag

* **`--enable-balancer`**: **(DEPRECATED)** This flag has been replaced by `--vtgate-balancer-mode=prefer-cell`. While still accepted for backwards compatibility, it will be removed in a future release. If you are currently using `--enable-balancer`, migrate to using `--vtgate-balancer-mode=prefer-cell` instead.
