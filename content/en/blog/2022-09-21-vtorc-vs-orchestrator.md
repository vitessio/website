---
author: 'Manan Gupta'
date: 2022-09-21
slug: '2022-09-21-vtorc-vs-orchestrator'
tags: ['Vitess','Orchestrator','VTOrc', 'MySQL', 'Cluster Management', 'Failover', 'Fault tolerance', 'Distributed Systems', 'Cloud Native']
title: 'VTOrc Vs Orchestrator'
description: "The differences between VTOrc and Orchestrator"
---

There was an idea. An idea to make Vitess self-reliant. An idea to get rid of the friction between Vitess and external fault-detection-and-repair tools. An idea that gave birth to VTOrc…

Both [VTOrc](https://vitess.io/docs/user-guides/configuration-basic/vtorc/) and [Orchestrator](https://github.com/openark/orchestrator) are tools for managing MySQL instances. If I were to describe these tools using a metaphor, I would say that they are kinda like the monitor of a class of students. They are responsible for keeping the MySQL instances in check and fixing them up in case they misbehave, just like how a monitor ensures that no mischief happens in the classroom. 

VTOrc started off as a fork of Orchestrator, which was then custom-fitted to the Vitess use-case running as a native Vitess component. VTOrc and Orchestrator are like twins, if you look from far away, you might think that they are the same and do the same thing, but the closer you look, the more differences emerge in architecture, functionality, and flexibility. If you are interested in appreciating the differences between these two twins, then you are at the right place. Let’s jump right into it.

Most of the differences between the two derive largely from the fact that VTOrc can be opinionated about a bunch of things because it only has to solve one use-case which is the Vitess use-case, but Orchestrator was built to work with virtually any MySQL topology. For example, Vitess currently doesn’t support hierarchical replication. You have 1 primary tablet in a shard and replicas of those primaries. There is no cascading replication. No replicas are replicating from other replicas in steady-state. But Orchestrator allows this configuration. So, VTOrc doesn’t have to worry about the hierarchical topology and can do away with this flexibility that Orchestrator provides in favor of simpler code that ties in with other Vitess components like [vtcltd](https://vitess.io/docs/user-guides/configuration-basic/vtctld/).

# Discovery
The first point of difference between the two is that Orchestrator is a complete tool in itself while VTOrc is part of a much larger framework, Vitess. So VTOrc can rely on other components of Vitess to simplify its design even further. Let us look at MySQL instance discovery to understand this better.

From the Orchestrator documentation on [Discovery](https://github.com/openark/orchestrator#discovery), `Orchestrator actively crawls through your topologies and maps them. It reads basic MySQL info such as replication status and configuration`. On the other hand, VTOrc here takes a completely different approach. In Vitess, all MySQL instances have a sidecar associated with them called [VTTablet](https://vitess.io/docs/reference/programs/vttablet/). These VTTablets register themselves in the [topology server](https://vitess.io/docs/concepts/topology-service/). So VTOrc can just go ahead and ask the topology server for the exhaustive list of VTTablets for the shards that it is concerned with and use those records to discover and poll the underlying MySQL instances.

There is another dimension to discovery that goes beyond the current state. It is the topology that the MySQL instances are **supposed** to be running in. From the VTOrc standpoint, we already know Vitess only supports a single hierarchy of MySQL replication with no co-primary scenarios, so there is only supposed to be one primary per shard and all the other MySQL instances in the shard should be replicating from it. As to who the primary is, that information is stored in the topology server. For Orchestrator, however, there is no central location where the desired topology is stored, it has to infer that based on the current topology configuration as it stands and any changes the user might make going forward. In other words, VTOrc’s topology discovery and maintenance are somewhat declarative in nature whereas Orchestrator works in a more imperative fashion.

# Synchronization
Just as the presence of the topology server greatly simplifies MySQL discovery, it also helps in synchronization. 

While maintaining and trying to fix the MySQL topology, it is essential to ensure that only one actor is trying to change the topology, otherwise, things can go wrong very quickly. For example, let’s say that you have a running cluster whose primary failed and you have multiple orchestrators running. If by any chance, two of the orchestrators decided to promote different primaries, it would result in a broken topology configuration with some replicas pointing to one instance and the others pointing to the other. Split-brain from this position is very likely and can cause major headaches. 

To prevent different orchestrator nodes from stepping on each other’s toes, one possible solution could be to only have one orchestrator maintaining a cluster. But this isn’t feasible because like any other application, orchestrators are also liable to failures, some of which are beyond their control, like being evicted from a node in the Kubernetes environment, running out of CPU allotted to it, etc. So, to have high availability you need to deploy more than one orchestrator node for each cluster.

Orchestrator provides two ways of providing [high availability](https://github.com/openark/orchestrator/blob/master/docs/high-availability.md#orchestrator-high-availability), the first one using the consensus algorithm Raft, and the other using a shared backing store for the orchestrator nodes.

VTOrc on the other hand relies on the existing functionality of shard locking that Vitess uses for synchronization between various actors. Since the topology servers are reliable key-value stores, which run some consensus algorithms under the hood, VTOrc can rely on them for this functionality of only allowing a sole actor to acquire a shard lock thereby guaranteeing synchronization. This allows multiple VTOrc instances to monitor the same cluster without knowing or caring about the existence of the others.

# Ephemeral Data 
In Vitess, the topology server is responsible for storing persistent and durable data like the topology structure, the durability policy, etc. This allows VTOrc to function with only storing ephemeral data. It doesn’t need any data to be persisted across restarts, which makes VTOrc a truly cloud-native component, since it can be restarted at will and its data gets populated again from the topology server.

# UI
Orchestrator comes bundled with an attractive [user interface](https://github.com/openark/orchestrator/blob/master/docs/using-the-web-interface.md) which serves as the final piece of an already impressive tool. It allows the users to look at the current topology structure, investigate the settings of all the MySQL nodes and even change them, right from the UI! 

In Vitess however, the user interface isn’t just about the running MySQL instances, but should also incorporate other Vitess components like the vttablets, and vtgates. It should allow the users to look at their current Vitess configurations like [VSchema](https://vitess.io/docs/concepts/vschema/) and should also allow them to change it seamlessly. Here yet another Vitess component comes to our aid, [VTAdmin](https://vitess.io/docs/reference/vtadmin/). It is the administration tool offered by Vitess providing an API and a web interface. The team is working towards incorporating all the data and functionality that the VTOrc UI provides (which it inherited from Orchestrator) into VTAdmin, at which point VTOrc’s stand-alone UI will be deprecated and removed.

# Clean-up and Ease of Use
The [orchestrator integration](https://vitess.io/docs/user-guides/configuration-advanced/integration-with-orchestrator/) built into Vitess is cumbersome and has caused bugs in the past.
Making VTOrc a native Vitess component that is aware of other Vitess components allows us to stop relying on a fragile integration. It also offers opportunities for cleaning up code that is no longer necessary. For example, VTTablets have the ability to take backups or restore from a previously taken backup. With the Vitess-Orchestrator integration, VTTablets needed to go into maintenance mode before they started taking a backup. This was required since replication is stopped while a backup is being taken, and we don’t want Orchestrator to fix it. This meant that VTTablets had to be aware of at least one orchestrator node to be able to request maintenance mode.
VTOrc, on the other hand, has access to VTTablet metadata along with the MySQL instance, which allows it to infer that a VTTablet is in the process of taking a backup and its replication should not be fixed without explicit action from the VTTablet.

# Future Scope
There are multiple possibilities for VTOrc to go above and beyond in the failure scenarios that it can handle as compared to Orchestrator. VTOrc can handle failures related to the VTTablets as well and not just the MySQL instances. It can subscribe to the VTTablet health checks to accomplish the same. The possibilities are endless and truly exciting.

With VTOrc going GA soon, it is the perfect time for you to try it out. If you do, please provide us feedback on your experience via [GitHub](https://github.com/vitessio/vitess/issues/new/choose) or [Slack](https://vitess.io/slack).

