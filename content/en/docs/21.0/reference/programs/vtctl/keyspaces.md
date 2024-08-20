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

<pre class="command-example">CreateKeyspace -- [--sharding_column_name=name] [--sharding_column_type=type] [--served_from=tablettype1:ks1,tablettype2:ks2,...] [--force] [--keyspace_type=type] [--base_keyspace=base_keyspace] [--snapshot_time=time] [--durability-policy=policy_name] [--sidecar-db-name=db_name] &lt;keyspace name&gt; </pre>

#### Flags

| Name                 | Type    | Definition                                                                                                                                                                                                                 |
|:---------------------|:--------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| allow_empty_vschema  | Boolean | If set this will allow a new keyspace to have no vschema                                                                                                                                                                   |
| base_keyspace        | Boolean | Specifies the base keyspace for a snapshot keyspace type                                                                                                                                                                   |
| durability-policy    | String  | Specifies the [durability policy](../../../../user-guides/configuration-basic/durability_policy) to use for the keyspace                                                                                                   |
| force                | Boolean | Proceeds even if the keyspace already exists                                                                                                                                                                               |
| keyspace_type        | String  | Specifies the type of the keyspace. It can be NORMAL or SNAPSHOT. For a SNAPSHOT keyspace you must specify the name of a base_keyspace, and a snapshot_time in UTC, in RFC3339 time format, e.g. 2006-01-02T15:04:05+00:00 |
| sharding_column_name | String  | Specifies the column to use for sharding operations                                                                                                                                                                        |
| sharding_column_type | String  | Specifies the type of the column to use for sharding operations                                                                                                                                                            |
| sidecar-db-name      | String  | (Experimental) Specifies the name of the Vitess sidecar database that tablets in this keyspace will use for internal metadata                                                                                              |
| served_from          | String  | Specifies a comma-separated list of dbtype:keyspace pairs used to serve traffic                                                                                                                                            |
| snapshot_time        | String  | Specifies the snapshot time for this keyspace                                                                                                                                                                              |


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

<pre class="command-example">RebuildKeyspaceGraph -- [--cells=c1,c2,...] [--allow_partial] &lt;keyspace&gt; ...
Rebuilds the serving data for the keyspace. This command may trigger an update to all connected clients.</pre>

#### Flags

| Name          | Type    | Definition                                                                                                                           |
|:--------------|:--------|:-------------------------------------------------------------------------------------------------------------------------------------|
| allow_partial | Boolean | Specifies whether a SNAPSHOT keyspace is allowed to serve with an incomplete set of shards. Ignored for all other types of keyspaces |
| cells         | String  | Specifies a comma-separated list of cells to update                                                                                  |

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


### FindAllShardsInKeyspace

Displays all of the shards in the specified keyspace.

#### Example

<pre class="command-example">FindAllShardsInKeyspace &lt;keyspace&gt;
Displays all of the shards in the specified keyspace.</pre>

#### Arguments

* <code>&lt;keyspace&gt;</code> &ndash; Required. The name of a sharded database that contains one or more tables. Vitess distributes keyspace shards into multiple machines and provides an SQL interface to query the data. The argument value must be a string that does not contain whitespace.

#### Errors

* the <code>&lt;keyspace&gt;</code> argument is required for the <code>&lt;FindAllShardsInKeyspace&gt;</code> command This error occurs if the command is not called with exactly one argument.


### Reshard

Start a Resharding process. Example: Reshard --cells='zone1,alias1' --tablet_types='PRIMARY,REPLICA,RDONLY'  ks.workflow001 -- '0' '-80,80-'

#### Example

<pre class="command-example">Reshard -- [--source_shards=&lt;source_shards>] [--target_shards=&lt;target_shards>] [--cells=&lt;cells&gt;] [--tablet_types=&lt;source_tablet_types&gt;] [--on-ddl=&lt;ddl-action&gt;] [--skip_schema_copy] &lt;action&gt; &lt;keyspace.workflow&gt; </pre>

#### Flags

