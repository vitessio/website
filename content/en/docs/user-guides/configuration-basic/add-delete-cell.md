---
title: Add or Delete a Cell
weight: 15
---

## Add
To add a cell after a cluster is up and running, you start off with creating one using the same steps we performed for creating the first cell:

```sh
vtctlclient AddCellInfo \
  -root /vitess/zone2 \
  -server_address <zone2_topo_address> \
  zone1
```

Additionally, you will need to deploy the keyspaces to the new cell. For every keyspace, issue the following:

```text
vtctlclient RebuildKeyspaceGraph -cells=zone2 <keyspace>
```

And finally, deploy the VSchema with

```text
vtctlclient RebuildVSchemaGraph -cells=zone2
```

Once these steps are done, you can bring up the necessary mysqls, vttablets and vtgates under that cell.

## Delete

To delete a cell, bring down all servers in that cell, and then remove its entry from the global topo with:

```
vtctlclient DeleteCellInfo -force zone2
```

If `-force` is not used the command will error out if any keyspace was deployed to that cell. There is currently no clean way to undeploy a keyspace from a cell. So, `-force` will need to be used for most use cases.

VTGates and vtctlds do not refresh themselves after a cell is deleted or updated. It is recommended that you restart them.

Once the vitess components are restarted, the last and final step will be to bring down the cell specific topo server.
