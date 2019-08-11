---
title: Queries
description: Frequently Asked Questions about Queries
---


## Can I address a specific shard if I want to?

If necessary, you can access a specific shard by connecting to it using the shard specific database name. For a keyspace ks and shard -80, you would connect to ks:-80.

## How do I choose between master vs. replica for queries?

You can qualify the keyspace name with the desired tablet type using the @ suffix. This can be specified as part of the connection as the database name, or can be changed on the fly through the USE command.

For example, `ks@master` will select `ks` as the default keyspace with all queries being sent to the master. Consequently `ks@replica` will load balance requests across all `REPLICA` tablet types, and `ks@rdonly` will choose `RDONLY`.

You can also specify the database name as `@master`, etc, which instructs Vitess that no default keyspace was specified, but that the requests are for the specified tablet type.

If no tablet type was specified, then VTGate chooses its default, which can be overridden with the `-default_tablet_type` command line argument.

## There seems to be a 10 000 row limit per query. What if I want to do a full table scan?

Vitess supports different modes. In OLTP mode, the result size is typically limited to a preset number (10 000 rows by default). This limit can be adjusted based on your needs.

However, OLAP mode has no limit to the number of rows returned. In order to change to this mode, you may issue the following command before executing your query:

```shell
set workload='olap'
```
You can also set the workload to `dba mode`, which allows you to override the implicit timeouts that exist in vttablet. However, this mode should be used judiciously as it supersedes shutdown and reparent commands.

The general convention is to send OLTP queries to `REPLICA` tablet types, and OLAP queries to `RDONLY`.

## Is there a list of supported/unsupported queries?

The list of unsupported constructs is currently in the form of test cases contained in [this test file](https://github.com/vitessio/vitess/blob/b2b3aeb7cf5316eeedbe667fecaa91b1c34a6cea/go/vt/vtgate/planbuilder/testdata/unsupported_cases.txt). However, contrary to the test cases, there is limited support for SET, DDL and DBA constructs. This will be documented in greater detail soon. Until then, [this test file](https://github.com/vitessio/vitess/blob/b2b3aeb7cf5316eeedbe667fecaa91b1c34a6cea/go/vt/vtgate/planbuilder/testdata/unsupported_cases.txt) serves as the canonical source of information on unsupported queries. Do also check on the [Vitess Slack channel](https://vitess.slack.com) (click [here](https://vitess.slack.com/join/shared_invite/enQtMzIxMDMyMzA0NzA1LTBjYjY1M2I2Yjg5YmY3ODIwOTk0N2M1YzI4Y2ViODdiNmIxMDdiMDM5YWQ1ZTc0YmJhZDdiOTliMGVkNDY4MjM) to join) to ask our friendly community about other queries you have in mind. 

## If I have a log of all queries from my app. Is there a way I can try them against Vitess to see how they’ll work?

Yes. The [vtexplain](../vtexplain) tool can be used to preview how your queries will be executed by Vitess. It can also be used to try different sharding scenarios before deciding on one.
