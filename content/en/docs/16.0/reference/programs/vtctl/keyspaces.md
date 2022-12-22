---
title: vtctl Keyspace Command Reference
series: vtctl
docs_nav_title: Keyspaces
---

The following `vtctl` commands are available for administering Keyspaces.

## Commands

### CreateKeyspace

Creates the specified keyspace.

#### Example

<pre class="command-example">CreateKeyspace -- [--sharding_column_name=name] [--sharding_column_type=type] [--served_from=tablettype1:ks1,tablettype2,ks2,...] [--force] [--durability-policy=policy_name] &lt;keyspace name&gt;
Creates the specified keyspace. keyspace_type can be NORMAL or SNAPSHOT. For a SNAPSHOT keyspace you must specify the name of a base_keyspace, and a snapshot_time in UTC, in RFC3339 time format, e.g. 2006-01-02T15:04:05+00:00</pre>

#### Flags

| Name | Type | Definition |
| :-------- | :--------- | :--------- |
| force | Boolean | Proceeds even if the keyspace already exists |
| durability-policy | string | Specifies the [durability policy](../../../../user-guides/configuration-basic/durability_policy) to use for the keyspace |
| served_from | string | Specifies a comma-separated list of dbtype:keyspace pairs used to serve traffic |
| sharding_column_name | string | Specifies the column to use for sharding operations |
| sharding_column_type | string | Specifies the type of the column to use for sharding operations |


#### Arguments

* <code>&lt;keyspace name&gt;</code> &ndash; Required. The name of a sharded database that contains one or more tables. Vitess distributes keyspace shards into multiple machines and provides an SQL interface to query the data. The argument value must be a string that does not contain whitespace.

#### Errors

* the <code>&lt;keyspace name&gt;</code> argument is required for the <code>&lt;CreateKeyspace&gt;</code> command This error occurs if the command is not called with exactly one argument.

### DeleteKeyspace

Deletes the specified keyspace. In recursive mode, it also recursively deletes all shards in the keyspace. Otherwise, there must be no shards left in the keyspace.

#### Example

<pre class="command-example">DeleteKeyspace -- [--recursive] &lt;keyspace&gt;
Deletes the specified keyspace. In recursive mode, it also recursively deletes all shards in the keyspace. Otherwise, there must be no shards left in the keyspace.</pre>

#### Flags

| Name | Type | Definition |
| :-------- | :--------- | :--------- |
| recursive | Boolean | Also recursively delete all shards in the keyspace. |


#### Arguments

* <code>&lt;keyspace&gt;</code> &ndash; Required. The name of a sharded database that contains one or more tables. Vitess distributes keyspace shards into multiple machines and provides an SQL interface to query the data. The argument value must be a string that does not contain whitespace.

#### Errors

* must specify the <code>&lt;keyspace&gt;</code> argument for <code>&lt;DeleteKeyspace&gt;</code> This error occurs if the command is not called with exactly one argument.

### RemoveKeyspaceCell

Removes the cell from the Cells list for all shards in the keyspace, and the SrvKeyspace for that keyspace in that cell.

#### Example

<pre class="command-example">RemoveKeyspaceCell -- [--force] [--recursive] &lt;keyspace&gt; &lt;cell&gt;
Removes the cell from the Cells list for all shards in the keyspace, and the SrvKeyspace for that keyspace in that cell.</pre>

#### Flags

| Name | Type | Definition |
| :-------- | :--------- | :--------- |
| force | Boolean | Proceeds even if the cell's topology service cannot be reached. The assumption is that you turned down the entire cell, and just need to update the global topo data. |
| recursive | Boolean | Also delete all tablets in that cell belonging to the specified keyspace. |


#### Arguments

* <code>&lt;keyspace&gt;</code> &ndash; Required. The name of a sharded database that contains one or more tables. Vitess distributes keyspace shards into multiple machines and provides an SQL interface to query the data. The argument value must be a string that does not contain whitespace.
* <code>&lt;cell&gt;</code> &ndash; Required. A cell is a location for a service. Generally, a cell resides in only one cluster. In Vitess, the terms "cell" and "data center" are interchangeable. The argument value is a string that does not contain whitespace.

#### Errors

* the <code>&lt;keyspace&gt;</code> and <code>&lt;cell&gt;</code> arguments are required for the <code>&lt;RemoveKeyspaceCell&gt;</code> command This error occurs if the command is not called with exactly 2 arguments.

### GetKeyspace

Outputs a JSON structure that contains information about the Keyspace.

#### Example

<pre class="command-example">GetKeyspace &lt;keyspace&gt;
Outputs a JSON structure that contains information about the Keyspace.</pre>

#### Arguments

