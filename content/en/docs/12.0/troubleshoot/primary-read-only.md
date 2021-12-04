---
title: Primary starts up read-only
description: Debug common issues with Vitess
weight: 5
---

## Primary starts up read-only

To prevent accidentally accepting writes, our default my.cnf settings tell MySQL to always start up read-only. If the primary MySQL gets restarted, it will thus come back read-only until you intervene to confirm that it should accept writes. You can use the [`SetReadWrite`](../../reference/programs/vtctl/#setreadwrite) command to do that.

However, usually if something unexpected happens to the primary, it's better to reparent to a different replica with [`EmergencyReparentShard`](../../reference/programs/vtctl/#emergencyreparentshard). If you need to do planned maintenance on the primary, it's best to first reparent to another replica with [`PlannedReparentShard`](../../reference/programs/vtctl/#plannedreparentshard).

