---
author: "Sugu Sougoumarane"
published: 2018-09-10T07:15:00-07:00
slug: "2018-09-10-vitess-weekly-digest"
tags: ['Weekly Digest']
title: "Vitess Weekly Digest - Sep 10 2018"
---

*This week, we continue the digest from the Slack discussions for Aug 3 2018 to Aug 31 2018.*

### Secondary Vindexes

**raj.veerappan [Aug 3 9:27 AM]**

how do secondary vindexes work? would they result in further sharding?

**weitzman [9:32 AM]**

If you have an authors table and a books table and you shard by author ID, a secondary vindex is a performance tool to help respond to the query, `select * from books where book_id = :id`

Being sharded by authors, there’s not any obvious information in that query to help identify what the associated author ID / keyspace ID would be for the book entry (edited)

A secondary vindex is a function that helps answer that question in a more effective way than just doing a scatter query across all shards

**raj.veerappan [9:35 AM]**

ahh got it

so sharding only happens by primary vindex and secondary vindexes help with routing to primary vindexes.

### Update streams like Maxell

**raj.veerappan [10:56 AM]**

I think I heard that Vitess lets you listen to a stream of db updates, similar to Maxwell, are there docs available on this?

found https://vitess.io/user-guide/update-stream/

* Note update stream has been replaced by Vstream

**sougou [10:57 AM]**

yup :slightly_smiling_face:

it needs to be beefed up a bit. It could be easily upgraded to send full row values for RBR

https://github.com/vitessio/vitess/blob/master/test/update_stream.py is a test that also shows how to use it.

### Migrating from existin MySQL

**sumitj [Aug 13th at 3:25 AM]**

hi , How easy it is to migrate from existing mysql stack to vitess ? it would be really helpful if we can document migration strategy and challenges in that .I think there are lot of mid size companies who use mysql and facing scaling issues in some way , it would be great if we can make this transition smooth . (edited)

**faut**

I think it depends on how much downtime and risk you can take.

Doing a mysqldump and restoring to a new vitess cluster seems relatively easy but it requires a lot of downtime.

**faut**

And also if your DB is sharded etc increases the migration complexity

**sumitj**

@faut, I know there will be certain challenges , but if the steps would be nicely documented then it would be easier to adopt best practice and less chance for any unexpected issues .

**sougou**

This is on my list of things todo

**sumitj**

thanks a lot @sougou

**sjmudd**

another thought: it depends heavily on what you have running already and how you have it set up. In theory putting vitess on top of an existing replication setup shouldn’t be hard but in practice you’ll probably have to modify existing infrastructure to be at least partially vitess aware.  I tried going along that route and found it troublesome. It’s possibly easier to migrate tables to a new clean system which you can test and use without affecting existing production. That then requires you to think about how you want to move data over or if you’re comfortable putting vitess on top or whatever, but managing Vitess is different to managing a normal MySQL replication setup however you have that running at the moment.

### Ordering by text strings

**xuhaihua [Aug 22nd at 3:06 AM]**

Case sensitive should be consistent in gate and MySQL.

**sougou**

Is this for table names?

**xuhaihua**

not table names, for row  values

**xuhaihua**

for example  there two shards and a table t, select a from t order by a asc; MySQL returned result is case insensitive.

shard1 return values:  `[o P]`

shard2 return values:   `[o r ]`

vtgate merge the two result in a heap:

merge shard1 `o`,  current result : `[o]`

next we should merge shard2 `o`, but the compare in vtgate is case sensitive, the next pop is `P`

merge shard1 `P` ,current result : `[o, P]`

...

the final result is `[o P o r]`

the correct result should be `[o o P r]`

if the gourp by ,  shard1 `o` and shard2 `o` will not merged, it will be two group. (edited)

**sougou**

In your case, vtgate should have given an error saying that it cannot compare `text` columns.

what is the column type in your case?

