---
title: Role-Based Access Control
---

# Overview

VTAdmin provides an (optional) role-based access control (RBAC) system for deployments that need to, or would like to, restrict access to specific resources to specific users.

In VTAdmin, RBAC is governed by two distinct layers:
- **Authentication**: Given a request, determine _who_ is attempting to take an action on a resource
- **Authorization**: Given an actor (obtained from the authentication layer), determine if that actor is allowed to take a certain action on a certain resource.

Let's discuss each in turn.

## Authentication

VTAdmin uses a plugin-based architecture for deployments to provide their own authentication implementation specific to their environment and needs.

The authentication plugin is installed as both an HTTP middleware and gRPC interceptor, and must implement the following [interface][authn_interface]:

```go
type Authenticator interface {
    // Authenticate returns an Actor given a context. This method is called
	// from the stream and unary grpc server interceptors, and are passed the
	// stream and request contexts, respectively.
	//
	// Returning an error from the authenticator will fail the request. To
	// denote an authenticated request, return (nil, nil) instead.
	Authenticate(ctx context.Context) (*Actor, error)
	// AuthenticateHTTP returns an actor given an http.Request.
	//
	// Returning an error from the authenticator will fail the request. To
	// denote an authenticated request, return (nil, nil) instead.
	AuthenticateHTTP(r *http.Request) (*Actor, error)
}
```
<br/>

If running with an authentication plugin installed, VTAdmin will invoke its `Authenticate` method on all incoming gRPC requests, and its `AuthenticateHTTP` method on all incoming HTTP requests.

Returning an error from either of these methods will fail the request with an `UNAUTHENTICATED` code for gRPC requests and an `UNAUTHORIZED` response for HTTP requests.
In order to indicate "no authenticated actor" to the authorization layer, the methods must return `(nil, nil)` instead.

### Available Plugins

VTAdmin currently provides no authentication plugins out of the box, though this may change in future releases.

However, users are free to define their own implementations suited to the needs of their specific deployment and environment.
As an example, [here][example_authn] is an authentication plugin that extracts a "user" key from an HTTP cookie or gRPC incoming metadata.

### Installing Plugins

VTAdmin supports two ways of installing an authentication plugin.

For universal support, users may recompile `vtadmin-api` after adding their authentication plugin file within `go/vt/vtadmin/rbac/plugin_<your_authn_name>.go`.
If following this process, you must ensure to call `RegisterAuthenticator("your_authn_name", yourAuthnConstructor())` in an `init` function.
This is the pattern followed by other components of Vitess; [tracing plugins][jaeger_plugin_example] are one of many you can refer to.

If you plan to run `vtadmin-api` on Linux, FreeBSD, or macOS, you can also install your authentication plugin using the [Go plugin API][go_plugin_pkg_docs].
If following this process, your Authenticator must be built with `go build -buildmode=plugin`, and its `main` package must expose a function of the following name and type:

```go
package main

import "vitess.io/vitess/go/vt/vtadmin/rbac"

func NewAuthenticator() rbac.Authenticator { return ... /* your implementation here */ }
```

### Configuration

Finally, to instruct VTAdmin to use your Authenticator, specify its name in the `"authenticator"` key in your `rbac.yaml`:

```yaml
authenticator: "./path/to/your_authn_name.so" # or just "your_authn_name" (see below)
```
<br/>

If the name ends in `.so`, VTAdmin will assume it is a Go plugin (the second option described in the previous section).
VTAdmin will attempt to open the plugin and find a function named `NewAuthenticator` that returns an `rbac.Authenticator` implementation.
If any of this fails, VTAdmin will refuse to start; attempting to use this option on platforms not supported by the Go plugin API will result in undefined behavior.

Otherwise, VTAdmin will assume it was (re-)compiled with a `plugin_<your_authn_name>.go` file that invoked `RegisterAuthenticator` with that name.
If there is no plugin registered with that name, VTAdmin will refuse to start.

## Authorization

Unlike authentication, which occurs at the incoming request boundary (both HTTP and gRPC), authorization happens within the `vtadmin.API` layer itself.

In each method, the API extracts any `Actor` from the authentication layer, and performs one or more checks to see if that actor is allowed to perform the actions necessary to fulfill the request.
We'll go over how this works in more detail, but as an example, here's a snippet of the `GetClusters` handler:

