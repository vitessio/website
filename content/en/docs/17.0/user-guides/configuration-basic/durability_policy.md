---
title: Durability Policy
weight: 10
---

Vitess now supports a configurable interface for durability policies. Users can now define, in the interface, which tablets are eligible to be promoted to a PRIMARY instance. They can also specify the number of semi-sync ACKs it requires and the tablets which are eligible to send these ACKs.

The interface definition looks like:
```go
// Durabler is the interface which is used to get the promotion rules for candidates and the semi sync setup
type Durabler interface {
	promotionRule(*topodatapb.Tablet) promotionrule.CandidatePromotionRule
	semiSyncAckers(*topodatapb.Tablet) int
	isReplicaSemiSync(primary, replica *topodatapb.Tablet) bool
}
```

There are 3 implementations supported in this release:
 - ***semi_sync*** - This durability policy sets the number of required semi-sync ACKers to 1. It only allows Primary and Replica type servers to acknowledge semi sync. It returns NeutralPromoteRule for replica tablet types, MustNotPromoteRule for everything else.
 - ***none** (default)* - This durability policy does not set any semi-sync configurations. It returns NeutralPromoteRule for Primary and Replica tablet types, MustNotPromoteRule for everything else
 - ***cross_cell*** - This durability policy sets the number of required semi-sync ACKers to 1. It only allows Primary and Replica type servers from a different cell than the current primary to acknowledge semi sync. It returns NeutralPromoteRule for replica tablet types, MustNotPromoteRule for everything else.


[EmergencyReparentShard](../../configuration-advanced/reparenting/#emergencyreparentshard-emergency-reparenting) and [PlannedReparentShard](../../configuration-advanced/reparenting/#plannedreparentshard-planned-reparenting) will use the durability rules while choosing the correct candidate for promotion.

This configuration must be stored in the topo server in the keyspace record using the command [CreateKeyspace](../../../reference/programs/vtctldclient/vtctldclient_createkeyspace/) or [SetKeyspaceDurabilityPolicy](../../../reference/programs/vtctldclient/vtctldclient_setkeyspacedurabilitypolicy/).

