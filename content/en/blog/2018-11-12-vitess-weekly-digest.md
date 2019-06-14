---
author: "Sugu Sougoumarane"
published: 2018-11-12T07:15:00-07:00
slug: "2018-11-12-vitess-weekly-digest"
tags: ['Weekly Digest']
title: "Vitess Weekly Digest - Nov 12 2018"
---

We continue the digest from the Slack discussions for Sep 22 2018 to Oct 5 2018. We've fallen slightly behind on this, but will catch up again soon.

###  Enable VtGateExecute in vtctld

**Arsalan [Sep 22nd]**

Hi,
I want to query vitess on vtgate but I have below error. How can i fix this problem?

`` vitess@vtctldv3-hrl74:/$ vtctlclient -server 10.5.61.20:16999  VtGateExecute -server 10.5.61.21:16991 "show tables"``

``E0923 05:14:55.169771    1102 main.go:61] Remote error: rpc error: code = Unknown desc = query commands are disabled (set the -enable_queries flag to enable)
``

**sougou**

you need to add this flag to vtctld:

``-enable_queries``

``if set, allows vtgate and vttablet queries. May have security implications, as the queries will be run from this process.
``

###  Multi-column Primary Key

**sjmudd [Sep 26th]**

Question: if a mysql table has a multi-column primary key, can Vitess handle this ? I vaguely remember the answer might be “no”.
but looking in `vschema_test.go` I think that may not be the case.

**sougou**

multi-column pk should work. What we don't fully support yet are multi-column vindexes.
there's partial support for multi-column lookup vindexes, where we write multiple columns, but only use the first column for computing the keyspace id.  

### Vitess wins InfoWorld Bossie award

**sougou [Sep 26th]**
"The best open source software for data storage and analytics": https://www.infoworld.com/article/3306454/big-data/the-best-open-source-software-for-data-storage-and-analytics.html#slide9

Also, @acharis and @tpetr have been accepted to present vitess at kubecon: https://kccna18.sched.com/event/Gras/vitess-at-hubspot-how-we-moved-hundreds-of-mysql-databases-into-kubernetes-tom-petr-alexander-charis-hubspot

### Splitting sharded and unsharded tables

**Mark Solters [Sep 27th]**

If one were to shard `foo/0 to baz/{-80,80-}`, would the `SplitClone foo/0` syntax have to be modified to reflect that the destination shards are no longer in the source keyspace?
Inspecting the command seems to suggest that there is no “destination shards” option for `SplitClone`.  In this case, my question is better phrased as “How can we horizontally reshard one keyspace into another?”  It seems the missing part is convincing `foo/0` that it “overlaps” with `baz/-80,80-`.
I think the correct answer here is that I should be vertically sharding.

**sougou**

Yeah. you first have to vertical shard from `foo/0` to `baz/0`, and then reshard `baz` to `baz/{...}`

**Mark Solters**

I see. Is there a guide or set of instructions for the vertical sharding procedure?

**sougou**

It's one of the top items that we need to document. In the meantime, you can look at my scripts. Steps are similar to horizontal sharding: https://gist.github.com/sougou/e6259e958b5707d5888a5ac406418cc3

**Mark Solters**

Very interesting! I’ve basically done these steps minus this
`CreateKeyspace` --served_from `'master:test_keyspace,replica:test_keyspace,rdonly:test_keyspace' target`
Is that step strictly necessary?  If I have already copied over the relevant `CopySchemaShard`, and baz already has a functional master etc. can I simply run `VerticalCloneSplit`?
i ask because i notice `VerticalCloneSplit` specifies the destination but not the source.

(The thread was forgotten at this point)
Answer: The specific step is strictly necessary for `SplitClone`. It's currently a rigid workflow that we plan to make more flexible in the future.

### Show tables of a keyspace

**mgersh [Sep 27th]**

is there a query to show all tables for a certain keyspace? we are using the jdbc driver
"show tables from $keyspace" just returns the default keyspace's tables

**leoxlin**

If you connect to a specific Keyspace, you can use `SHOW TABLES;`

### If pods crash, check resource limits

**mshivanna [Oct 1st]**

hi we recently spun up vitess cluster now we want to import a mysql dump. what is the right way to do it? We execed into the master node (vttablet-100) mysql container and did a usual mysql import but the vttablet pod kept crashin after sometime. The dump is 13Gb in size.

**sougou**

Can you look at the reason why the pod was terminated? Most likely, you ran out of some resource.

**mshivanna**

yeah i have increased the cpu its not failing quite often but its failing will increase again. will update here thank you @sougou

### Ameet presents at Velocity conference, NY

**ameet [Oct 2nd]**

Hi Vitessians, I just finished my talk about _Moving Slack's database to Vitess_ at Velocity Conference, NY. Here's the link to the talk and slides: https://conferences.oreilly.com/velocity/vl-ny/user/proposal/status/69885 The response was great. There was lots of interest about Vitess.

### Improved control on resharding

**young [Oct 5th]**

 Is there an open issue for encapsulating resetting vreplication in one command? It's quite annoying to do manually.

**sougou**

i'm wokring on a PR to perform high level commands for canceling resharding etc.

UPDATE:  these features are now done.

### Understanding keyspace ids and keyranges

**Mark Solters [Oct 5th]**

given a shard like `80-`
what is the smallest keyspace ID that would be mapped to this shard?
is it `0x80`? `0x81`? `0x800`? `0x8000`?
(i am trying to construct a `numeric_static_map`)
i know that we use a syntax that makes the RHS zeros “optional” but I also think that the center of the keyspace can’t be as small a number as `0x80`. (!)
is what we write as `0x80` actually `base-10 9223372036854775808`?

**sougou**

the keyspace id is a bunch of bits (left justified)
there is theoretically no limit to the number of bytes it can have
it may get confusing if you try to see it as a number
because numbers are right justified
in some cases, we 'encode' a number as a keyspace id. If so, we set the length as 64 bits.
it's just a convention. One could have used 128 bits or 32 bits, or whatever.

**Mark Solters**

hmm, OK so how then does one construct a `numeric_static_map`?
the vitess repo contains a `numeric_static_map_test.json` where it is simply mapping some example primary keys to integers like 1 and 2, which if i'm reading this correctly, are the keyspace IDs
im basically confused about how this map here translates to shards: https://github.com/vitessio/vitess/blob/master/data/test/vtgate/numeric_static_map_test.json

``{
   "1": 1,
   "3": 2
}
``

**sougou**

Oops. Sorry about the tangent. Yeah. In your case, you're right. the `922..` number is the lowest number for shard `80-`
this is because `numeric_static_map` converts the number into a 64-bit keyspace id.

**Mark Solters**

yes, and i take your point about the question being ambiguous without something grounding the bit size
hmmmm so, for this (trivial) example to work
i guess id have to construct a shard like `-000000000000002`
which would have an effective key size of 1

**sougou**

right. that shard can have 2 ids (0 & 1)

### Meaning of target in the Go driver

**derekperkins [Oct 5th]**

@sougou what is a target in the go driver? https://github.com/vitessio/vitess/blob/master/go/vt/vitessdriver/driver.go#L129

**sougou**

best documentation is the test https://github.com/vitessio/vitess/blob/master/go/vt/vitessdriver/driver_test.go

**derekperkins**

ah, thanks
and leaving it empty presumably points to master?

**sougou**

yeah
well
if you didn't override the default tablet type in vtgate
