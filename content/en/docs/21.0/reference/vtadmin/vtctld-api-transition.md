---
title: vtctld API Transition
weight: 3
---

The following table highlights old vtctld API methods and their counterparts in the newer VTAdmin API. 

Some methods do not have a 1:1 mapping from vtctld to VTAdmin. These cases include:
- vtctld methods that are split out into many different VTAdmin methods (ex. keyspace and tablet action methods)
- vtctld methods that are not supported in VTAdmin (ex. executing a vtctl command)
- vtctld methods that we plan to support, but do not currently support, in VTAdmin 
- VTAdmin methods that were not supported by vtctld API; noted here because they may be useful

One of the main differences between vtctld and VTAdmin API is that VTAdmin API returns results across all clusters discovered by VTAdmin [cluster discovery](https://vitess.io/docs/17.0/reference/vtadmin/cluster_discovery/). VTAdmin API methods that accept a `cluster_id` parameter are methods that will return results from all clusters, unless the aforementioned filter parameter is provided.

## vtctld and VTAdmin API methods

| Summary | `vtctld` API (old) | `vtctld` params (old) | `vtadmin` API (new) | `vtadmin` params (new)| Notes |
| -------- | ------ | -------- | ------ | -------- | -------- |
| Get cells | GET `/cells` | - | GET `/api/cells` | - | - |
| Get keyspaces | GET `/keyspaces` | - | GET `/api/keyspaces` | <li>`cluster_id`: Optional cluster filter</li> | - |
| Get a keyspace | GET `/keyspaces/<keyspace>` | - | GET `/api/keyspace/<cluster>/<keyspace>` | <li>`cluster_id`: Optional cluster filter</li> | - |
| Rebuild keyspace graph | - | - | PUT `/api/keyspace/<cluster>/<keyspace>/rebuild_keyspace_graph` | <li>`allow_partial`: Specifies whether a SNAPSHOT keyspace is allowed to serve with an incomplete set of shards. Ignored for all other types of keyspaces</li><li>`cells`: Specifies a comma-separated list of cells to update</li>  | - |
| Remove keyspace cell | - | - | PUT `/api/keyspace/<cluster>/<keyspace>/remove_keyspace_cell` | <li>`cell`: Cell to be removed</li> <li>`force`: Proceed even if the cell's topology server cannot be reached. The assumption is that you turned down the entire cell, and just need to update the global topo data.</li> <li>`recursive`: Also delete all tablets in that cell belonging to the specified keyspace.</li> | - |
| Validate keyspace | POST `/keyspaces/<keyspace>` | `action`: `ValidateKeyspace` | PUT `/api/keyspace/<cluster><keyspace>/validate` | <li>`ping_tablets`: Indicates whether all tablets should be pinged during the validation process</li> | - |
| Validate keyspace schema | POST `/keyspaces/<keyspace>` | `action`: `ValidateSchemaKeyspace` | PUT `/keyspace/<cluster>/<keyspace>/validate/schema` | - | -  |
| Validate keyspace version | POST `/keyspaces/<keyspace>` | `action`: `ValidateVersionKeyspace` | PUT `/api/keyspace/<cluster>/<keyspace>/validate/version` | - | -  |
| Validate keyspace permissions | POST `/keyspaces/<keyspace>` | `action`: `ValidatePermissionsKeyspace` | To be implemented in VTAdmin | - | Need to implement in VTAdmin |
| Delete keyspace | - | - | DELETE `/api/keyspace/<cluster>/<keyspace>` | <li>`recursive`: Recursively delete all shards in the keyspace. If not specified or set to false, the keyspace must be empty (have no shards), or DeleteKeyspace returns an error</li> | -  |
| Get keyspace tablets | GET `/keyspace/<keyspace>/tablets` | `cell`, `cells` | GET `/api/tablets` | <li>`cluster_id`: Optional cluster filter</li> | - |
| Get keyspace tablets for a specific shard | GET `/keyspace/<keyspace>/tablets/<shard>` | `cell`, `cells` | GET `/api/tablets` | <li>`cluster_id`: Optional cluster filter</li> | -  |
| Get shards | GET `/shards` | - | GET `/api/keyspaces` | <li>`cluster_id`: Optional cluster filter</li> | In VTAdmin, to get all shards across all keyspaces, first get all keyspaces, and shards are returned within every keyspace [`keyspace.Shards`](https://github.com/vitessio/vitess/blob/main/proto/vtadmin.proto#L223) |
| Get a shard | GET `/shards/<shard>` | - | GET `/api/keyspace/<cluster>/<keyspace>` | <li>`cluster_id`: Optional cluster filter</li> | In VTAdmin, to get a shard, first get the shard's keyspace, and then filter for the shard in [`keyspace.Shards`](https://github.com/vitessio/vitess/blob/main/proto/vtadmin.proto#L223) |
| Validate a shard | POST `/shards/<shard>` | `action`: `ValidateShard` | PUT `/api/shard/<cluster>/<keyspace>/<shard>/validate` | <li>`ping_tablets`: Indicates whether all tablets should be pinged during the validation process.</li> | - |
| Validate shard schema | POST `/shards/<shard>` | `action`: `ValidateSchemaShard` | To be implemented in VTAdmin | - | Need to implement in VTAdmin |
| Validate shard version | POST `/shards/<shard>` | `action`: `ValidateVersionShard` | PUT `/api/shard/<cluster>/<keyspace>/<shard>/validate_version` | - | - |
| Validate shard permissions | POST `/shards/<shard>` | `action`: `ValidatePermissionsShard` | To be implemented in VTAdmin | - | Need to implement in VTAdmin |
| Get SrvKeyspaces for a cell | GET `/srv_keyspace/<cell>` | - | GET `/api/srvkeyspaces` | <li>`cell`: Optional cell filter</li><li>`cluster_id`: Optional cluster filter</li> | The VTAdmin method returns all SrvKeyspaces across all clusters and their keyspaces if the `cluster_id` parameter is not provided. |
| Get SrvKeyspaces for a specific keyspace | GET`/srv_keyspace/<cell>/<keyspace>` | - | GET `/api/srvkeyspace/<cluster>/<keyspace>` | <li>`cell`: Optional cell filter</li> | - |
| Get all tablets by cell and/or shard | GET `/tablets` | `shard`,`cell` | GET `/api/tablets` | <li>`cluster_id`: Optional cluster filter</li> | - |
| Get a tablet | GET `/tablets/<tablet>` | - | GET `/api/tablets/<tablet>` | <li>`cluster_id`: Optional cluster filter</li> | - |
| Get tablet health | GET `/tablets/<tablet>/health` | - | GET `/api/tablet/<tablet>/healthcheck` | <li>`cluster_id`: Optional cluster filter</li> | - |
| Get a tablet's full status | - | - | GET `/api/tablet/<tablet>/full_status` | <li>`cluster_id`: Optional cluster filter</li> | - |
| Ping tablet | POST `/tablets/<tablet>` | `action`: `PingTablet` | GET `/api/tablet/<tablet>/ping` | <li>`cluster_id`: Optional cluster filter</li> | - |
| Refresh tablet | POST `/tablets/<tablet>` | `action`: `RefreshState` | PUT `/api/tablet/<tablet>/refresh` | <li>`cluster_id`: Optional cluster filter</li> | - |
| Refresh tablet replication source | - | - | PUT `/api/tablet/<tablet>/refresh_replication_source`| <li>`cluster_id`: Optional cluster filter</li>  | - |
| Reload tablet schema | POST `/tablets/<tablet>` | `action`: `ReloadSchema` | PUT `/api/tablet/<tablet>/reload_schema` | <li>`cluster_id`: Optional cluster filter</li> | - |
| Set tablet to read-only | - | - | PUT `/api/tablet/<tablet>/set_read_only`| <li>`cluster_id`: Optional cluster filter</li> | - |
| Set tablet to read-write | - | - | PUT `/api/tablet/<tablet>/set_read_write` | <li>`cluster_id`: Optional cluster filter</li> | - |
| Start replication on tablet | - | - | PUT `/api/tablet/<tablet>/start_replication` | <li>`cluster_id`: Optional cluster filter</li> | - |
| Stop replication on tablet | - | - | PUT `/api/tablet/<tablet>/stop_replication` | <li>`cluster_id`: Optional cluster filter</li> | - |
| Mark tablet as externally promoted | - | - | POST `/api/tablet/<tablet>/externally_promoted` |  <li>`cluster_id`: Optional cluster filter</li>  | - |
| Delete tablet | POST `/tablets/<tablet>` | `action`: `DeleteTablet` | DELETE `/api/tablet/<tablet>` | <li>`allow_primary`: Whether or not the primary can be deleted</li> <li>`cluster_id`: Optional cluster filter </li> | - |
| Run a vtctl command | GET `/vtctl` | `body`: array of vtctl commands | Unsupported by VTAdmin | - | We recommend using [vtctldclient](https://vitess.io/docs/16.0/reference/programs/vtctldclient/) for running any other vtctl commands |
| Apply schema changes | POST `/schema/apply` | `keyspace`, `sql`, `ddl_strategy`, `replica_timeout_seconds` | Unsupported by VTAdmin | - | Unsupported by VTAdmin |
| Get vtctl features | GET `/features` | - | GET `/debug/env` | - | Returns the current env vars for VTAdmin API. Must have [`http-no-debug` flag](https://vitess.io/docs/14.0/reference/programs/vtadmin/#http-server-flags) set to false. |
