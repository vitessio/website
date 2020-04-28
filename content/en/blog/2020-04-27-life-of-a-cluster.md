---
author: "Sugu Sougoumarane"
date: 2020-04-27T20:30:00
slug: "2020-04-27-life-of-a-cluster"
tags: ['vitess', 'vitess cluster', 'vitess troubleshooting', 'vitess getting started']
title: "Life of a Vitess Cluster"
---

This post goes into the details of what goes on behind the scenes when a cluster is brought up. This can be used both as a learning tool and troubleshooting guide. We assume that you have downloaded and installed all the necessary binaries before proceeding further.

Vitess is a very flexible system that is capable of running in a variety of environments. The local example does oversimplify things a bit. However, you will need to take more things into consideration when taking Vitess into production.

It will also be important to know how the various components interact with each other. This knowledge will facilitate troubleshooting if a cluster does not come up as intended.

## Choosing a Topology Server

The first component one needs to bring up is actually not a Vitess component. The toposerver can be ZooKeper, etcd, consul, or Kubernetes. Vitess needs a topo server to be up and running. The steps needed to bring up every kind of toposerver are not covered here.

Once you bring up the TopoServer, make sure that you can connect to it using one of their clients.

### Choosing a Topo root

You will probably need to run multiple independent Vitess clusters. For example, you may want to separate out the testing and staging clusters from the production one. However, you may still want to reuse the same TopoServer for all of these.

For this reason, Vitess allows you to choose a root directory in the Topo for each cluster. This directory is known as the `topo_global_root` and will need to be provided for every Vitess binary that is launched.

Caveat: In the case of ZooKeeper, you will actually need to create this directory in the server.

In the local example, we have chosen this to be `/vitess/global`. Here is a sample command to bring up etcd:

```
ETCD_SERVER="localhost:2379" etcd \
  --enable-v2=true \
  --data-dir="${VTDATAROOT}/etcd/" \
  --listen-client-urls="http://${ETCD_SERVER}" \
  --advertise-client-urls="http://${ETCD_SERVER}"
```

## Configuring vtctld

The most important flags for vtctld are the parameters needed to connect to the TopoServer and `-topo_global_root`. Here is a sample vtctld invocation:

```
vtctld \
  -topo_implementation=etcd2 \
  -topo_global_server_address=localhost:2379 \
  -topo_global_root=/vitess/global \
  -port=15000 \
  -grpc_port=15999 \
  -service_map='grpc-vtctl'
```

If the TopoServer is unreachable, or if the `topo_global_root` is not specified, vtctld will fail to start. You should see the following error message in the logs:

```
F0426 11:11:40.363545   14833 server.go:223] Failed to open topo server (etcd2,localhost:2379,/vitess/global): dial tcp 127.0.0.1:2379: connect: connection refused
```

Other required parameters to vtctld are `port`, `grpc_port` and `service_map 'grpc-vtctl'`.

The service_map flag allows you to configure the grpc APIs that a Vitess server exposes as gRPC. If grpc-vtctl is not specified as a service_map for vtctld, you will not be able to access it using vtctlclient.

## Creating a cell

The next step is to create a [cell](https://vitess.io/docs/concepts/cell/). This can be done by issuing the following command:

```
vtctlclient AddCellInfo -root=/vitess/zone1 -server_address=<address> zone1
```

NOTE: vtctlclient does not need a topo global root, because it only talks to vtctld, and vtctld already has that value.

The ‘-root’ flag is different from topo_global_root. All information specific to the cell will be stored under `/vitess/zone1`.

For higher fault tolerance, you can set up and specify a different TopoServer to serve the local cell. If isolation of failure zones is not important, you could just reuse the main TopoServer as long as you ensure that the root paths don’t conflict.

The last parameter “zone1” is the name of the cell, which is required by the subsequent tools.

You can verify this information by browsing the Topology in vtctld:

<figure>
  <img src="/files/2020-life-cluster/cell-in-topo.png"/>
</figure>
