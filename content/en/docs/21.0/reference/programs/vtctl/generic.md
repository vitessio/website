---
title: vtctl Generic Command Reference
series: vtctl
docs_nav_title: Generic Commands
---

The following generic `vtctl` commands are available for administering Vitess.

## Commands

### Validate

Validates that all nodes reachable from the global replication graph and that all tablets in all discoverable cells are consistent.

#### Example

<pre class="command-example">Validate -- [--ping-tablets]</pre>

#### Flags

| Name | Type | Definition |
| :-------- | :--------- | :--------- |
| ping-tablets | Boolean | Indicates whether all tablets should be pinged during the validation process |

### ListAllTablets

Lists all tablets in an awk-friendly way.

#### Example

<pre class="command-example">ListAllTablets -- [--keyspace=''] [--tablet_type=&lt;primary,replica,rdonly,spare&gt;] [&lt;cell_name1&gt;,&lt;cell_name2&gt;,...]</pre>

#### Arguments

* <code>&lt;cell_name&gt;</code> &ndash; Optional. A cell is a location for a service. Generally, a cell resides in only one cluster. In Vitess, the terms "cell" and "data center" are interchangeable. The argument value is a string that does not contain whitespace. This allows you to request server side filtering to exlude tablets in cells not explicitly specified.

#### Flags

| Name | Type | Definition |
| :-------- | :--------- | :---------- |
| keyspace | string | (Optional) A keyspace is a logical database. This allows you to request server side filtering to exlude tablets not in this keyspace. |
| tablet_type | string | (Optional) A tablet type is one of PRIMARY,REPLICA,RDONLY,SPARE. This allows you to request server side filtering to exlude tablets not of this type. |

#### Errors

* An error will be returned if you specify a non-existent cell or an invalid tablet type.

### ListTablets

Lists specified tablets in an awk-friendly way.

#### Example

<pre class="command-example">ListTablets &lt;tablet alias&gt; ...</pre>

#### Arguments

* <code>&lt;tablet alias&gt;</code> &ndash; Required. A Tablet Alias uniquely identifies a vttablet. The argument value is in the format <code>&lt;cell name&gt;-&lt;uid&gt;</code>. To specify multiple values for this argument, separate individual values with a space.

#### Errors

* the <code>&lt;tablet alias&gt;</code> argument is required for the <code>&lt;ListTablets&gt;</code> command This error occurs if the command is not called with at least one argument.

### GenerateShardRanges

Generates shard ranges assuming a keyspace with N shards.

#### Example

<pre class="command-example">GenerateShardRanges -- [--num_shards 2]</pre>

#### Flags

| Name | Type    | Definition |
| :-------- |:--------| :---------- |
| num_shards | Integer | Number of shards to generate shard ranges for. (default 2) |

### Help

Provides help for a command.

#### Example

```
Help [command name]
```

## See Also

* [vtctl command index](../../vtctl)