| Name                        | Type     | Definition                                                                                                                                                                                                                                                                                                                                                        |
|:----------------------------|:---------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| all                         | Boolean  | MoveTables only. Move all tables from the source keyspace. Either table_specs or --all needs to be specified.                                                                                                                                                                                                                                                     |
| auto_start                  | Boolean  | If false, streams will start in the Stopped state and will need to be explicitly started (default true)                                                                                                                                                                                                                                                           |
| cells                       | String   | Cell(s) or CellAlias(es) (comma-separated) to replicate from.                                                                                                                                                                                                                                                                                                     |
| drop_foreign_keys           | Boolean  | If true, tables in the target keyspace will be created without foreign keys.                                                                                                                                                                                                                                                                                      |
| dry_run                     | Boolean  | Does a dry run of SwitchTraffic and only reports the actions to be taken. --dry_run is only supported for SwitchTraffic, ReverseTraffic and Complete.                                                                                                                                                                                                             |
| exclude                     | String   | MoveTables only. Tables to exclude (comma-separated) if --all is specified                                                                                                                                                                                                                                                                                        |
| keep_data                   | Boolean  | Do not drop tables or shards (if true, only vreplication artifacts are cleaned up).  --keep_data is only supported for Complete and Cancel.                                                                                                                                                                                                                       |
| keep_routing_rules          | Boolean  | Do not remove the routing rules for the source keyspace.  --keep_routing_rules is only supported for Complete and Cancel.                                                                                                                                                                                                                                         |
| max_replication_lag_allowed | Duration | Allow traffic to be switched only if vreplication lag is below this (in seconds) (default 30s)                                                                                                                                                                                                                                                                    |
| on-ddl                      | String   | What to do when DDL is encountered in the VReplication stream. Possible values are IGNORE, STOP, EXEC, and EXEC_IGNORE. (default "IGNORE")                                                                                                                                                                                                                        |
| rename_tables               | Boolean  | MoveTables only. Rename tables instead of dropping them. --rename_tables is only supported for Complete.                                                                                                                                                                                                                                                          |
| reverse_replication         | Boolean  | Also reverse the replication (default true). --reverse_replication is only supported for SwitchTraffic. (default true)                                                                                                                                                                                                                                            |
| skip_schema_copy            | Boolean  | Reshard only. Skip copying of schema to target shards                                                                                                                                                                                                                                                                                                             |
| source                      | String   | MoveTables only. Source keyspace                                                                                                                                                                                                                                                                                                                                  |
| source_shards               | String   | Source shards                                                                                                                                                                                                                                                                                                                                                     |
| source_time_zone            | String   | MoveTables only. Specifying this causes any DATETIME fields to be converted from given time zone into UTC                                                                                                                                                                                                                                                         |
| stop_after_copy             | Boolean  | Streams will be stopped once the copy phase is completed                                                                                                                                                                                                                                                                                                          |
| tables                      | String   | MoveTables only. A table spec or a list of tables. Either table_specs or --all needs to be specified.                                                                                                                                                                                                                                                             |
| tablet_types                | String   | Source tablet types to replicate from (e.g. PRIMARY, REPLICA, RDONLY). Note: SwitchTraffic overrides this default and uses in_order:RDONLY,REPLICA,PRIMARY to switch all traffic by default. (default "in_order:REPLICA,PRIMARY") |
| target_shards               | String   | Reshard only. Target shards                                                                                                                                                                                                                                                                                                                                       |
| timeout                     | Duration | Specifies the maximum time to wait, in seconds, for vreplication to catch up on primary migrations. The migration will be cancelled on a timeout. --timeout is only supported for SwitchTraffic and ReverseTraffic. (default 30s)                                                                                                                                 |

#### Arguments

* &lt;action&gt; - Required. Action must be one of the following: Create, Complete, Cancel, SwitchTraffic, ReverseTrafffic, Show, or Progress.
* &lt;keyspace.workflow&gt; - Required. The name of the keyspace and workflow to be used for the resharding process. The argument value must be a string that does not contain whitespace.


### MoveTables

Move table(s) to another keyspace, table_specs is a list of tables or the tables section of the vschema for the target keyspace. 
Example: 
```json
{
  "t1": {"column_vindexes": [{"column": "id1", "name": "hash"}]}, 
  "t2": {"column_vindexes": [{"column": "id2", "name": "hash"}]}
}
```  

In the case of an unsharded target keyspace the vschema for each table may be empty. 
Example: 
```json
{
  "t1":{}, 
  "t2":{}
}
```

#### Example

<pre class="command-example">MoveTables [--source=&lt;sourceKs&gt;] [--tables=&lt;tableSpecs&gt;] [--cells=&lt;cells&gt;] [--tablet_types=&lt;source_tablet_types&gt;] [--all] [--exclude=&lt;tables&gt;] [--auto_start] [--stop_after_copy] [--on-ddl=&lt;ddl-action&gt;] [--source_shards=&lt;source_shards&gt;] &lt;action&gt; &lt;targetKs.workflow&gt; </pre>

