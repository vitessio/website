---
title: vtctld
weight: 5
---

vtctld is not required to be highly available because it is not in the serving path of a query. Nevertheless, it may be wise to bring up more than a single instance. Typically, users bring up one instance per cell.

Even if brought up within each cell, vtctld itself is not tied to that cell. It will attempt to access all servers of all cells. You can bring up vtctld with the following invocation:

```sh
vtctld <topo_flags> <backup_flags> \
  --log-dir=${VTDATAROOT}/tmp \
  --port=15000 \
  --grpc-port=15999 \
  --service-map='grpc-vtctl,grpc-vtctld'
```

If the TopoServer is unreachable, or if the topo flags are incorrectly configured, vtctld will fail to start. With the default JSON log format, the log shows an error like the following:

```json
{"time":"2026-04-26T11:11:40.363545-07:00","level":"ERROR","source":{"function":"vitess.io/vitess/go/vt/topo.Open","file":"/vt/src/vitess.io/vitess/go/vt/topo/server.go","line":272},"msg":"Failed to open topo server","topo_implementation":"etcd2","topo_global_server_address":"localhost:2379","topo_global_root":"/vitess/global","error":"unable to connect to etcd at localhost:2379: context deadline exceeded","error_code":"DEADLINE_EXCEEDED"}
```

Check `topo_implementation`, `topo_global_server_address`, and `topo_global_root` against the `--topo-implementation`, `--topo-global-server-address`, and `--topo-global-root` flags, and use `error` to see why the connection failed.

The `service_map` flag allows you to configure the grpc APIs that a Vitess server exposes as grpc. If grpc-vtctl is not specified as a service\_map for vtctld, you will not be able to access it using `vtctldclient`.
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