```go
func (api *API) GetClusters(ctx context.Context, req *vtadminpb.GetClustersRequest) (*vtadminpb.GetClustersResponse, error) {
	clusters, _ := api.getClustersForRequest(nil) // `nil` implies "all clusters"
	resp := &vtadminpb.GetClustersResponse{
		Clusters: make([]*vtadminpb.Cluster, 0, len(clusters)),
	}

	for _, c := range clusters {
		if !api.authz.IsAuthorized(ctx, c.ID, rbac.ClusterResource, rbac.GetAction) {
			continue
		}

		resp.Clusters = append(resp.Clusters, &vtadminpb.Cluster{
			Id:   c.ID,
			Name: c.Name,
		})
	}

    return resp, nil
}
```
<br/>

First, it's necessary to note that there's a shim layer in the HTTP/gRPC middlewares that puts any `Actor` from an authentication plugin into the `ctx` that gets passed to the method you see here.
The details of how this works are not particularly relevant to this documentation, but you can refer to [these][http_authn_handler] [files][grpc_authn_interceptors] if you would like to learn more.

Second, it is possible to run VTAdmin with authorization but without an authentication plugin installed.
If you do this, all requests will implicitly be made by the "unauthenticated" actor, and therefore may only access resources that permit the wildcard `Subject` (more on RBAC configs in a bit!).

Third, and most important: note that being unauthorized to access to a `(cluster, resource, action)` **does not fail the overall request**.
If a request involves multiple clusters, and the actor is permitted to access a subset of them, the request will proceed for those clusters.
If a user tries to access a cluster they are not permitted to, **including a cluster that does not exist**, they will be unable to tell if
(1) there is simply no data; (2) they do not have access to the cluster; or (3) the cluster exists at all.
This is by design, to prevent a malicious actor from being able to enumerate resources by brute force and interpreting the authorization failure responses.

### Configuration

Authorization rules are specified as a list under the `rules` key of your `rbac.yaml` configuration file.
Each rule is a 4-key map, corresponding to the 4-tuple of `(resource, cluster, subject, action)`.

In order to allow more consisely-expressed configurations, each "rule" element actually takes a list of `clusters`, `subjects`, and `actions` (**but only a singular `resource`!**), as well as a wildcard (`*`) to stand in for "any {resource|cluster|subject|action}".
At startup, `vtadmin-api` will expand these rulesets and wildcards into the individual 4-tuples discussed previously.

#### Example

For example, take the following configuration:

```yaml
rules:
  - resource: "*"
    actions:
    - "get"
    - "ping"
    subjects: ["*"]
    clusters: ["*"]

  - resource: "*"
    actions:
    - "create"
    - "delete"
    - "put"
    subjects:
    - "user:andrew"
    - "role:admin"
    clusters: ["*"]

  - resource: "Shard"
    actions:
    - "emergency_failover_shard"
    - "planned_failover_shard"
    subjects:
    - "role:admin"
    clusters:
    - "local"
```

This permits the following:
1. Any subject can `get` or `ping` any resource in any cluster.
2. Any user with the name "andrew" or role of "admin" can `create`, `delete`, or `put` any resource in any cluster.
3. Any user with the role of "admin" can perform both emergency and planned failover operations on a `Shard` in _only_ the cluster with the id of "local".

### Clusters and Subjects

`cluster` and `subject` values depend entirely on the details of your particular vtadmin deployment.
Possible values for `cluster`, aside from the wildcard, are the `id` of any cluster you inform `vtadmin-api` of (either via flags at start time or dynamically).

`subject` values should be prefixed with either `user:` or `role:`.
In the case of `user:`, vtadmin's authorization check will verify the actor's `Name` value matches.
In the case of `role:`, it will verify that one of the actor's `Roles` values matches.
In code:

```go
func (r *Rule) Allows(clusterID string, action Action, actor *Actor) bool {
	if r.clusters.HasAny("*", clusterID) {
		if r.actions.HasAny("*", string(action)) {
			if r.subjects.Has("*") {
				return true
			}

			if actor == nil {
				return false
			}

			if r.subjects.Has(fmt.Sprintf("user:%s", actor.Name)) {
				return true
			}

			for _, role := range actor.Roles {
				if r.subjects.Has(fmt.Sprintf("role:%s", role)) {
					return true
				}
			}
		}
	}

	return false
}
```

