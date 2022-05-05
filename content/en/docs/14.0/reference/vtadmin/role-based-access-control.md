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

Returning an error from either of these methods will fail the request with either an `UNAUTHENTICATED` code for gRPC requests and an `UNAUTHORIZED` response for HTTP requests.
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

TODO:
- describe config structure
- list and describe actions/resources


[authn_interface]: https://github.com/vitessio/vitess/blob/46cb4679c198c96fbe7b51f40219d8196f4284a7/go/vt/vtadmin/rbac/authentication.go#L34-L50
[example_authn]: https://gist.github.com/ajm188/5b2c7d3ca76004a297e6e279a54c2299

[jaeger_plugin_example]: https://github.com/vitessio/vitess/blob/46cb4679c198c96fbe7b51f40219d8196f4284a7/go/trace/plugin_jaeger.go#L32-L36
[go_plugin_pkg_docs]: https://pkg.go.dev/plugin

[http_authn_handler]: https://github.com/vitessio/vitess/blob/01eab00275bbd73855c8c92876f73deb7ef62259/go/vt/vtadmin/http/handlers/authentication.go#L25-L42
[grpc_authn_interceptors]: https://github.com/vitessio/vitess/blob/01eab00275bbd73855c8c92876f73deb7ef62259/go/vt/vtadmin/rbac/authentication.go#L52-L88
