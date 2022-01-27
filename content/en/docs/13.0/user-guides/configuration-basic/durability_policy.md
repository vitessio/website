---
title: Durability Policy
weight: 10
---

Vitess now supports a configurable interface for the durability policies. The users can now define in the interface which tablets are eligible to be promoted to a PRIMARY instance. They can also specify the number of semi-sync ACKs it requires and the tablets which are eligible to send these ACKs.

The interface definition looks like - 
```go
// durabler is the interface which is used to get the promotion rules for candidates and the semi sync setup
type durabler interface {
	promotionRule(*topodatapb.Tablet) promotionrule.CandidatePromotionRule
	semiSyncAckers(*topodatapb.Tablet) int
	isReplicaSemiSync(primary, replica *topodatapb.Tablet) bool
}
```

There are 3 implementations bundled with Vitess - 
 - ***semi_sync*** - This durability policy setups the number of required semi-sync ACKers to 1. It only allows Primary and Replica type servers to acknowledge semi sync. It returns NeutralPromoteRule for Primary and Replica tablet types, MustNotPromoteRule for everything else
 - ***none** (default)* - This durability policy does not setup any semi-sync configurations. It returns NeutralPromoteRule for Primary and Replica tablet types, MustNotPromoteRule for everything else
 - ***cross_cell*** - This durability policy setups the number of required semi-sync ACKers to 1. It only allows Primary and Replica type servers from a different cell to acknowledge semi sync. This means that a transaction must be in two cells for it to be acknowledged. It returns NeutralPromoteRule for Primary and Replica tablet types, MustNotPromoteRule for everything else


[EmergencyReparentShard](../../configuration-advanced/reparenting/#emergencyreparentshard-emergency-reparenting) and [PlannedReparentShard](../../configuration-advanced/reparenting/#plannedreparentshard-planned-reparenting) will use the durability rules while choosing the correct candidate for promotion.

This configuration should be specified in [vtctld](../vtctld), [vtctl](../../../concepts/vtctl) and vtworker as a flag `-durability_policy`. It should be specified in [vtorc](../vtorc) as `Durability` config.

{{< info >}}
Currently the durability policies are not used to setup semi-sync in EmergencyReparentShard or PlannedReparentShard. All the RPCs are still using `-enable_semi_sync` flag on vttablet to setup semi-sync. This flag is currently being used for promotion rules and to log discrepancies in semi-sync setup. Nonetheless, this flag should be specified correctly for upgrade considerations to future releases when the durability policies will be used to setup semi-sync and `-enable_semi_sync` is deprecated.
{{< /info >}}

{{< info >}}
In case the user notices any logs that look like the following, they should create an issue and report it -
```
invalid configuration - semi-sync should be setup according to durability policies, but enable_semi_sync is not set
```
```
invalid configuration - semi-sync should be setup according to durability policies, but the tablet is not primaryEligible
```
If the following log is noticed when all the components are upgraded, then it should also be reported -
```
invalid configuration - enabling semi sync even though not specified by durability policies. Possibly in the process of upgrading
```
{{< /info >}}
