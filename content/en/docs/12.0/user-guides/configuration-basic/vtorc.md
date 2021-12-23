---
title: vtorc (experimental)
weight: 10
---

`vtorc` is a fork of the [Orchestrator](https://github.com/openark/orchestrator) customized to run as a Vitess component. It is available as an experimental feature. It still needs thorough testing, and more features need to be added.

In order to configure `vtorc`, you have to make the following changes to `vttablet`:

* Remove `-enable_semi_sync=true`: This part will be managed by vtorc instead.
* Add `-disable_active_reparents=true`: This part will prevent vttablet from fixing replication, and will rely on vtorc instead.

As mentioned before, bringing up `vtorc` also lets you avoid performing the `InitShardPrimary` step.

`vtorc` requires a config file to be launched. A sample is available [here](https://github.com/vitessio/vitess/blob/main/config/orchestrator/default.json):

```json
{
  "Debug": true,
  "MySQLTopologyUser": "orc_client_user",
  "MySQLTopologyPassword": "orc_client_user_password",
  "MySQLReplicaUser": "vt_repl",
  "MySQLReplicaPassword": "",
  "RecoveryPeriodBlockSeconds": 5
}
```

The `orc_client_user` and its password are in the `init_db.sql` file. It is highly recommended that you change the password to a more secure value. The same recommendation holds for the `vt_repl` user.

In production, you may also want to set “Debug” to false, and use a higher value for `RecoveryPeriodBlockSeconds` (default 3600).

You can bring `vtorc` using the following invocation:

```sh
vtorc <topo_flags> \
  -log_dir=${VTDATAROOT}/tmp \
  -config orc_config.json \
  -orc_web_dir ${VTROOT}/web/orchestrator
 ```
`orc_web_dir` must point at the contents of the orchestrator web files. The source can be found [here](https://github.com/vitessio/vitess/tree/main/web/orchestrator).

Bringing up `vtorc` should immediately cause a primary to be elected among the vttablets that have come up.

The `vtorc` config supports a new `Durability` setting that can currently be set to `none`, `semi_sync` or `cross_cell`. The `semi_sync` setting is the equivalent to setting the vttablet’s `enable_semi_sync` flag, whereas `cross_cell` will ensure that a primary will acknowledge a commit only if a `replica` that is not in the current cell has received the binary logs.

You can optionally add a `clusters_to_watch` flag that contains a comma separated list of keyspaces or `keyspace/shard` values. If specified, `vtorc` will manage only those clusters.

You can perform planned failovers using `vtorc`. Additionally, `vtorc` will also perform failure detection with automatic failovers while honoring the `Durability` rules.

Other Orchestrator settings may also be carefully added to the config. However, some of them may not be compatible with Vitess. These will be documented soon.
