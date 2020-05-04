---
title: vtctl Schema, Version, Permissions Command Reference
series: vtctl
---

The following `vtctl` commands are available for administering Schema, Versions and Permissions.

## Commands

### GetSchema

`GetSchema  [-tables=<table1>,<table2>,...] [-exclude_tables=<table1>,<table2>,...] [-include-views] <tablet alias>`

### ReloadSchema

`ReloadSchema  <tablet alias>`

### ReloadSchemaShard

`ReloadSchemaShard  [-concurrency=10] [-include_master=false] <keyspace/shard>`

### ReloadSchemaKeyspace

`ReloadSchemaKeyspace  [-concurrency=10] [-include_master=false] <keyspace>`

### ValidateSchemaShard

`ValidateSchemaShard  [-exclude_tables=''] [-include-views] <keyspace/shard>`

### ValidateSchemaKeyspace

`ValidateSchemaKeyspace  [-exclude_tables=''] [-include-views] <keyspace name>`

### ApplySchema

`ApplySchema  [-allow_long_unavailability] [-wait_slave_timeout=10s] {-sql=<sql>
| -sql-file=<filename>} <keyspace>`

### CopySchemaShard

`CopySchemaShard  [-tables=<table1>,<table2>,...] [-exclude_tables=<table1>,<table2>,...] [-include-views] [-skip-verify] [-wait_slave_timeout=10s] {<source keyspace/shard>
| <source tablet alias>} <destination keyspace/shard>`

### ValidateVersionShard

`ValidateVersionShard  <keyspace/shard>`

### ValidateVersionKeyspace

`ValidateVersionKeyspace  <keyspace name>`

### GetPermissions

`GetPermissions  <tablet alias>`

### ValidatePermissionsShard

`ValidatePermissionsShard  <keyspace/shard>`

### ValidatePermissionsKeyspace

`ValidatePermissionsKeyspace  <keyspace name>`

### GetVSchema

`GetVSchema  <keyspace>`

### ApplyVSchema

`ApplyVSchema  {-vschema=<vschema>
| -vschema_file=<vschema file>
| -sql=<sql>
| -sql_file=<sql file>} [-cells=c1,c2,...] [-skip_rebuild] [-dry-run] <keyspace>`

### GetRoutingRules

`GetRoutingRules  `

### ApplyRoutingRules

`ApplyRoutingRules  {-rules=<rules>
| -rules_file=<rules_file>} [-cells=c1,c2,...] [-skip_rebuild] [-dry-run]`

### RebuildVSchemaGraph

`RebuildVSchemaGraph  [-cells=c1,c2,...]`

## See Also

* [vtctl command index](../../vtctl)
