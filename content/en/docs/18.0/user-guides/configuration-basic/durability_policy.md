---
title: Durability Policy
weight: 10
---

Vitess now supports a configurable interface for durability policies. Users can now define, in the interface, which tablets are eligible to be promoted to a PRIMARY instance. They can also specify the number of semi-sync acknowledgements it requires and the tablets which are eligible to send these acknowledgements.

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
 - ***semi_sync*** - This durability policy sets the number of required semi-sync acknowledgements to 1. It only allows REPLICA type tablets to send semi-sync acknowledgements. It returns NeutralPromoteRule for REPLICA tablet types, MustNotPromoteRule for everything else.
 - ***semi_sync_with_rdonly_ack*** - This durability policy sets the number of required semi-sync acknowledgements to 1. It allows REPLICA and RDONLY type tablets to acknowledge semi sync. It returns NeutralPromoteRule for REPLICA tablet types, MustNotPromoteRule for everything else.
 - ***none** (default)* - This durability policy does not set any semi-sync configuration. It returns NeutralPromoteRule for REPLICA tablet types, MustNotPromoteRule for everything else
 - ***cross_cell*** - This durability policy sets the number of required semi-sync acknowledgements to 1. It only allows REPLICA type tablets from a different cell than the current primary to send semi-sync acknowledgements. It returns NeutralPromoteRule for REPLICA tablet types, MustNotPromoteRule for everything else.
 - ***cross_cell_with_rdonly_ack*** - This durability policy sets the number of required semi-sync acknowledgements to 1. It only allows REPLICA and RDONLY type tablets from a different cell than the current primary to send semi-sync acknowledgements. It returns NeutralPromoteRule for REPLICA tablet types, MustNotPromoteRule for everything else.


[EmergencyReparentShard](../../configuration-advanced/reparenting/#emergencyreparentshard-emergency-reparenting) and [PlannedReparentShard](../../configuration-advanced/reparenting/#plannedreparentshard-planned-reparenting) will use the durability rules while choosing the correct candidate for promotion.

This configuration must be stored in the topo server in the keyspace record using the command [CreateKeyspace](../../../reference/programs/vtctldclient/vtctldclient_createkeyspace/) or [SetKeyspaceDurabilityPolicy](../../../reference/programs/vtctldclient/vtctldclient_setkeyspacedurabilitypolicy/).