#### Flags

| Name                        | Type     | Definition                                                                                                                                                                                                                                                                                                                                                        |
|:----------------------------|:---------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| all                         | Boolean  | MoveTables only. Move all tables from the source keyspace. Either table_specs or --all needs to be specified.                                                                                                                                                                                                                                                     |
| auto_start                  | Boolean  | If false, streams will start in the Stopped state and will need to be explicitly started (default true)                                                                                                                                                                                                                                                           |
| cells                       | String   | Cell(s) or CellAlias(es) (comma-separated) to replicate from.                                                                                                                                                                                                                                                                                                     |
| drop_foreign_keys           | Boolean  | If true, tables in the target keyspace will be created without foreign keys.                                                                                                                                                                                                                                                                                      |
| dry_run                     | Boolean  | Does a dry run of SwitchTraffic and only reports the actions to be taken. --dry_run is only supported for SwitchTraffic, ReverseTraffic and Complete.                                                                                                                                                                                                             |
| exclude                     | String   | MoveTables only. Tables to exclude (comma-separated) if --all is specified                                                                                                                                                                                                                                                                                        |
| keep_data                   | Boolean  | Do not drop tables or shards (if true, only vreplication artifacts are cleaned up).  --keep_data is only supported for Complete and Cancel.                                                                                                                                                                                                                       |
| keep_routing_rules          | Boolean  | Do not remove the routing rules for the source keyspace.  --keep_routing_rules is only supported for Complete and Cancel.                                                                                                                                                                                                                                         |
| max_replication_lag_allowed | Duration | Allow traffic to be switched only if vreplication lag is below this (in seconds) (default 30s)                                                                                                                                                                                                                                                                    |
| on-ddl                      | String   | What to do when DDL is encountered in the VReplication stream. Possible values are IGNORE, STOP, EXEC, and EXEC_IGNORE. (default "IGNORE")                                                                                                                                                                                                                        |
| rename_tables               | Boolean  | MoveTables only. Rename tables instead of dropping them. --rename_tables is only supported for Complete.                                                                                                                                                                                                                                                          |
| reverse_replication         | Boolean  | Also reverse the replication (default true). --reverse_replication is only supported for SwitchTraffic. (default true)                                                                                                                                                                                                                                            |
| skip_schema_copy            | Boolean  | Reshard only. Skip copying of schema to target shards                                                                                                                                                                                                                                                                                                             |
| source                      | String   | MoveTables only. Source keyspace                                                                                                                                                                                                                                                                                                                                  |
| source_shards               | String   | Source shards                                                                                                                                                                                                                                                                                                                                                     |
| source_time_zone            | String   | MoveTables only. Specifying this causes any DATETIME fields to be converted from given time zone into UTC                                                                                                                                                                                                                                                         |
| stop_after_copy             | Boolean  | Streams will be stopped once the copy phase is completed                                                                                                                                                                                                                                                                                                          |
| tables                      | String   | MoveTables only. A table spec or a list of tables. Either table_specs or --all needs to be specified.                                                                                                                                                                                                                                                             |
| tablet_types                | String   | Source tablet types to replicate from (e.g. PRIMARY, REPLICA, RDONLY). Note: SwitchTraffic overrides this default and uses in_order:RDONLY,REPLICA,PRIMARY to switch all traffic by default. (default "in_order:REPLICA,PRIMARY") |
| target_shards               | String   | Reshard only. Target shards                                                                                                                                                                                                                                                                                                                                       |
| timeout                     | Duration | Specifies the maximum time to wait, in seconds, for vreplication to catch up on primary migrations. The migration will be cancelled on a timeout. --timeout is only supported for SwitchTraffic and ReverseTraffic. (default 30s)                                                                                                                                 |


#### Arguments

* &lt;action&gt; - Required. Action must be one of the following: Create, Complete, Cancel, SwitchTraffic, ReverseTrafffic, Show, or Progress.
* &lt;keyspace.workflow&gt; - Required. The name of the keyspace and workflow to be used for the resharding process. The argument value must be a string that does not contain whitespace.


### CreateLookupVindex

Create and backfill a lookup vindex. the json_spec must contain the vindex and colvindex specs for the new lookup.

#### Example

<pre class="command-example">
CreateLookupVindex  -- [--cells=&lt;source_cells&gt;] [--continue_after_copy_with_owner=false] [--tablet_types=&lt;source_tablet_types&gt;] &lt;keyspace&gt; &lt;json_spec&gt;
Create and backfill a lookup vindex. the json_spec must contain the vindex and colvindex specs for the new lookup.
</pre>

