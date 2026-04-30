---
title: vtgr (experimental)
weight: 10
---

`vtgr` is a stateless orchestration component that integrates Vitess with MySQL group replication: it is responsible to bootstrap MySQL group and reconcile between the group and Vitess. It is available as an experimental feature. It still needs thorough testing, and more features need to be added.

In order to configure `vtgr`, you have to make the following changes to `vttablet`:

* Add `--db_flavor=MysqlGR`: This will allow vttablet to understand stats in group replication.
* Add `--disable_active_reparents=true`: This part will prevent vttablet from fixing replication, and will rely on vtgr instead.

`vtgr` requires two config files `vtgr_config` and `db_config` to be launched:

* `vtgr_config`: controls desired group parameters. A sample is available [here](https://github.com/vitessio/vitess/blob/main/go/vt/vtgr/config/vtgr_config.json).

`BootstrapGroupSize` configs the desired size of group. `vtgr` will only bootstrap a mysql group for a shard when it discovers desired number of healthy node from topology.

* `db_config`: controls connection parameters that `vtgr` uses. As an example:

```json
{
  "MySQLTopologyUser": "vtgr_user",
  "MySQLTopologyPassword": "vtgr_password",
  "MySQLReplicaUser": "vtgr_user",
  "MySQLReplicaPassword": "vtgr_password",
}
```

You can bring `vtgr` using the following invocation:

```sh
vtgr <topo_flags> \
  --log_dir=${VTDATAROOT}/tmp \
  --vtgr_config vtgr.json \
  --db_config db.json \
  --clusters_to_watch ks/0 \
 ```

Bringing up `vtgr` should immediately cause a primary to be elected among the vttablets that have come up.

You can optionally add a `clusters_to_watch` flag that contains a comma separated list of keyspaces or `keyspace/shard` values. If specified, `vtgr` will manage only those clusters.
