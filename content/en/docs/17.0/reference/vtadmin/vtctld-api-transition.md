---
title: vtctld API Transition
weight: 3
---

TO DO: write an introduction

## vtctld and VTAdmin API methods

| Summary | `vtctld` API (old) | `vtctld` params (old) | `vtadmin` API (new) | `vtadmin` params (new)| Notes |
| -------- | ------ | -------- | ------ | -------- | -------- |
| Get cells | GET `/cells`     | -     | GET `/api/cells`    | - | - |
| Get keyspaces | GET `/keyspaces`     | -    | GET `/api/keyspaces`     | <li>`cluster`: Optional cluster filter</li> | This returns all keyspaces across all clusters discovered by VTAdmin |
| Get a keyspace | GET `/keyspaces/<keyspace>`     | -    | GET `/api/keyspace/<cluster>/<keyspace>` | <li>`cluster_id`: Optional cluster filter</li> | In VTAdmin, a cluster must be specified |
| Rebuild keyspace graph | POST `/keyspaces/<keyspace>`     | `action`| PUT `/api/keyspace/<cluster>/<keyspace>/rebuild_keyspace_graph` | <li>`allow_partial`: Specifies whether a SNAPSHOT keyspace is allowed to serve with an incomplete set of shards. Ignored for all other types of keyspaces</li><li>`cells`: Specifies a comma-separated list of cells to update</li>  | - |
| Remove keyspace cell | POST `/keyspaces/<keyspace>`     | `action`| PUT `/api/keyspace/<cluster>/<keyspace>/remove_keyspace_cell` | <li>`cell`: Cell to be removed</li> <li>`force`: Proceed even if the cell's topology server cannot be reached. The assumption is that you turned down the entire cell, and just need to update the global topo data.</li> <li>`recursive`: Also delete all tablets in that cell belonging to the specified keyspace.</li> | - |
| Validate keyspace | POST `/keyspaces/<keyspace>`     | `action`| PUT `/api/keyspace/<cluster><keyspace>/validate` | <li>`ping_tablets`: Indicates whether all tablets should be pinged during the validation process.</li> | - |
| Validate keyspace schema | POST `/keyspaces/<keyspace>`     | `action`| PUT `/keyspace/<cluster>/<keyspace>/validate/schema` | - | -  |
| Validate keyspace version | POST `/keyspaces/<keyspace>`     | `action`| PUT `/api/keyspace/<cluster>/<keyspace>/validate/version` | - | -  |
| Delete keyspace | POST `/keyspaces/<keyspace>`     | `action`| DELETE `/api/keyspace/<cluster>/<keyspace>` | <li>`recursive`: Recursively delete all shards in the keyspace. Otherwise, the keyspace must be empty (have no shards), or DeleteKeyspace returns an error</li> | -  |
| Get keyspace tablets | GET `/keyspace/<keyspace>/tablets`     | `cell`, `cells` | GET `/api/tablets`     | <li>`cluster`: Optional cluster filter</li> | In VTAdmin, all tablets in a cluster are returned. Optionally, you can filter results to just one cluster. |
| Get keyspace tablets for a specific shard | GET `/keyspace/<keyspace>/tablets/<shard>`     | `cell`, `cells` | GET `/api/tablets` | <li>`cluster`: Optional cluster filter</li> | In VTAdmin, all tablets in a cluster are returned. Optionally, you can filter results to just one cluster.  |
| Get shards | GET `/shards`     | - | GET `/api/keyspaces` | <li>`cluster`: Optional cluster filter</li> | In VTAdmin, to get all shards across all keyspaces, first get all keyspaces, and shards are returned within every keyspace [`keyspace.Shards`](https://github.com/vitessio/vitess/blob/main/proto/vtadmin.proto#L223) |
| Get a shard | GET `/shards/<shard>`     | - | GET `/api/keyspace/<cluster>/<keyspace>` | <li>`cluster_id`: Optional cluster filter</li> | In VTAdmin, to get a shard, first get the shard's keyspace, and then filter for the shard in [`keyspace.Shards`](https://github.com/vitessio/vitess/blob/main/proto/vtadmin.proto#L223) |
| Get SrvKeyspaces for a cell | GET `/srv_keyspace/<cell>`     | - | To be implemented in VTAdmin | - | Need to implement in VTAdmin |
| Get SrvKeyspaces for a specific keyspace | GET`/srv_keyspace/<cell>/<keyspace>`     | - | To be implemented in VTAdmin | - | Need to implement in VTAdmin |
| Get all tablets by cell and/or shard | GET `/tablets`     | `shard`,`cell` | GET `/api/tablets` | <li>`cluster`: Optional cluster filter</li> | In VTAdmin, all tablets across all clusters are returned. Optionally, you can filter results to just one cluster. |
| Get a tablet | GET `/tablets/<tablet>`     | - | GET `/api/tablets/<tablet>` | <li>`cluster`: Optional cluster filter</li> | - |
| Get tablet health | GET `/tablets/<tablet>/health`     | - | GET `/api/tablet/<tablet>/healthcheck` | <li>`cluster`: Optional cluster filter</li> | - |
| Perform an action on a tablet | POST `/tablets/<tablet>`    | `action` | GET `/api/tablet/<tablet>/full_status`, GET `/api/tablet/<tablet>/healthcheck`, GET `/api/tablet/<tablet>/ping`, PUT `/api/tablet/<tablet>/refresh`, PUT `/api/tablet/<tablet>/refresh_replication_source`, PUT `/api/tablet/<tablet>/reload_schema`, PUT `/api/tablet/<tablet>/set_read_only`, PUT `/api/tablet/<tablet>/set_read_write`, PUT `/api/tablet/<tablet>/start_replication`, PUT `/api/tablet/<tablet>/stop_replication`, POST `/api/tablet/<tablet>/externally_promoted`, DELETE `/api/tablet/<tablet>` | Refer to each method’s parameters [here](https://github.com/vitessio/vitess/blob/main/go/vt/vtadmin/http/tablets.go) | In VTAdmin, each action has its own method and parameters |
| Run a vtctl command | GET `/vtctl`    | `body`: array of vtctl commands | Unsupported by VTAdmin | - | We recommend using [vtctldclient](https://vitess.io/docs/16.0/reference/programs/vtctldclient/) for running any other vtctl commands |
| Apply schema changes | POST `/schema/apply`    | `keyspace`, `sql`, `ddl_strategy`, `replica_timeout_seconds` | Unsupported by VTAdmin | - | Unsupported by VTAdmin |
| Get vtctl features | GET `/features`    | - | GET `/debug/env` | - | Returns the current env vars for VTAdmin API. Must have [`http-no-debug` flag](https://vitess.io/docs/14.0/reference/programs/vtadmin/#http-server-flags) set to false. |