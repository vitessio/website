---
title: Creating a cell
weight: 6
---

A Vitess [cell](../../../concepts/cell) is a logical grouping of servers that typically maps to an availability zone, region, or data center. The purpose of a cell is to provide isolation. The loss of one cell should not disrupt other cells. To fulfil this, Vitess allows you to configure separate cell specific topo servers. There is no need to distribute the servers of a cell specific toposerver to other cells. However, it is recommended that you bring up more than one instance in order to survive individual server failures.

Even if you do not want a multi-cell deployment, you still need to create at least one cell before bringing up the rest of the Vitess servers. If you do not plan to deploy multiple cells, you can reuse the global toposerver as the cell-specific one also.

You can use the `vtctlclient` alias to create one:

```sh
vtctlclient AddCellInfo \
  -root /vitess/zone1 \
  -server_address <cell_topo_address> \
  zone1
```

Note that the cell topo has its own root path. If reusing the same toposerver. You must ensure that they don’t overlap.

The cell information is saved in the global toposerver. Vitess takes care of deploying the necessary information from the global topo to the cell specific topos. Vitess binaries fetch the cell information from the global topo before switching to use the cell topo.

{{< info >}}
You will only need to specify the topo global root for launching the vitess servers. The cell-specific information including its root path will be automatically loaded from the cell info.
{{< /info >}}

## Checklist

* Ensure that vtctlds come up successfully. If there is a failure, check the log files for any errors.
* Ensure that you can browse to the http port of vtctld. The dashboard should appear, and you should be able to browse under the `Topology` tab and verify that the cell information is as you created it.
* If you configured a separate cell specific topo, ensure that you can connect to it using the parameters in the cell information.
* Ensure that the cell specific topos are reachable from other cells.

Browsing to the cell information should look like this screenshot:

![cell-in-topo](../img/cell-in-topo.png)

{{< info >}}
Clicking on the `zone1` link will fail because metadata under that path will be created only when we bring up cell specific vitess components.
{{< /info >}}
