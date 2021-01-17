---
title: VReplication
description: VReplication related design docs
weight: 3
skip_sections: true
aliases: ['/docs/design/vreplication/']
---

# Introduction
This section contains documents discussing the design and implementation of different aspects
of the VReplication functionality in Vitess. It should help:
* developers wishing to contribute code (new features, bug fixes, ...) can get an idea of the core architectural components and a pointer to where the relevant code resides. Each page contains a quick "code sitemap" of where the key source files reside
* new or experienced users who want to get a better insight into how vreplication works

_Please note that, over time, the code may diverge from this documentation. The code, as always, is authoritative :-)  Feel free to either report or fix issues that you see in this documentation or flag areas that need more._

<hr style="border:1px solid gray"> </hr>

# Contents

## Core Stuff
  1. [**Basic Architecture**](./architecture) _Coming Soon_ <br/>
  Gives a short outline of the key processes and business logic components that participate in a VReplication workflow.

  1. [**Life of a Stream**](./life-of-a-stream) <br/>
  Describes the internal details of how a stream in a VReplication workflow replicates data from a source to a target in a fast and eventually consistent mannner.

## Key Modules
  3. [**VStreamers on the Source**](./vstreamer) _Coming Soon_ <br/>
  Describes how a VStreamer, running on the source, send data streams to the target.

  1. [**VReplication on the Target**](./vreplication) _Coming Soon_ <br/>
  Describes how the target replays the data stream received from VStreamers to generate CRUD statements to replicate data on the target database.

  1. [**The VTGate VStream API on the Target**](./vstream-api) _Coming Soon_ <br/>
  Talks about how the VStream GRPC API on VTGate is implemented.

## Related Topics
  6. [**When to turn on the switch**](./switch-lag) _Coming Soon_ <br/>
  Determining when to switch traffic over to a target for a MoveTables and Reshard workflow.

  1. [**What happens during a cutover**](./cutover) _Coming Soon_ <br/>
  Describes the changes required in the topo to signal to VTGate that queries that were served by the source should now be routed to a target.

  1. [**Migrating materialize streams during a Reshard**](./switch-lag) _Coming Soon_ <br/>
  Materialize streams run for ever and need to be migrated so that they seamlessly start sourcing data from the new target on a MoveTables or a Reshard.

##  Developer and SRE Corner
  9. [**Unit Test Frameworks**](./test) _Coming Soon_ <br/>
  Writing unit tests for VReplication requires building complex mock environments to emulate a vttablet, simulate edge cases, ...

  1. [**Observability and Metrics**](./observability) _Coming Soon_ <br/>
  VReplication exposes performance metrics and execution logs for developers and SREs to debug problems and integrate with operational dashboards.

  1. [**VReplication Tools and Scripts**](./tools) _Coming Soon_ <br/>
  Describes the helper scripts, commands and tools for advanced configuration, management and debugging.

  <hr style="border:1px solid gray"> </hr>
