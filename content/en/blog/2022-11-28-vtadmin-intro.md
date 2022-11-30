---
author: 'Frances Thai'
date: 2022-11-28
slug: '2022-11-28-vtadmin-intro'
tags: ['Vitess','VTAdmin','vtctld','vtctld2']
title: 'Introducing VTAdmin'
description: "Vitess's cluster management API and UI"
---

[VTAdmin](https://vitess.io/docs/reference/vtadmin/) is now generally available for use! VTAdmin provides both a web client and API for managing multiple Vitess clusters, and is the successor to the now-deprecated UI for [vtctld](https://vitess.io/docs/reference/programs/vtctld/).

## What is VTAdmin?
VTAdmin is made up of two components: 
- VTAdmin API: An HTTP(S) and gRPC API server
- VTAdmin Web: A React + Typescript web client built with [Create React App](https://create-react-app.dev/)

## What can you do with VTAdmin?
VTAdmin can do everything the old vtctld2 UI could do, now that the [vtctld2 parity project](https://github.com/vitessio/vitess/projects/13) has been completed. For a complete list of supported API methods, refer [here](https://github.com/vitessio/vitess/blob/main/go/vt/vtadmin/api.go#L332).

The following are just a few examples of what VTAdmin can do!
### Tablet Management
VTAdmin provides a variety of Tablet management tools - from starting and stopping replication, setting to read/write, reparenting, deleting, pinging, refreshing Tablets to experimental features like tablet and VReplication QPS. 
<img src="/files/2022-11-28-vtadmin-intro/tablets.gif" alt="GIF of tablets features in VTAdmin Web"/>

_Note: To use experimental features, make sure to set `REACT_APP_ENABLE_EXPERIMENTAL_TABLET_DEBUG_VARS` in VTAdmin Web and `--http-tablet-url-tmpl` in VTAdmin API, as experimental tablet features work by making an HTTP call to the VTTablets._

### Keyspace Management
In VTAdmin, keyspace actions like validate keyspace/schema/version, reloading schemas, rebuilding keyspace graphs and cells, and creating new shards are made easy.
<img src="/files/2022-11-28-vtadmin-intro/keyspaces.gif" alt="GIF of keyspace features in VTAdmin Web"/>

## Workflow Management
VTAdmin also allows you to view all your workflows and monitor workflow streams.
<img src="/files/2022-11-28-vtadmin-intro/workflows.gif" alt="GIF of workflow features in VTAdmin Web"/>

### Topology
The old topology browser in vtctld2 has also been reimagined into a graph-traversal UI, that allows you to explore topology across single and multi-cluster deployments.
<img src="/files/2022-11-28-vtadmin-intro/topology.gif" alt="GIF of topology in VTAdmin Web"/>

### Role-based access control
VTAdmin also supports role-based access control (RBAC). This allows you to restrict access to, and actions on certain resources to a subset of users for an added layer of security. For more information on how to configure RBAC in VTAdmin, refer to our documentation [here](https://vitess.io/docs/15.0/reference/vtadmin/role-based-access-control/).

## How does VTAdmin work?
VTAdmin Web is a web client that queries data from VTAdmin API via HTTP protocol. VTAdmin API in turn, is a mostly stateless API server that fetches data from VTGates and Vtctlds via gRPC. It returns this data to the frontend, VTAdmin Web. In a multi-cluster environment, that might look like:
<img src="/files/2022-11-28-vtadmin-intro/architecture.png" alt="Architecture diagram for VTAdmin API and Web"/>

### Lifecycle of a Request
_This is taken from the VTAdmin architecture doc [here](https://vitess.io/docs/reference/vtadmin/architecture/)_.

As an example, take the `/schemas` page in VTAdmin Web:
<img src="/files/2022-11-28-vtadmin-intro/schemas.png" alt="The /schemas page in VTAdmin Web"/>

When a user loads the `/schemas` page in the browser, VTAdmin Web makes an HTTP `GET` `/api/schema/local/commerce/corder` request to VTAdmin API. VTAdmin API then issues gRPC requests to the vtgates and vtctlds in the cluster to construct the list of schemas. Here's what that looks like in detail:
<img src="/files/2022-11-28-vtadmin-intro/requests.png" alt="Lifecycle of a request to the /schemas page in VTAdmin"/>

### Cluster configuration and discovery
VTAdmin manages to be stateless because it mostly proxies queries to VTGates and Vtctlds within Vitess clusters. It is able to do this through **cluster discovery**, the mechanism by which addresses for VTGates and Vtctlds are discovered.

Discovery is specified as a part of [cluster configuration](https://github.com/vitessio/vitess/blob/main/doc/vtadmin/clusters.yaml). Cluster configuration is passed as the command line argument `--cluster` to VTAdmin API like so:
```bash
vtadmin \
  --addr ":14200" \
  --http-origin "http://localhost:14201" \
  --http-tablet-url-tmpl "http://{{ .Tablet.Hostname }}:15{{ .Tablet.Alias.Uid }}" \
  --tracer "opentracing-jaeger" \
  --grpc-tracing \
  --http-tracing \
  --logtostderr \
  --alsologtostderr \
  --rbac \
  --rbac-config="./vtadmin/rbac.yaml" \
  --cluster "id=local,name=local,discovery=staticfile,discovery-staticfile-path=./vtadmin/discovery.json,tablet-fqdn-tmpl={{ .Tablet.Hostname }}:15{{ .Tablet.Alias.Uid }}"
```
where, in this example, `discovery=staticfile` is specifying static file discovery.

VTAdmin API currently supports a few methods for discovery:
#### Consul discovery
With **Consul discovery**, VTGate and Vtctld addresses are discovered via requests to [Consul](https://www.consul.io/). For a full list of supported flags for Consul discovery, refer [here](https://github.com/vitessio/vitess/blob/main/go/vt/vtadmin/cluster/discovery/discovery_consul.go#L83-L118), or refer to the [test examples](https://github.com/vitessio/vitess/blob/main/go/vt/vtadmin/cluster/discovery/discovery_consul_test.go#L102-L110).

#### Static file discovery
With **static file discovery**, VTGate and Vtctld addresses are specified in a static file, whose path is provided as a parameter to the `--cluster` command line argument:
```bash
  --cluster "id=local,name=local,discovery=staticfile,discovery-staticfile-path=./vtadmin/discovery.json,tablet-fqdn-tmpl={{ .Tablet.Hostname }}:15{{ .Tablet.Alias.Uid }}"
```

In this example, the file lives at `./vtadmin/discovery.json`, and might look like:

```json
{
    "vtctlds": [
        {
            "host": {
                "fqdn": "localhost:15000",
                "hostname": "localhost:15999"
            }
        }
    ],
    "vtgates": [
        {
            "host": {
                "fqdn": "localhost:15001",
                "hostname": "localhost:15991"
            }
        }
    ]
}
```

where `fqdn` specifies the address of the component's web UI, and `hostname` specifies the address of the component's gRPC server.

##### Multiple clusters
To specify multiple clusters, repeat the `--cluster` flag:
```bash
vtadmin \
  --addr ":14200" \
  --http-origin "http://localhost:14201" \
  --http-tablet-url-tmpl "http://{{ .Tablet.Hostname }}:15{{ .Tablet.Alias.Uid }}" \
  --tracer "opentracing-jaeger" \
  --grpc-tracing \
  --http-tracing \
  --logtostderr \
  --alsologtostderr \
  --rbac \
  --rbac-config="./vtadmin/rbac.yaml" \
  --cluster "id=local,name=local,discovery=staticfile,discovery-staticfile-path=./vtadmin/discovery-local.json,tablet-fqdn-tmpl={{ .Tablet.Hostname }}:15{{ .Tablet.Alias.Uid }}"
  --cluster "id=prod,name=prod,discovery=staticfile,discovery-staticfile-path=./vtadmin/discovery-prod.json,tablet-fqdn-tmpl={{ .Tablet.Hostname }}:15{{ .Tablet.Alias.Uid }}"
```

The above multi-cluster configuration would show up in VTAdmin Web as:

<img src="/files/2022-11-28-vtadmin-intro/multiclusters.png" alt="Multiple clusters on the /clusters page in VTAdmin"/>

## How do I operate VTAdmin?
We have a complete [operator's guide](https://vitess.io/docs/15.0/reference/vtadmin/operators_guide/) to setting up VTAdmin in your Vitess cluster. If you intend to use VTAdmin with the Vitess Operator instead, follow [these instructions](https://vitess.io/docs/15.0/reference/vtadmin/running_with_vtop/).
## What's next?
There a number of things the team is excited to do next! Some of those things include:
- **Single component VTAdmin**: VTAdmin is currently deployed as two separate components: the Web client and the API server. We're working on packaging these up into a single component much like how the old vtctld2 UI was packaged with Vtctld.
- **Adding VTOrc UI**: We'd also like to combine VTOrc management capabilities into VTAdmin, primarily [the VTOrc UI](https://vitess.io/docs/15.0/user-guides/configuration-basic/vtorc/#old-ui-removal-and-replacement). That means instead of having to access two web applications to manage your Vitess clusters, you'll be able to do it all from VTAdmin.
- **Adding VTTablet and VTGate features**: VTGate and VTTablet also come with their own web UIs and management APIs - we'd also like to combine these into VTAdmin someday. This includes being able to use the experimental tablet features without providing tablet FQDN templates.
- **Making it easier to deploy**: Since VTAdmin recently went GA, we'd like to work on making the developer experience around deploying VTAdmin much easier. That means adding VTAdmin to existing Makefile workflows and other deployment optimizations.
## Stay in touch with VTAdmin
We welcome you to stay in touch with VTAdmin development in the #feat-vtadmin channel in the Vitess Slack. Here are some other ways you can stay up-to-date:
- **Vitess Docs**: https://vitess.io/docs/15.0/reference/vtadmin/
- **Github Repo**: https://github.com/vitessio/vitess/tree/main/web/vtadmin
- **Github Project**: https://github.com/vitessio/vitess/projects/12
