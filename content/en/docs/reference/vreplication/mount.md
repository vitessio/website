---
title: Mount
description: Link an external cluster to the current one
weight: 90
---
##### _Experimental_

This documentation is for a new (v2) set of vtctld commands. See [RFC](https://github.com/vitessio/vitess/issues/7225) for more details.

### Command

```
Mount [-type vitess] [-topo_type=etcd2|consul|zookeeper] [-topo_server=topo_url]
    [-topo_root=root_topo_node> [-unmount] [-list] [-show]  [<cluster_name>]
```

### Description

Mount is used to link external vitess clusters to the current cluster. (In the future we will also support mounting external MySQL servers.)

Mounting vitess clusters requires the topology information of the external cluster to be specified. Used in conjunction with [the Migrate command](../migrate).

### Parameters

#### cluster_name

The name that will be used in VReplication workflows to refer to the mounted cluster. Required when mounting, unmounting or getting details of a cluster.

#### unmount

Unmount an already mounted cluster. Requires `cluster_name` to be specified.

#### show

Show details of an already mounted cluster. Requires `cluster_name` to be specified.

#### list

List all mounted clusters

### Topo parameters

##### topo_type=[etcd2|consul|zookeeper]
##### topo_server=<topo_url>
##### topo_root=<root_topo_node>

Mandatory (and only specified) while mounting a Vitess cluster. These should specify the topology parameters of the cluster being mounted.
