+++
author = "Sugu Sougoumarane"
published = 2018-09-24T07:15:00-07:00
slug = "2018-09-24-vitess-weekly-digest"
tags = ['Weekly Digest']
title = "Vitess Weekly Digest - Sep 24 2018"
+++

This week, we continue the digest from the Slack discussions for Sep 1 2018 to Sep 21 2018. As of this post, we are fully caught up on our backlog.

### Tracking progress of resharding

**jk [Sep 5th]** 

In the  SplitClone Stage of resharding, how can i get the percent of process ?  Or Could I estimate the time left ?

**sougou**

I don't know of a formal way, but you can look at the database size. It should be a good indicator hopefully.

**jk**

Alright. I'll check the mysql data size and compare. It is almost 400G in the source shard. So I'm not sure how long it will take. Thank you.

**xuhaihua**

@jk just check the row size of the destination shard and the source shard in vtctld.

### Proposal to reduce vitess CPU usage

**sougou [Sep 9th]**

Whoever is concerned about CPU: https://github.com/vitessio/vitess/issues/4191

### SHOW FULL FIELDS FROM

**captaineyesight [Sep 9th at 6:15 PM]**

Is there anyway to get around `1105 vtgate: http://<vtgate-addr>/: syntax error at position 17 near 'FIELDS': SHOW FULL FIELDS FROM`? We are using rails, and I believe this is required.

**koz**

Do you have the full query?
It looks like the grammar support `SHOW FULL COLUMNS FROM`.
I may have a simple PR that will add in FIELDS for you.

**captaineyesight**

Excellent. I think it is `show full fields for table name`.

**koz**

@captaineyesight try this https://github.com/vitessio/vitess/pull/4192

(PR has now been merged)

### Locking primitives

**sjmudd [Sep 10th at 1:40 AM]**

Does vitess expose any locking primitives to do administrative tasks? I want to do a backup on one of my replicas globally but have more than one cell. I can clearly use things outside of vitess (e.g. talk to zookeeper/etcd directly) but given vitess is talking to the topology service it would be nice to use vitess to do this and thus be agnostic to whatever vitess is using.

**sougou**

vitess has built an api for such a thing which it uses internally. For example, to prevent multiple vtctlds from racing on the same action. But it's all go code.

**sjmudd**

That would be fine. Perhaps you can point me at that or a sample way of getting some global lock that would be useful.

**sougou**

 i found this: https://github.com/vitessio/vitess/blob/master/go/vt/topo/locks.go
you can obtain keyspace or shard level locks
but i thought there was a different locking scheme. i'll need to dig further
I'll post here if i find something better.
Found it: https://github.com/vitessio/vitess/blob/master/go/vt/topo/conn.go#L165
    ```// NewMasterParticipation creates a MasterParticipation```

**sjmudd**

Thanks. I will take a look. In many ways this simplifies the doing stuff and means that the process is agnostic to the topo service being used.

### Vitess with no special drivers

**Mark Solters [Sep 10th]**

 I have what I hope is a very trivial question about `vtgate`: is it possible to perform a simple SQL operation such as e.g. a data import, but have that come in through `vtgate` so its automatically routed appropriately? _Without_ using some kind of application-level driver?
In the tutorial and documentation material everything I’ve seen along these lines already has a specific master tablet in mind.
For example, if I have some `.sql` file that has data from many databases, and I have a schema such that those databases are separated into their own keyspaces, is there a single endpoint I can hit with vitess so that the SQL from each database goes to the appropriate keyspace, instead of having to manually connect to each shard’s master?

**sougou**

@Mark Solters you just summarized the whole purpose of vitess :slightly_smiling_face:

**Mark Solters**

I know, but my difficulty is this particular implementation: using the vtgate, but without using e.g. some python or golang driver.

**sougou**

vtgates support mysql protocol.

**Mark Solters**

yes, is there more documentation than this? https://vitess.io/user-guide/mysql-server-protocol/.

**sougou**

Basically, any program that speaks mysql, you should be able to point it at vtgate. there are some caveats: some things that work with single mysql don't work in a sharded system.
Like setting global parameters, or information_schema queries etc.

**Mark Solters**

So just to clarify, there is no documentation of the actual implementation of the mysql protocol? Or maybe it is so simple that i am simply looking for more than there is.

**sougou**

Yup. Just point your mysql app at it. We do need to document what works and what doesn't. That's coming soon.

**Mark Solters**