Note that if you are using just authorization without authentication, you must use the wildcard subject in your rules.

### Resources and Actions

The following table lists all current resources vtadmin has, and the actions that can be performed on them.
Note that it's technically possible to specify a rule for an action that cannot actually be performed on a particular resource (e.g. an action of `planned_failover_shard` on a resource of `Schema`), but this has no effect on the rest of your rules.

| API | Rule(s) Needed `(<action>, <resource>)` form |
| :--- | :--- |
| `CreateKeyspace` | `(create, Keyspace)` |
| `CreateShard` | `(create, Shard)` |
| `DeleteKeyspace` | `(delete, Keyspace)` |
| `DeleteShards` | `(delete, Shard)` |
| `DeleteTablet` | `(delete, Tablet)` |
| `EmergencyFailoverShard` | `(emergency_failover_shard, Shard)` |
| `FindSchema` | `(get, Schema)` |
| `GetBackups` | `(get, Backup)` |
| `GetCellInfos` | `(get, CellInfo)` |
| `GetCellsAliases` | `(get, CellsAlias)` |
| `GetClusters` | `(get, Cluster)` |
| `GetGates` | `(get, VTGate)` |
| `GetKeyspace` | `(get, Keyspace)` |
| `GetKeyspaces` | `(get, Keyspace)` |
| `GetSchema` | `(get, Schema)` |
| `GetSchemas` | `(get, Schema)` |
| `GetShardReplicationPositions` | `(get, ShardReplicationPosition)` |
| `GetSrvVSchema` | `(get, SrvVSchema)` |
| `GetSrvVSchemas` | `(get, SrvVSchema)` |
| `GetTablet` | `(get, Tablet)` |
| `GetTablets` | `(get, Tablet)` |
| `GetVSchema` | `(get, VSchema)` |
| `GetVSchemas` | `(get, VSchema)` |
| `GetVtctlds` | `(get, Vtctld)` |
| `GetWorkflow` | `(get, Workflow)` |
| `GetWorkflows` | `(get, Workflow)` |
| `PingTablet` | `(ping, Tablet)` |
| `PlannedFailoverShard` | `(planned_failover_shard, Shard)` |
| `RefreshState` | `(put, Tablet)` |
| `RefreshTabletReplicationSource` | `(refresh_tablet_replication_source, Tablet)` |
| `ReloadSchemas` | `(reload, Schema)` |
| `RunHealthCheck` | `(get, Tablet)` |
| `SetReadOnly` | `(manage_tablet_writability, Tablet)` |
| `SetReadWrite` | `(manage_tablet_writability, Tablet)` |
| `StartReplication` | `(manage_tablet_replication, Tablet)` |
| `StopReplication` | `(manage_tablet_replication, Tablet)` |
| `TabletExternallyPromoted` | `(tablet_externally_promoted, Shard)` |
| `VTExplain` | `(get, VTExplain)` |
| `ValidateKeyspace` | `(put, Keyspace)` |
| `ValidateSchemaKeyspace` | `(put, Keyspace)` |
| `ValidateVersionKeyspace` | `(put, Keyspace)` |

[authn_interface]: https://github.com/vitessio/vitess/blob/46cb4679c198c96fbe7b51f40219d8196f4284a7/go/vt/vtadmin/rbac/authentication.go#L34-L50
[example_authn]: https://gist.github.com/ajm188/5b2c7d3ca76004a297e6e279a54c2299

[jaeger_plugin_example]: https://github.com/vitessio/vitess/blob/46cb4679c198c96fbe7b51f40219d8196f4284a7/go/trace/plugin_jaeger.go#L32-L36
[go_plugin_pkg_docs]: https://pkg.go.dev/plugin

[http_authn_handler]: https://github.com/vitessio/vitess/blob/01eab00275bbd73855c8c92876f73deb7ef62259/go/vt/vtadmin/http/handlers/authentication.go#L25-L42
[grpc_authn_interceptors]: https://github.com/vitessio/vitess/blob/01eab00275bbd73855c8c92876f73deb7ef62259/go/vt/vtadmin/rbac/authentication.go#L52-L88
