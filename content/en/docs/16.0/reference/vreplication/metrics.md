---
title: Metrics
description: Metrics related to vreplication functionality
weight: 85
---

VReplication exports several metrics using the expvars interface. These are available at the `/debug/vars` endpoint of vttablet's http status pages. [More details can be found here](../../features/monitoring/#3-push-based-metrics-system).

## Target Tablet Metrics

#### VReplicationCopyLoopCount, VReplicationCopyLoopCountTotal

During the copy phase we run one loop of bulk copy for approximately an hour at a time (by default) before running catchup. _VReplicationCopyLoopCount_ counts the number of times this loop has run for each stream and _VReplicationCopyLoopCountTotal_ the total across all streams.

#### VReplicationCopyRowCount, VReplicationCopyRowCountTotal

_VReplicationCopyRowCount_ counts the number of rows copied during the copy phase per stream and _VReplicationCopyRowCountTotal_ the total across all streams.

#### VReplicationErrors

_VReplicationErrors_ counts the number of times errors occurred during vreplication. Errors are keyed
by the type of error.

#### VReplicationHeartbeat

_VReplicationHeartbeat_ records, for each stream, the timestamp sent by the last heartbeat event for that stream.

#### VReplicationMessages

_VReplicationMessages_ contains a stack of the last N (currently 3) messages of a vreplication stream.

#### VReplicationPhaseTimings, VReplicationPhaseTimingsCounts, VReplicationPhaseTimingsTotal

This metric relates to the times each phase is run during the lifetime of a stream.
_VReplicationPhaseTimings_ counts the total time taken by the runs,
VReplicationPhaseTimingsCounts the number of runs and _VReplicationPhaseTimingsTotals_ the total
runs across all streams.

#### VReplicationTableCopyRowCounts

_VReplicationTableCopyRowCounts_ counts the number of rows copied during the copy phase per table per stream.

#### VReplicationTableCopyTimings

_VReplicationTableCopyTimings_ counts the time taken per table per stream during the copy phase of the stream. Unlike _VReplicationPhaseTimings_, this metric updates continuously, rather than being set once at the end of the copy phase.

#### VReplicationQPS

_VReplicationQPS_ is a list of QPS values for each loop of each phase of the workflow.

#### VReplicationQueryCount, VReplicationQueryCountTotal

_VReplicationQueryCount_ is the total number of queries in each phase of a workflow. _VReplicationQueryCountTotal_ is the total queries across all phases and workflows.

#### VReplicationLagSeconds, VReplicationLagSecondsMax, VReplicationLagSecondsTotal

These metrics show the replication lag of the target stream with respect to the source stream. _VReplicationLagSeconds_ shows the current replication lag and _VReplicationLagSecondsMax_ has the maximum lag in this stream. Note that these values are only valid during the replication phase of a workflow.

#### VReplicationSource

Shows the keyspace and shard of the source from which this target stream is replicating

#### VReplicationSourceTablet

Shows the tablet from which this stream is currently replicating

#### VReplicationStreamCount

The number of streams running on this target

#### VReplicationStreamState

This shows the state of each stream.

## Source Tablet Metrics

#### VStreamPacketSize

The value of the `vstream_packet_size` flag specified for this tablet

#### VStreamerCount

The current number of running vstreamers

#### VStreamerErrors

The number of errors per category across workflows

#### VStreamersEndedWithErrors

The total number of errors that caused a stream to stall

#### VStreamerEventsStreamed

The total number of events streamed by this vttablet across all workflows

#### VStreamerNumPackets

The total number of packets sent by this vttablet across all workflows

#### VStreamersCreated

The total number of vstreamers created during the lifetime of this tablet

<hr style="border-top: 2px dashed brown">

## Example
**A snippet from tablet 200 from the local example after running the MoveTables step**

```
"VReplicationCopyLoopCount": {"commerce.0.commerce2customer.1": 2},
"VReplicationCopyLoopCountTotal": 2,
"VReplicationCopyRowCount": {"commerce.0.commerce2customer.1": 10},
"VReplicationCopyRowCountTotal": 10,
"VReplicationErrors": {},
"VReplicationHeartbeat": {"commerce.0.commerce2customer.1": 1618681048},
"VReplicationMessages": {"1": "2021-04-17T19:36:13.003858838+02:00:Picked source tablet: cell:\"zone1\" uid:100 "},
"VReplicationPhaseTimings": {"commerce.0.commerce2customer.1.catchup": 1000935083, "commerce.0.commerce2customer.1.fastforward": 15349583, "commerce.0.commerce2customer.1.copy": 63353125},
"VReplicationPhaseTimingsCounts": {"commerce.0.commerce2customer.1.copy": 2, "commerce.0.commerce2customer.1.All": 6, "commerce.0.commerce2customer.1.catchup": 2, "commerce.0.commerce2customer.1.fastforward": 2},
"VReplicationPhaseTimingsTotal": 1079637791,
"VReplicationQPS": {"All":[11.8,1,1.2,1.2,1,1.2,1,1.2,1,1.2,1,1.2,1.2,1,1.2,1,1.2],"Query":[11.2,1,1.2,1.2,1,1.2,1,1.2,1,1.2,1,1.2,1.2,1,1.2,1,1.2],"Transaction":[0.6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]},
"VReplicationQueryCount": {"commerce.0.commerce2customer.1.copy": 2},
"VReplicationQueryCountTotal": 2,
"VReplicationLagSeconds": {"commerce.0.commerce2customer.1": 0},
"VReplicationLagSecondsMax": 0,
"VReplicationLagSecondsTotal": 0,
"VReplicationSource": {"1": "commerce/0"},
"VReplicationSourceTablet": {"1": "cell:\"zone1\" uid:100 "},
"VReplicationStreamCount": 1,
"VReplicationStreamState": {"commerce2customer.1": "Running"},
"VReplicationTableCopyRowCounts": {"commerce.0.commerce2customer.1.corder": 4, "commerce.0.commerce2customer.1.customer": 2},
"VReplicationTableCopyTimings": {"commerce.0.commerce2customer.1.customer": 6707583, "commerce.0.commerce2customer.1.corder": 13254250},
"VStreamPacketSize": 250000,
"VStreamerCount": 0,
"VStreamerErrors": {"Catchup": 0, "Copy": 0, "Send": 0, "TablePlan": 0},
"VStreamerEventsStreamed": 0,
"VStreamerNumPackets": 0,
"VStreamerPhaseTiming": {"TotalCount":0,"TotalTime":0,"Histograms":{}},
"VStreamersCreated": 0,
"VStreamersEndedWithErrors": 0,
```
