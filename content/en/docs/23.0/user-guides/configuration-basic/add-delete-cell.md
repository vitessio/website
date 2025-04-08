---
title: Add or Delete a Cell
weight: 15
---

## Add
To add a cell after a cluster is up and running, you start off by creating one using the same steps previously performed to create the first cell:

```sh
vtctldclient AddCellInfo \
  --root /vitess/cell2 \
  --server-address <cell2_topo_address> \
  cell2
```

Additionally, you will need to make the keyspace info visible in the cell. For every keyspace, issue the following:

```text
vtctldclient RebuildKeyspaceGraph --cells=cell2 <keyspace>
```

And finally, deploy the VSchema with

```text
vtctldclient RebuildVSchemaGraph --cells=cell2
```

{{< info >}}
If the `cells` option is not specified, the rebuild deploys to all cells.
{{< /info >}}

Once these steps are done, you can bring up the necessary MySQLs, vttablets and vtgates under that cell.

## Delete

To delete a cell, bring down all servers in that cell, and then remove its entry from the global topo with:

```
vtctldclient DeleteCellInfo --force cell2
```

If `--force` is not used the command will error out if any keyspace was deployed to that cell. There is currently no clean way to undeploy a keyspace from a cell. So, `--force` will need to be used for most use cases.

VTGates and vtctlds do not refresh themselves after a cell is deleted or updated. It is recommended that you restart them.

Once the Vitess components are restarted, the final step will be to bring down the cell-specific topo server.

If you had deployed a cell-specific toposerver, that can now be brought down. The deployed info under the cell's root (`/vitess/cell2`) will not be automatically deleted. You will have to manually delete that directory.
