---
title: vtctl Topo Command Reference
series: vtctl
docs_nav_title: Topology Service
---

The following `vtctl` commands are available for administering Topology Services.

## Commands

### TopoCat

Retrieves the file(s) at &lt;path&gt; from the topo service, and displays it. It can resolve wildcards, and decode the proto-encoded data.

#### Example

<pre class="command-example">TopoCat -- [--cell &lt;cell&gt;] [--decode_proto] [--long] &lt;path&gt; [&lt;path&gt;...]</pre>

#### Flags

| Name | Type | Definition                                                      |
| :-------- | :--------- |:----------------------------------------------------------------|
| cell | string | topology cell to cat the file from. Defaults to global cell.    |
| decode_proto | Boolean | decode proto files and display them as text. Defaults to false. |
| decode_proto_json | Boolean | decode proto files and display them as json. Defaults to false. |
| long | Boolean | long listing. Defaults to false.                                |


#### Arguments

* <code>&lt;cell&gt;</code> &ndash; Required. A cell is a location for a service. Generally, a cell resides in only one cluster. In Vitess, the terms "cell" and "data center" are interchangeable. The argument value is a string that does not contain whitespace.
* <code>&lt;path&gt;</code> &ndash; Required.
* <code>&lt;path&gt;</code>. &ndash; Optional.

#### Errors

* <code>&lt;TopoCat&gt;</code>: no path specified. This error occurs if the command is not called with at least one argument.
* <code>&lt;TopoCat&gt;</code>: invalid wildcards. If you send paths that don't contain any wildcard and don't exist.
* <code>&lt;TopoCat&gt;</code>: some paths had errors. If there is an error getting node data for given paths.

### TopoCp

Copy data at given path from topo service to local file or vice versa.

#### Example

<pre class="command-example">TopoCp -- [--cell &lt;cell&gt;] [--to_topo] &lt;src&gt; &lt;dst&gt; </pre>

#### Flags

| Name | Type | Definition                                      |
| :-------- | :--------- |:------------------------------------------------|
| cell | string | topology cell to use for the copy. Defaults to global cell. |
| to_topo | Boolean | copies from local server to topo instead (reverse direction). Defaults to false. |

#### Arguments

* <code>&lt;cell&gt;</code> &ndash; Required. A cell is a location for a service. Generally, a cell resides in only one cluster. In Vitess, the terms "cell" and "data center" are interchangeable. The argument value is a string that does not contain whitespace.
* <code>&lt;src&gt;</code> &ndash; Required. Source from which data needs to be copied. It can be local file or some path in topo service, depedning on if `to_topo` is specified.
* <code>&lt;dst&gt;</code>. &ndash; Required. Destination to which data will be copied. It can be local file or some path in topo service, depedning on if `to_topo` is specified.

#### Errors

* <code>&lt;TopoCp&gt;</code>: need source and destination. This error occurs if the command is not called with proper `src` and `dst`.


## See Also

* [vtctl command index](../../vtctl)
