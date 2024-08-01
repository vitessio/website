---
title: VTGate Tablet Balancer
aliases: ['/docs/user-guides/tablet-balancer/','/docs/reference/tablet-balancer/']
---

# VTGate Tablet Balancer

When a VTGate routes a query and has multiple available tablets for a given shard / tablet type (e.g. REPLICA),
it implements a balancing mechainsm to pick a candidate tablet to route to. At a high level, this process aims to
maintain an even distribution of query load to each tablet, while preferentially routing to tablets in the same cell
as the VTGate to reduce latency.

In other words, the balancer attempts to achieve two objectives:

1. Balance the load across the available tablets
2. Prefer a tablet in the same cell as the vtgate if possible

## Default Policy

The default behavior is a local cell affinity round robin policy.

This means that when routing a given query, all the available tablets are randomly shuffled while preferring tablets
in the same cell as the VTGate. So if there is one or more available tablets in the same cell as the VTGate, the query
will be routed to one of those tablet(s), otherwise it will randomly pick a tablet in another cell.

In many cases this approach suffices, since if there are a proportional number of local tablets in each cell to
satisfy the inbound traffic to the vtgates in that cell, then in general the queries will be distributed evenly to
each tablet.

## Balancer Motivation

However, in some topologies, a simple affinity algorithm does not effectively balance the load.

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

For these topologies, the tabletBalancer proportionally assigns the output flow to each tablet,
preferring the local cell where possible, but only as long as the global query balance is
maintained.

## Algorithm

To accomplish this goal, the balancer is given:

* The list of cells that receive inbound traffic to vtgates (from configuration)
* The local cell where the vtgate exists (from configuration)
* The set of tablets and their cells (learned from discovery)

The model assumes there is an equal probablility of a query coming from each vtgate cell, i.e.
traffic is effectively load balanced between the cells with vtgates.

Given that information, the balancer builds a simple model to determine how much query load
would go to each tablet if vtgate only routed to its local cell. Then if any tablets are
unbalanced, it shifts the desired allocation away from the local cell preference in order to
even out the query load.

Based on this global model, the vtgate then probabalistically picks a destination for each
query to be sent and uses these weights to order the available tablets accordingly.

Assuming each vtgate is configured with and discovers the same information about the topology,
and the input flow is balanced across the vtgate cells (as mentioned above), then each vtgate
should come the the same conclusion about the global flows, and cooperatively should
converge on the desired balanced query load.

## Configuration

To enable the balancer requires the following configuration:

  * `--balancer-enabled`:  Enables the balancer.  **Not enabled by default**
  * `--balancer-vtgate-cells`:  Specifies the set of cells that contain vtgates

Optionally this behavior can be restricted only when routing to certain keyspaces as a means of controlling rollout:

  * `--balancer-keyspaces`:  Specifies the set of keyspaces for which the balancer should be enabled.