However, if you specify a column's type in vschema, like this: https://github.com/vitessio/vitess/blob/master/data/test/vtgate/schema_test.json#L78

then it will produce a plan like this: https://github.com/vitessio/vitess/blob/master/data/test/vtgate/aggr_cases.txt#L81

which will yield the correct results.

**xuhaihua**

wow, understand, I didn’t know weight_string before ,awesome:+1:

### Packing multiple instances in a VM

**Srinath [Aug 22nd at 9:07 PM]**

Can we configure one vttablet to be a master of one shard and to be a replica of another shard?

**Srinath**

If yes, would like to know if this is a recommended pattern, if not, would like to know the reasoning behind

**sougou**

i remember someone asking this question, but don't remember the answer anymore. What's the use case?

**Srinath**

we have an application that is distributed across many VMs. for other applications that are part of these VMs, data is stored in cassandra. the application that we write uses postgres, but none of the existing solutions help us automatically re-shard and abstract the sharding logic. hence we have chosen to keep postgres stateless and only one node is a leader, when leader goes down, all state is lost. but this poses limitations to scale of our application.

we are evaluating vitess to see if we can have a database solution that gives easy re-sharding abilities, with some guarantees w.r.t consistency &amp; performance. we also like the fact that vitess abstracts out the sharding routing logic so that our application need not know about the topology of the database clusters at all.

that said, we are trying to see if we can come up with an architecture using vitess that will help us add more data storage capacity as more nodes are added to the cluster. initially we start from one VM, then scale out to 3, 5 etc as the need arises.

one possible architecture for 3 nodes is that have one shard and make all three nodes part of the same shard and have one master. but when we scale-out to 5 nodes, it gets complicated as to we have 2 shards, that can have 2 masters 3 replicas, but when we get to this architecture, there will be an imbalance in the replica count for shards as one shard will have two replicas and the other one will have only one replica.

another possible way to look at this is to not have database/vitess running on all nodes. basically for 5 node cluster, use only 3 node database configuration and for probably more than 5 node cluster, come up with a 6 node vitess configuration  which will have 2 master shards and 4 slaves with 2 slaves per shard.

other way to look at this is to form a ring (like cassandra) where one have many shards that can be mapped on to available servers and make every available server a leader for some of the shards and follower for other shards. very much the way cockroach db is also architected. but that would mean that one vttablet instance should become both a master and a replica at the same time.

would like to know your thoughts.

**sougou**

i think you're assuming that you can run only one mysql per node.

vitess allows you to pack multiple mysqls per host.

so, there's no need to overload a replica onto a master

if you have host1, host2 and host3 (and say, 3 shards)

**Srinath**

yes, we have come up with the same configuration where one node has more than one mysql, vttablet instance running, with one of it is master and other one is replica for some other master. is that the recommended configuration?

**sougou**

yes. that's the recommended config

**Srinath**

alright, lets see how our benchmarking goes :slightly_smiling_face:

**sougou**

if you run like this, you just have to make sure that a replica is never on the same host as the master.

because that can cause loss of durability

**Srinath**

yes, we are aware of it

**Srinath**

thank you for your thoughts :slightly_smiling_face: (edited)

### Avoiding stray tablet records

**Mark Solters [Aug 27th at 10:45 AM]**

I have noticed that when `vttablets` go down, `vtctld` has no idea?  e.g. I follow the example tutorial, and make a single unsharded `test` cell (1 master, 2 read replica, 2 read only) and these show up fine when I `ListAllTablets`.  But, when those pods go down (for example, if I kill them/they OOM/get evicted for any reason) `ListAllTablets` continues to list those now non-existant replicas as having an IP.  Restarting `vtctld` does not resolve this.  Am I missing something necessary to keep the state of the tablets synced with the vitess control plane here?

**sougou**

Yeah. This is a limitation of how things work. VTTablet is responsible for registering and unregistering the record. But it can't unregister if it's killed.

This also causes other issues: if you reparent later, the vtctld ends up waiting for a long time to change the master on the dead vttablets

