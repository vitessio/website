---
title: Overview
weight: 2
---
One of the goals for vitess is to provide a unified view for a large number of mysql clusters distributed across multiple data centers and regions.

Vitess achieves this goal by allowing the application to connect to any VTGate server, and that server gives you the semblance of being connected to a single mysql server. The metadata that maps the logical view to the physical mysql servers is stored in the topology.

In this logical view, a vitess keyspace is the equivalent of a mysql database. In many cases, this is a one-to-one mapping where a keyspace directly corresponds to a physical mysql server with a single database. However, a vitess keyspace can also be sharded. If so, a single keyspace would map to multiple mysql servers behind the scenes.

The topology is typically spread across multiple Topo Servers: The Global Topo server contains global information, like the list of keyspaces, shards and cells. This information gets deployed into cell-specific topo servers. Each cell specific Topo Server contains additional information about vttablets and mysql servers running in that cell. With this architecture, an outage in one cell does not affect other cells.

The topo also stores a VSchema for each keyspace. For an unsharded keyspace, the vschema is a simple list of table names. If a keyspace is sharded, then it must contain additional metadata about the sharding scheme for each table, and how they relate to each other. When a query is received by VTGate, the information in the vschema is used to make decisions about how to serve the query. In some cases, it will result in the query being routed to a single shard. In other cases, it could result in the query being sent to all shards, etc.

This guide explains how to build vschemas for vitess keyspaces.

### Demo
To illustrate the various features of the VSchema, we will make use of the [demo app](https://github.com/vitessio/vitess/tree/master/examples/demo). After installing Vitess, you can launch this demo by running `go run demo.go`. Following this, you can visit http://localhost:8000 to view the tables, issue arbitrary queries, and view their effects.

Alternatively, you can also connect to vitess using a mysql client: `mysql -h 127.0.0.1 -P 12348`.

The demo models a set of tables that are similar to those presented in the [Getting Started](../../../get-started/local) guide, but with more focus on the VSchema.

Note that the demo brings up a test process called vtcombo (instead of a real vitess cluster), which is functionally equivalent to all the components of vitess, but within a single process.

You can also use the demo app to follow along the steps of this user guide. If so, you can start by emptying out the files under `schema/product` and `schema/customer`, and incrementally making the changes presented in the steps that follow.
