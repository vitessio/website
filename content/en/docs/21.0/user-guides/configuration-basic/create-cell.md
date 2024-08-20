---
title: Creating a cell
weight: 6
---

A Vitess [cell](../../../concepts/cell) is a logical grouping of servers that typically maps to an availability zone, region, or data center. The purpose of a cell is to provide isolation. The loss of one cell should not disrupt other cells. To fulfil this, Vitess allows you to configure separate cell-specific topo servers. There is no need to distribute the servers of a cell-specific toposerver to other cells. However, it is recommended that you bring up more than one instance in order to survive individual server failures.

Even if you do not want a multi-cell deployment, you still need to create at least one cell before bringing up the rest of the Vitess servers. If you do not plan to deploy multiple cells, you can reuse the global toposerver as the cell-specific one also.

You can use the `vtctldclient` alias to create one:

```sh
vtctldclient AddCellInfo \
  --root /vitess/cell1 \
  --server-address <cell_topo_address> \
  cell1
```

Note that the cell topo has its own root path. If reusing the same toposerver, you must ensure that they don’t overlap.

The cell information is saved in the global toposerver. Vitess takes care of deploying the necessary information from the global topo to the cell-specific topos. Vitess binaries fetch the cell information from the global topo before switching to use the cell topo.

{{< info >}}
You will only need to specify the topo global root for launching the Vitess servers. The cell-specific information including its root path will be automatically loaded from the cell info.
{{< /info >}}

## Mapping Cells to Zones and Regions

Most public clouds offer a hierarchy of failure boundaries. Regions are data centers that are far apart. Depending on the distance, the latency between two regions can be in the 10s to 100s of milliseconds. Zones are partitions within a region where the machines are in different buildings. Latency between zones is typically in the range of sub-millisecond to 1-2ms.

There is also a cost to transferring data between zones and regions, and these costs can come into play when making decisions about how to layout the topology.

The general recommendation for Vitess is to map each cell to a zone. The main advantage of this approach is that it minimizes cross-zone data transfers to the extent possible, thereby minimizing cost.

If an application must be deployed across regions, then you can create more cells in the newer region, one for each zone.

Within a region, you could use a single topo cluster to serve all the cells, as long as their root paths are distinct, or you could use one topo cluster per cell. The decision depends on the kind of failure tolerance you want to build into the system.

For example, let us say that you plan to deploy in three zones and decided to use a shared topo. In this case, losing two zones will result in a full outage because the topo server in the third zone would become unavailable due to loss of quorum. On the other hand, deploying a separate topo cluster for each cell would allow the third zone to survive the loss of the other two zones.

If you intend to use more than one region for the sake of survivability, then it is recommended that you use at least three regions. This will allow you to deploy a balanced quorum of servers for the global topo.

If you have deployed in multiple regions and would like the flexibility of queries that go cross-cell within a region, you can create [cell aliases](../../../reference/programs/vtctl/cell-aliases). These aliases will indicate to the vtgates that they can send requests to the vttablets of a different cell if a no local vttablet is available.

## Checklist

* Ensure that vtctlds come up successfully. If there is a failure, check the log files for any errors.
* Ensure that you can query the http port of vtctld: `curl http://localhost:15000/cells/`
* If you configured a separate cell-specific topo, ensure that you can connect to it using the parameters in the cell information.
* Ensure that the cell-specific topos are reachable from other cells.

Open the VTAdmin application in your browser. Go to Topology > View Topology
Browsing to the cell information should look like this screenshot:

![cell-in-topo](../img/cell-in-topo.png)

