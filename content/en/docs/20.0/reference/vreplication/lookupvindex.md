---
title: LookupVindex
description: Create, backfill, and externalize Lookup Vindexes
weight: 60
---

[`LookupVindex`](../../../reference/programs/vtctldclient/vtctldclient_lookupvindex/) is a command used to create **and** backfill
a [Lookup Vindex](../../../reference/features/vindexes/#lookup-vindex-types) automatically for a table that already
exists, and may have a significant amount of data in it already.

Internally, the [`LookupVindex create`](../../../reference/programs/vtctldclient/vtctldclient_lookupvindex/vtctldclient_lookupvindex_create/) command uses
VReplication for the backfill process, until the lookup Vindex is "in sync". Then the normal process for
adding/deleting/updating rows in the lookup Vindex via the usual
[transactional flow when updating the "owner" table for the Vindex](../../../reference/features/vindexes/#lookup-vindex-types)
takes over.

## Command

Please see the [`LookupVindex` command reference](../../../reference/programs/vtctldclient/vtctldclient_lookupvindex/) for a full list of sub-commands and their flags.

## Additional Information

Please see the user guide for examples of [Creating a Lookup Vindex](../../../user-guides/configuration-advanced/createlookupvindex/) for more information on how to use this command.
