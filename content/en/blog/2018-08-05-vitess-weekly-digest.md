---
author: "Adrianna Tan"
published: 2018-08-05T07:15:00-07:00
slug: "2018-08-05-vitess-weekly-digest"
tags: ['Weekly Digest']
title: "Vitess Weekly Digest - Aug 5 2018"
---
*This week, we kick off our new weekly blog updates — bringing you the best of Vitess questions and topics on our [Slack](https://slack.com) discussions. The goal is to show the most interesting topics and requests so those of you just getting started can see highlights of what has been covered.*

Since this is our first ever digest, we’re going to go back in time and publish a little more than what happened last week.

### Large result sets

**Alejandro [Jul 2nd at 9:54 AM]**

Good morning, we are trying to move away from interacting with Vitess through gRPC and instead using the MySQL binary protocol and I was just wondering if anyone here could let me know if Vitess supports unbuffered/streaming queries (returning more than 10K rows) over the MySQL binary protocol, or if that is just a gRPC feature? Thanks in advance. (edited)

**sougou [29 days ago]**

@ Alejandro `set workload='olap'` should do it (for mysql protocol)


### Naming shards

**Deepak [9:36 AM]**

Hello everyone, I have a small doubt can someone please help me with it? I have four shards in Vitess cluster but all the data are going in just one shard. One of the difference in the setup is shard nomenclature. Instead of giving -80, 80- etc as shard names (params to -init_shard flag to vttablet) I have given names 0, 1, 2, 3. Can this be the cause of all data going to just one shard?

**sougou [10:11 AM]**

@ Deepak yeah. shards have to be named by their keyrange

### DB config parameters simplified

**sougou [10:06 AM]**

yay. no more long list of db command line options for vttablet: https://github.com/vitessio/vitess/pull/4088

all db-config-XXX options are now deprecated.

**acharis [10:08 AM]**

but will still work?

**sougou [10:08 AM]**

yes

**acharis [10:08 AM]**

great

**sougou [10:08 AM]**

till 3.0, then I'll delete them


### MySQL 8.0 support

**hrishy [7:33 PM]**

does vitess support mysql 5.8 and the native json in particular

**sougou [7:41 PM]**

@ hrishy I assume you mean 8.0. Although it hasn't been tried, we think it should work.

**derekperkins [7:49 PM]**

the new 8.0 JSON functions won’t work yet, those have to get added to the parser, but if that’s a blocker for you, it’s pretty easy to add

**derekperkins [8 days ago]**

https://github.com/vitessio/vitess/issues/4099


### Replica chicken-and-egg

**faut [1:01 AM]**

Hello. I need some help migrating to vitess. I have a baremetal master running mysql 5.6 and vttablet pointing to that master. I can query the master through vttablet and vtgate. The replicas however are still empty and cannot replicate because they don’t have the correct schema. I thought I could try make it a rdonly tablet and do the copy but that says no storage method implemented (assuming because it is not managed by mysqlctld) I’m not sure what the best approach from here is.

**sougou [6:21 AM]**

@ faut you can setup the replicas independent of vitess: manually copy the schema and point them at the master, just like you would to a regular mysql replica

mysqlctl is good only if you want vitess to manage the mysqls from the ground up.

but if you want to spin up a brand new replica, you first need to take a backup through vtctl

then spinning up a vttablet against an empty mysql will restore from that backup and automatically point it to the master

**faut [6:24 AM]**

yea, I’m stuck at the point of making the backup through vtctl. I want to try get away from managed the sql servers.

If I had a replica/rdonly with the schema manually copied would it manage to copy all the data from the existing master?

I am able to do a GetSchema off the master but cannot just restore that schema to the rdonly/replica.

**sougou [6:26 AM]**

there is a chicken-and-egg problem here

because you can't take a backup from a master

**faut [6:26 AM]**

Yes :joy:

**sougou [6:26 AM]**

so, you need to manually bring up one rdonly replica

and take a backup using that

after that you can spin up more

(we need to fix that limitation). there's an issue for it


### Vitess auto-fixes replication

**sjmudd [5:52 AM]**

Hi all. I was a bit surprised by something I saw today in Vitess. I had a master which was configured on “the wrong port”, so to simplify things I adjusted the configuration and restarted vttablet and mysqld.  Clearly changing the port the master was listening on broke replication so I went to fix the replica configurations by doing a stop slave and was going to do a change master to master_port = xxx only to find it had given me an error: replication was already running. It looks like vttablet will “fix” the master host:port configuration if replication is stopped and restart replication.

Wasn’t bad but was unexpected.

**sjmudd [5:52 AM]**

Is this expected? (I’d guess so). What other magic type behaviour does vitess do and when? @sougou?

**sougou [6 days ago]**

vttablet will try to fix replication by default. You can disable it with the -disable_active_reparents flag. If you're managing mysql externally to vitess, this should be specified for vttablet as well as vtctld.

**skyler [6:08 AM]**

Is there a document anywhere that lists the kinds of SQL queries that are incompatible with Vitess?

**derekperkins [6:24 AM]**

@skyler it depends whether your queries are single shard or not

single shard supports most any query since it is just passed through to the underlying MySQL instance

cross-shard is much more limited


**sjmudd [7.12 AM]**

also there are several things even a single shard won’t handle well: e.g. setting/querying session/global variables

use of query hints.

many of these things may not be a concern.

but if you use them can require code changes.

Sougou: while it is configurable I think you should probably show the default vitess version as 5.7.X as 5.5.X is rather antique right now.

I’ve changed my setup to advertise as 5.7.X. Is there a need to show such a low version?  iirc this can lead replication to behave differently as the i/o thread sometimes takes the remote version into account. I’d guess most other things may not care.

**sougou [8:09 AM]**

yeah. we can change the default now. most people are on 5.7 now

**acharis [9:17 AM]**

i think vtexplain might be what you're looking for

**skyler [6 days ago]**

nice! Thank you. I was unaware of that.

**derekperkins [6 days ago]**

Thanks, I couldn't remember for sure what the current iteration was called