When vtgate looks at the `/mysqlcreds/creds.json` file, does the `vtgate` binary actually create those users in the tablets? or does authentication “terminate” at the `vtgate` binary, and all tablet operations are performed with e.g. `vt_dba`? (edited)

**sougou**

The latter, but they're performed as `vt_app`. You can use the table acl feature to do access control at the vitess level.

### Cancel resharding

** weitzman [Sep 10th at 4:02 PM]**

I haven’t synced in the vreplication stuff yet, but I’ve noticed that pre-vreplication things get weird if you forget to clean up blp_checkpoint and re-run SplitClone. You may end up with having to manually populate blp_checkpoint and create the source shard entries

**sougou**

in the future, there may be other workflows that may create vreplication streams
the more correct thing will be to cleanly delete vreplication through a `CancelResharding` command, which I intend to implement.

### How to write a parser in Go

**sougou [Sep 11th]**

Gophercon video is out: https://youtu.be/NG0s3-s3whY.

### Resharding in Kubernetes

**Sean Gillespie [Sep 12th at 9:06 AM]**

Using vitess in kubernetes what is the best way to add shards to a keyspace?  I’m using vitess-operator and it seems like the obvious solution is update the yaml with sharding info and let it create new pods, but I kinda assume there are some extra steps to migrate data and create new masters and such

**derekperkins**

you’ll have to run through the resharding workflow
I’m not sure how much the operator supports you on that https://vitess.io/user-guide/horizontal-sharding-workflow/

**koz**

I think you can add new shards to the operator, but you need to add all the new shards, then run through the workflow and fail over traffic, then you can remove the old shards
So for while you are doing split clone you need to have the old shards and new shards online

**Sean Gillespie**

Ah so that may be tricky with operator then huh? Would I just give an additional definition for that keyspace that includes shards and then do the migration from the old ones to the new ones?

**koz**

If you do a `kubectl apply` that should just spin out the extra nodes
you would just need the cluster record to contain both.
( the old shards and the new shards )

### Emergency reparent

**longfei [Sep 14th at 9:17 PM]**

How to change replica to master when the original master is down? Is there any document?

**sougou**

`EmeregencyReparentTablet` (typo)

**longfei**

is EmergencyReparentShard ?
:+1: i'll take a look at it. thanks

**sougou**
or that one 

### Resource estimation

** Mark Solters [Sep 17th at 7:11 AM]**

in the documentation (production planning) it notes that you can think of giving vttablet as much CPU as your mysqls may have been using previously.  this gets me in the ballpark but what I’m left wondering is what is the recommendation as far as CPU assigned to the _mysql_ container itself?
e.g. if i have a vttablet that has 2-4 CPUs, is the rule of thumb to give the mysql sidecar that same amount of CPU? are there any guidelines here?
Or are the estimates being provided (2-4CPUs) actually the total for _both_ the `vttablet` and `mysql` containers taken together, and if so, what should the relative CPU ratio between them be?

**sougou**

MySQL's CPU is harder to estimate because it's workload dependent. Best way is to start with some assumptions and iterate.
Range should be in the order of 2-10K QPS per core.
Even for vttablet, we've seen 50-100% in CPU variance. So, take those recommendations with a pinch of salt :slightly_smiling_face:

**derekperkins**

@Mark Solters the recommendations in the helm chart are sourced from a few companies in production and are per container, not combined.

### HubSpot use of Vitess

**skyler [Sep 17th]**

https://product.hubspot.com/blog/infrastructure-as-code-getting-the-best-of-both-worlds-with-aws-and-google-cloud-platform

> Our first big project has been migrating all 400+ of our MySQL databases from standalone instances into Kubernetes with the help of the Vitess project.
I know some folks from HubSpot are in this channel. Are you able to give any more details on this? Are you really running all of your MySQL in Vitess? That’s pretty impressive. 

**acharis**

We're on our way there. It's a pretty cool project.

**hmcgonigal**

Very big portion of our production env is on vitess, yes.

**acharis**

And all of our QA (that we care to mention).

**skyler**

Sure

**hmcgonigal**

With the goal of having 100% of prod vitess very soon.

**skyler**

That’s awesome. That’s a big sign of confidence.

**hmcgonigal**

:+1:

**derekperkins**

@skyler HubSpot is also unique in how they use Vitess, based on their original microservice setup. They had hundreds of small dbs, as mentioned in the article, vs having a few big dbs that needed sharding.

**skyler**

Right, true. That’s a fortunate starting position to have.

**derekperkins**

It helps to show how flexible Vitess is.