We could have an agent that performs a sweep and remove orphaned records, but it's dangerous

**Mark Solters**

hmm, so what is the recommended approach to keep the pods alive/synced?

**sougou**

the recommended approach is to have another vttablet restarted with the same id if the pod dies

**Mark Solters**

for example, in the beginning tutorial, the pods are created directly.  should they die for any reason (they OOM frequently using the specs out-of-the-box) they do not come back

so I was thinking I’d try to spin up vttablets as statefulsets to preserve those unique ids/disk relationships

the same pod id?

**sougou**

the same tablet id

### Do we need multiple vtctlds?

**Mark Solters [Aug 28]**

a bit of confusion here with `vtctld`: is there one instance per cell? it seems there’s only one per _cluster_

but it does accept an argument like `-cell {{cell}}`, but this is only `global` in the tutorial.  is this a shortcut for ease of explanation?  does each cell in fact need its own `vtctld`? why wouldn’t there be a `vtctld` with `-cell=test`?

**sougou**

a single vtctld per cluster is likely sufficient. Some people launch 3, just in case.

the `cell` parameter in vtctld is just an old legacy thing. We need to remove that requirement.

### Designing ahead for sharding

**ruant [Aug 29th at 12:51 AM]**

So totally dumb question...

What should i think about when designing a DB that i want to shard in the future (since this startup is of course taking of like a rocket soon :sweat_smile: )

**sougou**

The easiest approach is to think that you need to shard this right now, and if so, how would you do it.

**ruant**

I guess splitting it up by each tenant, since it's multi tenant db.

Not all tables have a tenant id on it, but if you follow the relationship all rows in the db eventually will hit a table that has a tenant id...

How advanced can I define these sharding keys? (vindex if i'm not mistaken?)

**sougou**

Yeah. You can shard things such that all rows related to a tenant live together.

**ruant**

Nice :slightly_smiling_face:

But i'm still able to query across all the data even if it's sharded.

I guess it will go faster? Since it's being processed by two "db's"

I should just take a few hours to read up on this sharding topic.

Sorry for all the questions.

**sougou**

There are a few approaches with different trade-offs. The TL;DR: for secondary tables: if you don't have a tenant id, you may need to incur the overhead of going through a slower vindex (backed by lookup tables)

**ruant**

Thanks for your replies @sougou

Really appreciate it :slightly_smiling_face:

### Vitess sequences are globally unique

**skyler [Aug 31st at 9:25 AM]**

Do Vitess sequences support `auto_increment_increment` and `auto_increment_offset`?


**sougou**

The offset can be set by initializing a starting value in the sequence table (I think it's `next_id`). But there's currently no support for something like `auto_increment_increment`). Reason: typically, people set this value when they do custom sharding and want different masters to generate non-overlapping ids. But this is not required for vitess sequences because they generate globally unique ids.

**skyler**

Custom sharding, right, that’s exactly why we use it. If possible I wanted to keep IDs unique across different Vitess installations, using the same scheme.

but Vitess sequences are globally unique, aha, I did not know that

Thank you!

### Feature like Debezium (CQRS)

**Lucas Piske [Aug 31st at 11:58 AM]**

I'm developing a project where I'm using vitess as the sharding engine for mysql and I would like to use Debezium to implement CQRS. Do you think its possible to integrate this two technologies? Do you forsee any challenges that could cause problems?

**koz**

There will most likely be problems

It looks like Debezium uses the binlog to produce the changelog

Since Vitess is distributed you would need to connect to the binlog of each shard

It looks like Debezium supports that, but it would require additional configuration

@sougou Just implemented a feature called vreplication which might support the same feature set you are looking at with debezium

**sougou**

It's a POC, but we'll make into a real product soon

**Lucas Piske**

That would be great

I think it would be a really cool feature

It would help to implement some eventual consistency patterns

Thanks for the help

**sougou**

I'll definitely announce when the feature is ready
