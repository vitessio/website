---
author: 'Deepthi Sigireddi'
date: 2020-07-28T08:00:00-08:00
slug: '2020-07-28-announcing-vitess-7'
tags: ['Guides']
title: 'Announcing Vitess 7'
---

On behalf of the Vitess maintainers team, I am pleased to announce the general availability of Vitess 7.

## Major Themes

### Improved SQL Support
We continued to progress towards (almost) full MySQL compatibility. The highlights in Vitess 7 are replica transactions, savepoint support, and ability to set system variables per session.
We expect to continue down this path for Vitess 8.

### Stability
Vitess had significant technical debt because of functionality that has been added organically. Some parts of the code had become unmaintainable.
In this release, VTGate's healthcheck and VTTablet's tabletserver and tabletmanager have been rewritten.
The rewrites have already paid dividends. Replica transaction support and system variable support are built on the foundation of the new healthcheck and tabletserver.
VTTablet rewrites are expected to facilitate several new features in upcoming releases.

### Innovation
Vitess 7 adds ease-of-use and many new features built on top of VReplication. VStream Copy allows streaming of entire tables or databases, thus enabling change data capture applications.
Schema Versioning enables correct handling of binlog events on replication streams based on older versions of the schema.
VExec and Workflow commands make it possible to manage vreplication workflows without manual edits to metadata.
A novel framework has been built to allow dedicated connections alongside connection pooling. Locks and system variables have been implemented using this.

### Tutorials
Vitess 7 adds three new tutorials to the documentation. We have added a tutorial that demonstrates how to use the open source vitess-operator from PlanetScale,
a tutorial for region-based sharding, and one for a local docker installation.

There is a short list of incompatible changes in this release. We encourage you to spend a moment reading the [release notes](https://github.com/vitessio/vitess/releases/tag/v7.0.0).

Please download Vitess 7 and try it out!
