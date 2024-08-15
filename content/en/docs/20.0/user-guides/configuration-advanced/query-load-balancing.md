---
title: Read Query Load Balancing
weight: 12
---

For applications which scale out read queries using replicas, Vitess can safely avoid sending queries to replicas with replication lag beyond acceptable thresholds.

## Flags

You can set the following flags on VTGate to control load-balancing of read queries for replicas:

* `discovery_high_replication_lag_minimum_serving`: If the replication lag of a vttablet exceeds this value, vtgate will treat it as unhealthy and will not send queries to it. This value is meant to match vttablet’s `unhealthy_threshold` value.
* `discovery_low_replication_lag`: If a single vttablet lags beyond this value, vtgate will not send it any queries. However, if too many replicas exceed this threshold, then vtgate will send queries to the ones that have the least lag. A weighted average algorithm is used to exclude the outliers. This value is meant to match vttablet’s `degraded_threshold` value.
* `min_number_serving_vttablets`: The minimum number of vttablets for each replicating tablet type (e.g. replica, rdonly) that will continue to be used even with replication lag above `discovery_low_replication_lag`, but still below `discovery_high_replication_lag_minimum_serving`.

Be aware that there are VTTablet settings that impact the functionality of these flags, discussed in the section below.

## Replication Lag and Query Routing

From a replication lag perspective, a tablet can be considered to be in three states for read-only routing: healthy, degraded, and unhealthy. Unhealthy tablets receive no queries. Degraded tablets will only receive queries if absolutely necessary. Healthy tablets will always receive queries.

Degraded tablets (those with replication lag above `discovery_low_replication_lag`) will only receive queries when there are fewer than `min_number_serving_vttablets` non-degraded tablets available (within same shard, same tablet type, etc) for queries. Above that point, a weighted average algorithm is used to determine which replica should serve queries, prefering those with less lag.

{{< info >}} If there are only 2 replicas for a given replication group and tablet type and `min_number_serving_vttablets` is set to the default of 2, the only portion of this logic that will apply is the unhealthy threshold set by `discovery_high_replication_lag_minimum_serving` at which point the replica will receive no queries. To get the other behaviors requires either more tablets or reducing `min_number_serving_vttablets`. {{< /info >}}

The replication lag thresholds at which tablets are considered degraded or unhealthy as well as the logic around when degraded tablets receive queries are controlled by several flags. There are both VTGate-side and VTTablet-side flags and it's important to configure them together and properly to get the behavior you desire.

Combining `discovery_high_replication_lag_minimum_serving`, `discovery_low_replication_lag`, and `min_number_serving_vttablets` can be used to safely route around temporarily lagging replicas in an otherwise healthy cluster. A common scenario is when a new replica tablet is initialized from a base backup, which will very likely have a too-high replication lag when it first comes up. 

* Set `min_number_serving_vttablets` to the minimum number of replicas that must be available to serve your peak replica query traffic.
* Set `discovery_high_replication_lag_minimum_serving` (along with `unhealthy_threshold` on vttablet) to the highest amount of acceptable replication lag for serving queries, or the threshold at which it is preferable to serve an error versus stale data.
* Set `discovery_low_replication_lag` (along with `degraded_threshold` on vttablet) to the replication lag that is tolerable under normal circumstances.

## Gotchas and Notes

There are some things to be aware of when manipulating these settings.

* It is safe to roll out the flag changes on vttablet and vtgate separately, but the overall behavior may not take hold as expected until both sets of flags are completely applied.
* It is unadvisable to set these replication lag thresholds below 3 seconds, as there is skew in replication lag measurement below that point.
* As a reminder, tablets are grouped together by type for this functionality, so for example, `min_number_serving_vttablets` will be applied separately to rdonly and replica tablet type groups.
* When reducing `discovery_low_replication_lag` from the default, also consider reducing the vttablet `health_check_interval` which controls how often the lag measurements are checked. The latency in changes to replication lag is dictated by this configuration. It should be a fraction of `discovery_low_replication_lag` -- a good rule of thumb is half of that setting or lower.

