---
title: Global TopoServer
weight: 4
aliases: ['/docs/user-guide/topology-service/']
---

The first component to bring up is the Global TopoServer. As mentioned before, this can be a zookeeper or etcd cluster. The servers will likely have to be distributed across data centers for resilience. Please refer to the corresponding documentation for instructions on how to configure and launch these servers.

{{< info >}}
Vitess previously supported Consul as a TopoServer. However, it is now deprecated because Consul does not natively support the ability to connect to multiple servers from a single program. This is a prerequisite for multi-region deployments.
{{< /info >}}

Vitess will store global metadata like keyspaces, shards and cells in the topserver.

## Choosing a TopoRoot

Vitess allows you to share the same global toposerver for multiple clusters. For example, you may want to run separate testing, staging and production clusters.

To support this separation, we allow you to assign a root directory in the Topo for each cluster. This directory is known as the `topo_global_root` and will need to be provided as a command line flag to every Vitess component.

{{< info >}}
In the case of ZooKeeper, you will also need to create this directory on the server. For etcd, the path will be automatically created on first write.
{{< /info >}}

The following command line options are required for every Vitess component:

```text
--topo_implementation=etcd2 --topo_global_server_address=<comma_separated_addresses> --topo_global_root=/vitess/global
```

To avoid repetition we will use `<topo_flags>` in our examples to signify the above flags.

Note that the topo implementation for etcd is `etcd2`. This is because Vitess uses the v2 API of etcd.

{{< info >}}
To be safe, you may want to bring up etcd with `--enable-v2=true`, even though it is the default value. Also, you will need to set the `ETCDCTL_API=2` environment variable before bringing up etcd.
{{< /info >}}

## Moving to a Different TopoServer

It is generally not recommended that you migrate from one type of toposerver to another. However, if absolutely necessary, you can use the [topo2topo](../../../reference/features/topology-service/#migration-between-implementations) command line tool to perform this migration.

## Backups

It is important to periodically backup the data in the TopoServer. Although most of the information in the TopoServer can be manually reconstructed, it is still a painful task. This can be avoided if a recent backup was readily available.

## Checklist

* Ensure toposerver is up, and that you can set and get values using their provided client tools.
* Ensure you have the mechanism to include the correct topo flags for all the components: `--topo_implementation`, `--topo_global_server_address` and `--topo_global_root`.
* If using zookeeper, ensure the global root path is created. It may be beneficial to do the same for etcd also.
* Ensure that the servers are reachable from other parts of the system where Vitess components will be launched.
