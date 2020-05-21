---
author: "Pratik Gupta"
date: 2020-05-19T11:20:00
slug: "2020-05-19-vitess-cross-cell"
tags: ['vitess', 'vitess cluster', 'vitess cross-cell', 'vitess getting started']
title: "Vitess: The Cross Cell Connection"
---

This post explains about how VTGate handles cross-cell operations and how to configure CellAlias for cross-cell read operations.
If you are new to Vitess, it is recommended to [read this blog post](./2020-04-27-life-of-a-cluster) to get more familiar with the various components and their configuration in Vitess.

To understand CellAlias, first let's get familiar with what a cell means in Vitess. A cell is a group of servers and network infrastructure collocated in an area, and isolated from failures in other cells. It is typically either a full data center or a subset of a data center, sometimes called a zone or availability zone. Vitess gracefully handles cell-level failures, such as when a cell is cut off the network.
By default Vitess limits cross-cell traffic by only routing the writes to a master if it does not reside in the current cell. Vitess will always prefer the replicas in the current cell for all read operations.

However in some cases it may be necessary to route read operations to different cells eg. when all the replicas in the current cell fail. For all such cases, we need to configure CellAlias.

## CellAlias

A CellAlias defines a group of cells within which replica/rdonly traffic can be routed across cells. By default, Vitess does not allow replica traffic between different cells. Between cells that are not in the same group (alias), only master traffic can be routed.

Here is a sample command for creating a CellAlias:

```
vtctl \
  -topo_implementation=etcd2 \
  -topo_global_server_address=localhost:2379 \
  -topo_global_root=/vitess/global \
  AddCellsAlias \
  -cells zone1,zone2 \
  cellglobal
```

Here `zone1` and `zone2` are two cells in different datacenters and `cellglobal` is the alias name.

## Configuring VTGate

Although we do not need to pass the CellAlias name directly to VTGate, we do need to pass all the cell names that are part of the CellAlias using the `-cells_to_watch` flag.
VTGate will be able to route read queries to all cells that it is watching which also belong to the same cellAlias as vtgate's local cell (`-cell` flag).

Here is a sample command for setting `-cells_to_watch` flag in VTGate:

```
vtgate \
  -topo_implementation=etcd2 \
  -topo_global_server_address=localhost:2379 \
  -topo_global_root=/vitess/global \
  -cell=zone1 \
  -cells_to_watch=zone1,zone2 \
  -port=15001 \
  -grpc_port=15991 \
  -service_map='grpc-vtgateservice' \
  -mysql_server_port=$mysql_server_port \
  -mysql_auth_server_impl=none
```

### Understanding VTGate Cross-Cell Behaviour

1. VTGate will always be able to route to a master in a different cell (which is part of cells_to_watch) even without a cellAlias. the cellAlias requirement is only for replicas.
2. By default VTGate sends all queries(reads and writes) to the master.
3. Replica reads can be performed by first issuing a `use ks@replica` where `ks` should be replaced by your keyspace name.
4. VTGate will always prefer tables that are in the same cell over tablets in other cells despite the CellAlias.
5. VTGate caches the CellAliases from the Topology Server, so if an alias is created/updated after the VTGate instance has been started then VTGate must be restarted to fetch the CellAlias. This behaviour is similar to adding/removing new cells where the VTGate instances need to be restarted to udpate the `-cells_to_watch` values.
