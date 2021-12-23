---
title: File:Position based VReplication
description:
weight: 1
---

## Problem Statement

In order to support migration from legacy databases that may not have GTID turned on, there is a need for VReplication to support file:position based tracking.

It is understood that this type of tracking will work only for a single physical mysql source. Replication cannot be automatically resumed from a different source. In the worst case, it is possible to manually figure out the continuation point, and change the VReplication parameters to resume replication from a different source.

Supporting file:position based vreplication will allow for one-time "shoveling" of data from an existing source to a destination. It could also be used to continuously keep the target data up-to-date just like we do for resharding. In this situation, it should also be possible to reverse the replication after a cut-over from legacy to vitess. This will give us the option to rollback a migration should anything go wrong.

## Requirements

The VReplication design is entrenched in using the concept of GTID. So, it will be substantial work to change its DNA to recognize file:position based binlog tracking. However, Vitess has the design elements needed to support multiple GTID formats. This means that we can build a low level abstraction layer that encapsulates a file:position as a GTID. There are situations where this abstraction breaks down. We'll have to handle those corner cases.

### Forcing file:position based tracking

Although not anticipated, it's possible that a user may want to use file:position based tracking even if the source has GTID turned on. This means that file:position based tracking should not be inferred through auto-detection.

An environment variable (like MYSQL_FLAVOR) should not be used because the tracking mode depends on a specific source. Since VReplication can have multiple sources, this should be dictated by the source.

### Current position

In GTID mode, the current position is guaranteed to be at a transaction boundary. But a file:position based binlog can report a position for every event, including stray ones that are not material for replication. In such cases, the mechanism of getting the current position from the source and asking the target to stop at that position should work no matter what that position is.

### Single Source

As mentioned above, only a fixed mysql instance will be supported as source.

## Design

A prototype work was done by PlanetScale for file:position based tracking. This was developed as an "RDS" flavor. This is because RDS did not support GTIDs when this was developed. With PlanetScale's permission, this work will be leveraged to implement the new proposal. The work will be published as part of the Vitess license. The following high level tasks will need to be performed.

* **Rename rdsFlavor->filePosFlavor**: This rename will more accurately represent the functionality.
* **Flavor as connection parameter**: Since we need to control the flavor on a per-source basis, the best way to achieve this is to extend the `ConnParams` structure to include a `Flavor`. If empty, auto-detection will be used. If specified, the name will map to a registered flavor implementation. This approach will retain backward compatibility.
* **Track sub-flavor**: Since we want to support file:position based tracking even if GTID is turned on, we need the ability to recognize GTID events. This means that we have to understand MySQL and MariaDB flavors under the covers.
* **Standardize on when to send GTID**: Currently, the binlog dictates when to report a GTID. In some cases, it's before the next transaction, and sometimes it's within. We'll change the design to report the GTID just before the "COMMIT". This is the point where it's actually useful. Knowing exactly when a GTID will be received will simplify the design of the vplayer.
* **Introduce Pseudo-GTID**: In order to report positions outside of transaction boundaries, one possibility is to report them as pseudo-GTIDs. Although it's possible to convert them to fake empty transactions, it may be more readable to use a separate category.
* **Stop Position**: The vplayer currently uses ambiguous rules about how it handles the case where a stop position was exceeded. As part of this change, we'll standardize on: _A stop position is considered to be successfully reached if the new position is greater than or equal to the specified position_. The main motivation for this change is that the possibility of position mismatch is higher in the case of file:pos tracking. We're likely to hit many false positives if we're too strict.

## Future improvements

Once a GTID gets more implicitly associated with saveable events, we can later deprecate GTID as an explicit event. Instead, we can send the GTID as part of the COMMIT or DDL message, which is where it's actually used. This will allow us to tighten some code in vplayer. Without this, the association of GTID with a COMMIT is more ambiguous, and there's extra code to glue them together.
