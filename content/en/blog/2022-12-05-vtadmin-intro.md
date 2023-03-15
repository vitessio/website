---
author: 'Frances Thai'
date: 2022-12-05
slug: '2022-12-05-vtadmin-intro'
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
### VTTablet Management
VTAdmin provides a variety of VTTablet management tools, from starting and stopping replication, setting VTTablets to read/write, reparenting, deleting, pinging, and refreshing VTTablets, to experimental features like VTTablet QPS and VReplication QPS. 
<img src="/files/2022-12-05-vtadmin-intro/tablets.gif" alt="GIF of tablets features in VTAdmin Web"/>

_Note: To use experimental features, make sure to set `REACT_APP_ENABLE_EXPERIMENTAL_TABLET_DEBUG_VARS` in VTAdmin Web and `--http-tablet-url-tmpl` in VTAdmin API, as experimental tablet features work by making HTTP requests to the VTTablets._

### Keyspace Management
In VTAdmin, keyspace actions like validating keyspace/schema/version, reloading schemas, rebuilding keyspace graphs and cells, and creating new shards are made easy.
<img src="/files/2022-12-05-vtadmin-intro/keyspaces.gif" alt="GIF of keyspace features in VTAdmin Web"/>

## Workflow Management
VTAdmin allows you to view all your VReplication workflows and monitor workflow streams.
<img src="/files/2022-12-05-vtadmin-intro/workflows.gif" alt="GIF of workflow features in VTAdmin Web"/>

### Topology
The old topology browser in vtctld2 has been reimagined into a graph-traversal UI, which allows you to explore the full topology across single and multi-cluster deployments.
<img src="/files/2022-12-05-vtadmin-intro/topology.gif" alt="GIF of topology in VTAdmin Web"/>

## How does VTAdmin work?
VTAdmin Web is a web client that queries data from VTAdmin API via HTTP protocol. VTAdmin API in turn, is a mostly stateless API server that fetches data from VTGates and Vtctlds via gRPC. It returns this data to the frontend, VTAdmin Web. In a multi-cluster environment, that might look like:
<img src="/files/2022-12-05-vtadmin-intro/architecture.png" alt="Architecture diagram for VTAdmin API and Web"/>

### Lifecycle of a Request
_This is taken from the VTAdmin architecture doc [here](https://vitess.io/docs/reference/vtadmin/architecture/)_.

As an example, take the `/schemas` page in VTAdmin Web:
<img src="/files/2022-12-05-vtadmin-intro/schemas.png" alt="The /schemas page in VTAdmin Web"/>

When a user loads the `/schemas` page in the browser, VTAdmin Web makes an HTTP `GET` `/api/schema/local/commerce/corder` request to VTAdmin API. VTAdmin API then issues gRPC requests to the VTGates and Vtctlds in the cluster to construct the list of schemas. Here's what that looks like in detail:
<img src="/files/2022-12-05-vtadmin-intro/requests.png" alt="Lifecycle of a request to the /schemas page in VTAdmin"/>

## How do I operate VTAdmin?
We have a complete [operator's guide](https://vitess.io/docs/15.0/reference/vtadmin/operators_guide/) to setting up VTAdmin in your Vitess cluster. If you intend to use VTAdmin with the Vitess Operator instead, follow [these instructions](https://vitess.io/docs/15.0/reference/vtadmin/running_with_vtop/).
### Cluster configuration and discovery
VTAdmin API manages to be mostly stateless because it works by proxying requests from clients (VTAdmin Web) to Vitess clusters' VTGates and Vtctlds using gRPC.

The method by which VTAdmin API discovers VTGate and Vtctld addresses to create those gRPC connections is called **cluster discovery**. Users can pass VTGate and Vtctld addresses to VTAdmin API in two ways:
1. As command line arguments at initialization time
2. As an HTTP header cookie or gRPC metadata _after_ initialization time

More information on the different cluster discovery methods, and how to use them, can be found in our [cluster discovery documentation](/docs/15.0/reference/vtadmin//cluster_discovery).

### Role-based access control
VTAdmin also supports role-based access control (RBAC). This allows you to restrict access to, and actions on certain resources to a subset of users for an added layer of security. For more information on how to configure RBAC in VTAdmin, refer to our documentation [here](https://vitess.io/docs/15.0/reference/vtadmin/role-based-access-control/).
## What's next?
There a number of things the team is excited to do next! Some of those things include:
- **Single component VTAdmin**: VTAdmin is currently deployed as two separate components: the Web client and the API server. We're working on packaging these up into a single component much like how the old vtctld2 UI was packaged with Vtctld.
- **Adding VTOrc UI**: We'd also like to combine VTOrc management capabilities into VTAdmin, primarily [the VTOrc UI](https://vitess.io/docs/15.0/user-guides/configuration-basic/vtorc/#old-ui-removal-and-replacement). 
- **Adding VTTablet and VTGate features**: VTGate and VTTablet also come with their own web UIs and management APIs - we'd also like to combine these into VTAdmin someday. This includes being able to use the experimental tablet features without providing tablet FQDN templates.
- **Making it easier to deploy**: Since VTAdmin recently went GA, we'd like to work on making the developer experience around deploying VTAdmin much easier. That means adding VTAdmin to existing Makefile workflows and other deployment optimizations.
## Stay in touch with VTAdmin
We welcome you to stay in touch with VTAdmin development in the #feat-vtadmin channel in the Vitess Slack. Here are some other ways you can stay up-to-date:
- **Vitess Docs**: https://vitess.io/docs/15.0/reference/vtadmin/
- **Github Repo**: https://github.com/vitessio/vitess/tree/main/web/vtadmin
- **Github Project**: https://github.com/vitessio/vitess/projects/12
