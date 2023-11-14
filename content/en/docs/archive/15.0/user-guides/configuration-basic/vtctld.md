---
title: vtctld
weight: 5
---

vtctld is not required to be highly available because it is not in the serving path of a query. Nevertheless, it may be wise to bring up more than a single instance. Typically, users bring up one instance per cell.

Even if brought up within each cell, vtctld itself is not tied to that cell. It will attempt to access all servers of all cells. You can bring up vtctld with the following invocation:

```sh
vtctld <topo_flags> <backup_flags> \
  --log_dir=${VTDATAROOT}/tmp \
  --port=15000 \
  --grpc_port=15999 \
  --service_map='grpc-vtctl,grpc-vtctld'
```

If the TopoServer is unreachable, or if the topo flags are incorrectly configured, vtctld will fail to start. You may see an error message like the following in the logs:

```text
F0426 11:11:40.363545   14833 server.go:223] Failed to open topo server (etcd2,localhost:2379,/vitess/global): dial tcp 127.0.0.1:2379: connect: connection refused
```

The `service_map` flag allows you to configure the grpc APIs that a Vitess server exposes as grpc. If grpc-vtctl is not specified as a service\_map for vtctld, you will not be able to access it using `vtctlclient`.
Similarly, if grpc-vtctld is not specified as a service\_map for vtctld, you will not be able to access it using `vtctldclient`.

vtctld is usually not very resource intensive. But you may need to provision more if you plan to run the `VDiff` command. This functionality will soon be moved to vttablet.

## vtctldclient

Since we will be using `vtctldclient` often, it will be convenient to configure an alias for it:

```sh
alias vtctldclient="command vtctldclient --server <vtctld_grpc_address>"
```

{{< info >}}
We intend to move these arguments into an init file. Once that is done, there will be no need to set up the alias any more.
{{< /info >}}

The next step will be to create a cell.
