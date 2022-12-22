---
title: Mount
description: Link an external cluster to the current one
weight: 90
---

### Command

```
Mount -- [--type vitess] [--topo_type=etcd2|consul|zookeeper] [--topo_server=topo_url]
    [--topo_root=root_topo_node> [--unmount] [--list] [--show]  [<cluster_name>]
```

### Description

Mount is used to link external Vitess clusters to the current cluster.

Mounting Vitess clusters requires the topology information of the external cluster to be specified. Used in conjunction with [the `Migrate` command](../migrate).

{{< info >}}
No validation is performed when using the `Mount` command. You must ensure your values are correct, or you may get errors when initializing a migration.
{{< /info >}}


### Parameters

#### cluster_name

The name that will be used in VReplication workflows to refer to the mounted cluster. Required when mounting, unmounting or getting details of a cluster.

#### unmount

Unmount an already mounted cluster. Requires `cluster_name` to be specified.

#### --show

Show details of an already mounted cluster. Requires `cluster_name` to be specified.

#### --list

List all mounted clusters.

### Topo Parameters

##### --topo_type=[etcd2|consul|zookeeper]
##### --topo_server=<topo_url>
##### --topo_root=<root_topo_node>

Mandatory (and only specified) while mounting a Vitess cluster. These should specify the topology parameters of the cluster being mounted.
