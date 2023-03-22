---
title: vtctld API Transition
weight: 3
---

TO DO: write an introduction

## vtctld and VTAdmin API methods

| Summary | `vtctld` API (old) | `vtctld` params (new) | `vtadmin` API (new) | `vtadmin` params (new)| Notes |
| -------- | -------- | -------- | -------- | -------- | -------- |
| Get cells | GET `/cells`     | -     | GET `/api/cells`    | - | - |
| Get keyspaces | GET `/keyspaces`     | -    | GET `/api/keyspaces`     | `cluster`: Optional cluster filter | This returns all keyspaces across all clusters discovered by VTAdmin |
| Get a keyspace | GET `/keyspaces/<keyspace>`     | -    | GET `/api/keyspace/<cluster>/<keyspace>`     | `cluster_id`: Optional cluster filter | In VTAdmin, a cluster must be specified |
| Perform an action on a keyspace | POST `/keyspaces/<keyspace>`     | `action`| PUT `/api/keyspace/<cluster>/<keyspace>/rebuild_keyspace_graph`, PUT `/api/keyspace/<cluster>/<keyspace>/remove_keyspace_cell`, PUT `/api/keyspace/<cluster><keyspace>/validate`, PUT `/keyspace/<cluster>/<keyspace>/validate/schema`, PUT `/api/keyspace/<cluster>/<keyspace>/validate/version`, DELETE `/api/keyspace/<cluster>/<keyspace>` | Refer to each method's parameters [here](https://github.com/vitessio/vitess/blob/main/go/vt/vtadmin/http/keyspaces.go) | In VTAdmin, each action has its own method and parameters  |
| Get keyspace tablets | GET `/keyspace/<keyspace>/tablets`     | `cell`, `cells` | GET `/api/tablets`     | `cluster`: Optional cluster filter | In VTAdmin, all tablets in a cluster are returned. Optionally, you can filter results to just one cluster. |
| Get keyspace tablets for a specific shard | GET `/keyspace/<keyspace>/tablets/<shard>`     | `cell`, `cells` | GET `/api/tablets` | `cluster`: Optional cluster filter | In VTAdmin, all tablets in a cluster are returned. Optionally, you can filter results to just one cluster. |
| Get shards | GET `/shards`     | - | GET `/api/keyspaces` | `cluster`: Optional cluster filter | In VTAdmin, to get all shards across all keyspaces, first get all keyspaces, and shards are returned within every keyspace [`keyspace.Shards`](https://github.com/vitessio/vitess/blob/main/proto/vtadmin.proto#L223) |
| Get a shard | GET `/shards/<shard>`     | - | GET `/api/keyspace/<cluster>/<keyspace>` | `cluster_id`: Optional cluster filter | In VTAdmin, to get a shard, first get the shard's keyspace, and then filter for the shard in [`keyspace.Shards`](https://github.com/vitessio/vitess/blob/main/proto/vtadmin.proto#L223) |
| Get SrvKeyspaces for a cell | GET `/srv_keyspace/<cell>`     | - | To be implemented in VTAdmin | - | Need to implement in VTAdmin |
| Get SrvKeyspaces for a specific keyspace | GET`/srv_keyspace/<cell>/<keyspace>`     | - | To be implemented in VTAdmin | - | Need to implement in VTAdmin |
| Get all tablets by cell and/or shard | GET `/tablets`     | `shard`,`cell` | GET `/api/tablets` | `cluster`: Optional cluster filter | In VTAdmin, all tablets across all clusters are returned. Optionally, you can filter results to just one cluster. |
| Get a tablet | GET `/tablets/<tablet>`     | - | GET `/api/tablets/<tablet>` | `cluster`: Optional cluster filter | - |
| Get tablet health | GET `/tablets/<tablet>/health`     | - | GET `/api/tablet/<tablet>/healthcheck` | `cluster`: Optional cluster filter | - |
| Perform an action on a tablet | POST `/tablets/<tablet>`    | `action` | GET `/api/tablet/<tablet>/full_status`, GET `/api/tablet/<tablet>/healthcheck`, GET `/api/tablet/<tablet>/ping`, PUT `/api/tablet/<tablet>/refresh`, PUT `/api/tablet/<tablet>/refresh_replication_source`, PUT `/api/tablet/<tablet>/reload_schema`, PUT `/api/tablet/<tablet>/set_read_only`, PUT `/api/tablet/<tablet>/set_read_write`, PUT `/api/tablet/<tablet>/start_replication`, PUT `/api/tablet/<tablet>/stop_replication`, POST `/api/tablet/<tablet>/externally_promoted`, DELETE `/api/tablet/<tablet>` | Refer to each method’s parameters [here](https://github.com/vitessio/vitess/blob/main/go/vt/vtadmin/http/tablets.go) | In VTAdmin, each action has its own method and parameters |
| Run a vtctl command | GET `/vtctl`    | `body`: array of vtctl commands | Unsupported by VTAdmin | - | We recommend using [vtctldclient](https://vitess.io/docs/16.0/reference/programs/vtctldclient/) for running any other vtctl commands |
| Apply schema changes | POST `/schema/apply`    | `keyspace`, `sql`, `ddl_strategy`, `replica_timeout_seconds` | Unsupported by VTAdmin | - | Unsupported by VTAdmin |
| Get vtctl features | GET `/features`    | - | GET `/debug/env` | - | Returns the current env vars for VTAdmin API. Must have [`http-no-debug` flag](https://vitess.io/docs/14.0/reference/programs/vtadmin/#http-server-flags) set to false. |