---
title: vtadmin
---

## Flags 

These flags are provided to the `vtadmin` process. They are also referenced in [cmd/vtadmin/main.go](https://github.com/vitessio/vitess/blob/main/go/cmd/vtadmin/main.go).

### Common Flags

| Name | Required | Type | Default | Definition |
| -------- | --------- | --------- | --------- |--------- |
| `addr` | **Required** | string | ":15000" | The address for `vtadmin` to serve on. |
| `lame-duck-duration` | Optional | [time.Duration][duration] | "5s" | The length of the lame duck period at shutdown. |
| `lmux-read-timeout` | Optional | [time.Duration][duration] | "1s" | How long to spend connection muxing. | 

[duration]: https://pkg.go.dev/time#ParseDuration

### Cluster Config Flags

One of `cluster`, `cluster-defaults`, or `cluster-config` file is required. Multiple configurations are permitted; precedence is noted below.

| Name | Definition |
| -------- | --------- | 
| `cluster` | Per-cluster configuration. Any values here take precedence over those defined by the `cluster-defaults` and/or `cluster-config` flags. | 
| `cluster-config` | Path to a yaml cluster configuration; for reference, see the example [clusters.yaml](https://github.com/vitessio/vitess/blob/main/doc/vtadmin/clusters.yaml). | 
| `cluster-defaults` | Default options for all clusters. |
| `enable-dynamic-clusters` | Defaults to `false`. Whether to enable dynamic clusters that are set by request header cookies or gRPC metadata. | 

### Tracing Flags

| Name | Required | Type | Default | Definition |
| -------- | --------- | --------- | --------- |--------- |
| `grpc-tracing` | Optional | boolean | `false` | If true, enables tracing on the gRPC server. |
| `http-tracing` | Optional | boolean | `false` | If true, enables tracing on the HTTP server. |
| `tracer` | Optional | string | "noop" | Which tracing service to use; see [go/trace/trace.go](https://github.com/vitessio/vitess/blob/main/go/trace/trace.go). |
| `tracing-enable-logging` | Optional | boolean | `false` | Whether to enable logging in the tracing service; see [go/trace/trace.go](https://github.com/vitessio/vitess/blob/main/go/trace/trace.go).  |
| `tracing-sampling-type` | Optional | string | - | Sampling strategy to use for jaeger. Possible values are "const", "probabilistic", "rateLimiting", or "remote"; see [go/trace/plugin_jaeger.go](https://github.com/vitessio/vitess/blob/main/go/trace/plugin_jaeger.go). |
| `tracing-sampling-rate` | Optional | float | 0.1 | Sampling rate for the probabilistic jaeger sampler; see [go/trace/plugin_jaeger.go](https://github.com/vitessio/vitess/blob/main/go/trace/plugin_jaeger.go). |

### gRPC Server Flags

| Name | Required | Type | Default | Definition |
| -------- | --------- | --------- | --------- |--------- |
| `grpc-allow-reflection` | Optional | boolean | `false` | Whether to register the gRPC server for reflection; this is required to use tools like `grpc_cli`.
| `grpc-enable-channelz` | Optional | boolean | `false` | Whether to enable the [channelz](https://grpc.io/blog/a-short-introduction-to-channelz/) service on the gRPC server. |

### HTTP Server Flags

| Name | Required | Type | Default | Definition |
| -------- | --------- | --------- | --------- |--------- |
| `http-origin` | **Required** | string | - | repeated, comma-separated flag of allowed CORS origins. omit to disable CORS |
| `http-metrics-endpoint` | **Recommended** | string | "/metrics" | HTTP endpoint to expose prometheus metrics on. Omit to disable scraping metrics. Using a path used by VTAdmin's http API is unsupported and causes undefined behavior.|
| `http-tablet-url-tmpl` | **Recommended** | string | "https://{{ .Tablet.Hostname }}:80" | Go template string to generate a reachable http(s) address for a tablet. Currently used to make passthrough requests to /debug/vars endpoints. Example: `"https://{{ .Tablet.Hostname }}:80"` |
| `http-debug-omit-env` | Optional | boolean | `false` | The name of an environment variable to omit from /debug/env, if http debug endpoints are enabled. Specify multiple times to omit multiple env vars. |
| `http-debug-sanitize-env`| Optional | string | - | The name of an environment variable to sanitize in /debug/env, if http debug endpoints are enabled. Specify multiple times to sanitize multiple env vars. | 
| `http-no-compress` | Optional | boolean | `false` | Whether to disable compression of HTTP API responses. |
| `http-no-debug` | Optional | boolean | `false` | Whether to disable `/debug/pprof/*` and `/debug/env` HTTP endpoints | 


### RBAC Flags

If using RBAC, both the `--rbac` and `--rbac-config` flags must be set. If not using RBAC, the `--no-rbac` must be set.

| Name | Required | Type | Default | Definition |
| -------- | --------- | --------- | --------- |--------- |
| `no-rbac` | Optional | boolean | `false` | Whether to disable RBAC. | 
| `rbac` | Optional | boolean | `false` | Whether to enable RBAC. |
| `rbac-config` | Optional | string | - | Path to an RBAC config file. Must be set if passing `--rbac`. |

### glog Flags

See https://pkg.go.dev/github.com/golang/glog.

| Name | Required | Type | Default | Definition |
| -------- | --------- | --------- | --------- |--------- |
| `logtostderr` | Optional | boolean | `false` | If true, logs are written to standard error instead of to files. 
| `alsologtostderr` | Optional | boolean | `false` | If true, logs are written to standard error as well as to files. 
| `stderrthreshold` | Optional | string | `ERROR` | Log events at or above this severity are logged to standard error as well as to files.
| `log_dir` | Optional | string | - | Log files will be written to this directory instead of the default temporary directory. | 
| `v` | Optional | int | 0 | Enable V-leveled logging at the specified level. | 