### Flags

| Name                           | Type    | Definition                                                                |
|:-------------------------------|:--------|:--------------------------------------------------------------------------|
| cells                          | String  | Source cells to replicate from.                                           |
| continue_after_copy_with_owner | Boolean | Vindex will continue materialization after copy when an owner is provided |
| tablet_types                   | String  | Source tablet types to replicate from.                                    |

### Arguments

* &lt;keyspace&gt; - Required. The name of the keyspace where lookup vindex needs to be created.
* &lt;json_spec&gt; - Required. json specification about how to create the lookup vindex. More information in [user-guides](../../../../user-guides/configuration-advanced/createlookupvindex)


### ExternalizeVindex

Externalize (activate) a lookup vindex backfilled using `CreateLookupVindex`.

This removes the workflow and vreplication streams associated with the
backfill, and clears the `write_only` flag on the vindex. After this flag is
removed, applications can start using the vindex for lookups.

#### Example

<pre class="command-example">
ExternalizeVindex &lt;keyspace&gt;.&lt;vindex&gt;
</pre>

### Materialize

Performs materialization based on the json spec. Is used directly to form VReplication rules, with an optional step to copy table structure/DDL.

#### Example

<pre class="command-example">
Materialize -- [--cells=&lt;cells&gt;] [--tablet_types=&lt;source_tablet_types&gt;] &lt;json_spec&gt;
</pre>

#### Flags

| Name         | Type   | Definition                             |
|:-------------|:-------|:---------------------------------------|
| cells        | String | Source cells to replicate from.        |
| tablet_types | String | Source tablet types to replicate from. |


#### Argument

* <json_spec> - Required.

Example:
```json
{
  "workflow": "aaa", 
  "source_keyspace": "source", 
  "target_keyspace": "target", 
  "table_settings": [{
    "target_table": "customer", 
    "source_expression": "select * from customer", 
    "create_ddl": "copy"}]
}
```

### `VDiff`

Perform a diff of all tables in the workflow

#### Example

<pre class="command-example">
VDiff -- [--source_cell=&lt;cell&gt;] [--target_cell=&lt;cell&gt;] [--tablet_types=in_order:RDONLY,REPLICA,PRIMARY] [--limit=&lt;max rows to diff&gt;] [--tables=&lt;table list&gt;] [--format=json] [--auto-retry] [--verbose] [--max_extra_rows_to_compare=1000] [--filtered_replication_wait_time=30s] [--debug_query] [--only_pks] [--wait] [--wait-update-interval=1m] &lt;keyspace.workflow&gt; [&lt;action&gt;] [&lt;UUID&gt;]
</pre>

#### Flags

| Name         | Type   | Definition                             |
|:-------------|:-------|:---------------------------------------|
| auto-retry | Boolean | Should this vdiff automatically retry and continue in case of recoverable errors (default true) |
| checksum  | Boolean | Use row-level checksums to compare, not yet implemented |
| debug_query | Boolean | Adds a mysql query to the report that can be used for further debugging |
| filtered_replication_wait_time | Duration | Specifies the maximum time to wait, in seconds, for filtered replication to catch up on primary migrations. The migration will be cancelled on a timeout. (default 30s) |
| format | String | Format of report (default "text") |
| limit | Int | Max rows to stop comparing after (default 9223372036854775807) |
| max_extra_rows_to_compare | Int | If there are collation differences between the source and target, you can have rows that are identical but simply returned in a different order from MySQL. We will do a second pass to compare the rows for any actual differences in this case and this flag allows you to control the resources used for this operation. (default 1000) |
| only_pks | Boolean | When reporting missing rows, only show primary keys in the report. |
| sample_pct | Int | How many rows to sample, not yet implemented (default 100) |
| source_cell | String | The source cell to compare from; default is any available cell |
| tables | String | Only run vdiff for these tables in the workflow |
| tablet_types | String | Tablet types for source (PRIMARY is always used on target) (default "in_order:RDONLY,REPLICA,PRIMARY") |
| target_cell | String | The target cell to compare with; default is any available cell |
| v1 | Boolean | Use legacy VDiff v1 |
| verbose | Boolean | Show verbose vdiff output in summaries |
| wait | Boolean | When creating or resuming a vdiff, wait for it to finish before exiting |
| wait-update-interval | Duration |When waiting on a vdiff to finish, check and display the current status this often (default 1m0s) |

## See Also

* [vtctl command index](../../vtctl)
