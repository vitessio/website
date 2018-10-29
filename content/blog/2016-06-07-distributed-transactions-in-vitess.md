+++
author = "Sugu Sougoumarane"
published = 2016-06-07T17:05:00-07:00
slug = "2016-06-07-distributed-transactions-in-vitess"
tags = [ "distributed transactions", "sharding", "2PC",]
title = "Distributed Transactions in Vitess"
+++
<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">With
Vitess introducing sharding and allowing you to create cross-shard
indexes, distributed transactions become unavoidable for certain
workloads. Currently, Vitess only supports best-effort distributed
transactions. So, it’s possible that a distributed commit only completes
partially, leaving data in an inconsistent state.</span>  
<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">  
</span><span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">At
this point, 2 Phase Commit (2PC) is the only known protocol that allows
you to give atomic guarantees for distributed transactions. For this
protocol to work, a database must be able to support the ‘Prepare’
contract. However, not all databases provide such support. Also, some of
the engines that do support it either do it incorrectly or
inefficiently. Specifically, the pre-5.7 MySQL XA protocol works
incorrectly for replication, and is therefore not usable.</span>  
<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">  
</span><span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">The
question was asked: Is it possible to build a Prepare protocol on top of
a database that does not support it? The answer is: Yes, for an engine
like MySQL. The explanation follows.</span>  

<span style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">2PC in very few words</span>
---------------------------------------------------------------------------------------------------------------

<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">If
nothing ever failed, 2PC would not be needed. You just open transactions
with databases as needed, and commit them all at the end. However, there
are failure modes in the system that cause one of these things to
happen:</span>  

1.  <span
    style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">A
    database aborts a transaction for internal reasons.</span>
2.  <span
    style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">A
    database refuses to commit because of lock conflicts.</span>
3.  <span
    style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">A
    database crashes and loses an uncommitted transaction.</span>

<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">2PC
introduced the prepare protocol to defend against the above three. A
database that acknowledges a prepare must give you the following
guarantees:</span>  

1.  <span
    style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">It
    will not abort a transaction unless requested.</span>
2.  <span
    style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">It
    will never refuse a commit.</span>
3.  <span
    style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">If
    the database crashes, it will reinstate the transaction to its
    prepared state upon recovery.</span>

<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">With
the above guarantees, a transaction manager asks all participants to
prepare. If any of them fails, then the decision is to rollback. If they
all succeed, then we have the guarantee that commits will never be
refused. So, we can decide to commit. Once a commit (or rollback)
decision is made, it’s final. If a database crashes after a prepare, the
recovery process will reinstate the prepared transaction. At this point,
the transaction manager can resolve the transaction according to the
final decision.</span>  
<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">  
</span><span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">2PC
itself has failure modes. The most significant issues are related to the
transaction manager crashing, or the ability for various parts of the
system to agree on the commit/rollback decision. These issues are
somewhat orthogonal to the focus of this document, and they will be
covered in the upcoming design doc, or possibly in a different blog
post.</span>  

<span style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">MySQL transactions</span>
------------------------------------------------------------------------------------------------------------

<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">MySQL
transactions have an interesting property: If all statements have
executed successfully, then a commit almost never fails. There are a few
configurations where this is not true. So, they should be
avoided:</span>  

1.  <span
    style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">Group
    replication: This is a new 5.7 feature. If this is turned on, then a
    commit can fail due to locking conflicts.</span>
2.  <span
    style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">Semi-sync
    with a commit timeout: If configured this way, MySQL could fail your
    commit if it doesn’t receive a semi-sync packet within the timeout.
    To make 2PC reliable, it’s recommended that semi-sync be configured
    with no time-out. This way, if acks are not received on time, the
    entire database would lock up and will be treated as crashed. In the
    case of Vitess, the system will initiate a failover to a healthier
    replica. Of course, the new master will not have the original
    transaction, but we’ll rely on a different mechanism for
    reinstatement, which is explained in the next section.</span>

<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">Because
a commit could never fail, MySQL will never rollback your transaction
unless it’s requested.</span>  
<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">  
</span><span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">The
above behavior basically tells us that MySQL transactions are in a
pseudo-prepared state all the time. They satisfy properties 1 & 2 of the
prepared state, but not \#3.</span>  

<span style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">Redo logs in the database</span>
-------------------------------------------------------------------------------------------------------------------

<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">Now,
all we have to do is figure out a way to get back to the prepared state
when a database crashes. In order to achieve this, the traffic will have
to be sent through a proxy.</span>  

-   <span
    style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">The
    proxy will maintain a list of statements that are sent in a
    transaction. When a ‘prepare’ is requested, the list will be saved
    to a redo\_log table. This will be done in a separate transaction
    while the original transaction is still open. If this operation
    fails, then the prepare is treated as failed.</span>
-   <span
    style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">Let’s
    say that a database crashes after some transactions are prepared,
    and we’re performing a recovery. After the database part of the
    recover, the proxy scans the redo log for prepared transactions, and
    replays each of those in independent connections. These should not
    fail because of the serializability of transactions. Once this is
    done, we have fulfilled the 3rd requirement of the ‘Prepare’
    contract. After this step, the proxy can start accepting normal
    traffic. At this time, the transaction managers can re-connect to
    the proxy to conclude the prepared transactions.</span>

<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">Coincidentally,
Vitess already has such a proxy in VTTablet. How convenient.</span>  
<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">  
</span><span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">In
Vitess, the usual way to ‘recover’ a failed master is to failover to a
replica by designating it as the new master. A tool like
[Orchestrator](https://github.com/outbrain/orchestrator) will do this
reliably almost all the time. Various levels of semi-sync settings
further improve these guarantees. In other words, the same effect of
reinstating prepared transactions can also be achieved if we used the
failover workflow instead of a traditional recover.</span>  

<span style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">Recap</span>
-----------------------------------------------------------------------------------------------

<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">Vitess
allows you to tune MySQL to suit your durability requirements. If you’re
very paranoid about data loss, you can tune-up the semi-sync variable to
have almost the same reliability level as Paxos. Using MySQL 5.7’s
version of “lossless” semi-sync will further strengthen this. However,
these could be overkill. Typically, requiring a single semi-sync ack for
any version of MySQL is likely sufficient. In the rare case of a
transaction loss, the 2PC mechanism should be able to detect and alert
you, and manual intervention can be used to perform repairs. These
failure modes will be covered in the detailed design doc.</span>  
<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">  
</span><span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">Coupling
this with fast failure detection and automatic master failover also
gives you high availability.</span>  
<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">  
</span><span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">This
basically means that a node is unlikely to lose your committed data, and
will also be resurrected very quickly if it crashes or experiences a
network partition.</span>  
<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">  
</span><span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">The
proposed prepare mechanism effectively extends the durability and
availability guarantee of a single database (or shard), and makes it
work equally reliably for distributed transactions that span multiple
shards.</span>  

### <span style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">Loose ends</span>

<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">The
purpose of this blog post is to show that it’s possible for Vitess to
support atomic distributed transactions. There are still many details to
cover:</span>  

-   <span
    style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">Generating
    globally unique transaction ids to avoid number conflicts.</span>
-   <span
    style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">Isolation
    levels.</span>
-   <span
    style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">Reliably
    storing commit/abort decisions.</span>
-   <span
    style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">Transaction
    manager failures.</span>
-   <span
    style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">Database
    and network failure scenarios.</span>
-   <span
    style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">Optimizations.</span>

<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">These
issues will be addressed in a detailed design doc under vitess.io very
soon.</span>