* <code>&lt;keyspace&gt;</code> &ndash; Required. The name of a sharded database that contains one or more tables. Vitess distributes keyspace shards into multiple machines and provides an SQL interface to query the data. The argument value must be a string that does not contain whitespace.

#### Errors

* the <code>&lt;keyspace&gt;</code> argument is required for the <code>&lt;GetKeyspace&gt;</code> command This error occurs if the command is not called with exactly one argument.

### GetKeyspaces

Outputs a sorted list of all keyspaces.

### RebuildKeyspaceGraph

Rebuilds the serving data for the keyspace. This command may trigger an update to all connected clients.

#### Example

<pre class="command-example">RebuildKeyspaceGraph -- [--cells=c1,c2,...] &lt;keyspace&gt; ...
Rebuilds the serving data for the keyspace. This command may trigger an update to all connected clients.</pre>

#### Flags

| Name | Type | Definition |
| :-------- | :--------- | :--------- |
| cells | string | Specifies a comma-separated list of cells to update |


#### Arguments

* <code>&lt;keyspace&gt;</code> &ndash; Required. The name of a sharded database that contains one or more tables. Vitess distributes keyspace shards into multiple machines and provides an SQL interface to query the data. The argument value must be a string that does not contain whitespace. To specify multiple values for this argument, separate individual values with a space.

#### Errors

* the <code>&lt;keyspace&gt;</code> argument must be used to specify at least one keyspace when calling the <code>&lt;RebuildKeyspaceGraph&gt;</code> command This error occurs if the command is not called with at least one argument.


### ValidateKeyspace

Validates that all nodes reachable from the specified keyspace are consistent.

#### Example

<pre class="command-example">ValidateKeyspace -- [--ping-tablets] &lt;keyspace name&gt;
Validates that all nodes reachable from the specified keyspace are consistent.</pre>

#### Flags

| Name | Type | Definition |
| :-------- | :--------- | :--------- |
| ping-tablets | Boolean | Specifies whether all tablets will be pinged during the validation process |


#### Arguments

* <code>&lt;keyspace name&gt;</code> &ndash; Required. The name of a sharded database that contains one or more tables. Vitess distributes keyspace shards into multiple machines and provides an SQL interface to query the data. The argument value must be a string that does not contain whitespace.

#### Errors

* the <code>&lt;keyspace name&gt;</code> argument is required for the <code>&lt;ValidateKeyspace&gt;</code> command This error occurs if the command is not called with exactly one argument.

### Reshard

```shell
Reshard <options> <action> <workflow identifier>
```

## MoveTables

```shell
MoveTables <options> <action> <workflow identifier>
```

### CreateLookupVindex

```shell
CreateLookupVindex  -- [--cells=<source_cells>] [--continue_after_copy_with_owner=false] [--tablet_types=<source_tablet_types>] <keyspace> <json_spec>
Create and backfill a lookup vindex. the json_spec must contain the vindex and colvindex specs for the new lookup.
```

### ExternalizeVindex

```shell
ExternalizeVindex  <keyspace>.<vindex>
Externalize (activate) a lookup vindex backfilled using `CreateLookupVindex`.
This removes the workflow and vreplication streams associated with the
backfill, and clears the `write_only` flag on the vindex. After this flag is
removed, applications can start using the vindex for lookups.
```

### Materialize

```shell
Materialize  <json_spec>, example : '{"workflow": "aaa", "source_keyspace": "source", "target_keyspace": "target", "table_settings": [{"target_table": "customer", "source_expression": "select * from customer", "create_ddl": "copy"}]}'
Performs materialization based on the json spec. Is used directly to form VReplication rules, with an optional step to copy table structure/DDL.
```

### VDiff

```shell
VDiff  -- [--source_cell=<cell>] [--target_cell=<cell>] [--tablet_types=<source_tablet_types>] [--filtered_replication_wait_time=30s] [--max_extra_rows_to_compare=1000] <keyspace.workflow>
Perform a diff of all tables in the workflow
```

### FindAllShardsInKeyspace

Displays all of the shards in the specified keyspace.

#### Example

<pre class="command-example">FindAllShardsInKeyspace &lt;keyspace&gt;
Displays all of the shards in the specified keyspace.</pre>

#### Arguments

* <code>&lt;keyspace&gt;</code> &ndash; Required. The name of a sharded database that contains one or more tables. Vitess distributes keyspace shards into multiple machines and provides an SQL interface to query the data. The argument value must be a string that does not contain whitespace.

#### Errors

* the <code>&lt;keyspace&gt;</code> argument is required for the <code>&lt;FindAllShardsInKeyspace&gt;</code> command This error occurs if the command is not called with exactly one argument.


## See Also

* [vtctl command index](../../vtctl)
