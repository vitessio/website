---
title: Cluster Discovery
---

# Overview
VTAdmin manages to be stateless because it mostly proxies queries to VTGates and Vtctlds within Vitess clusters. It is able to do this through **cluster discovery**, the mechanism by which addresses for VTGates and Vtctlds are discovered.

Discovery is specified as a part of [cluster configuration](https://github.com/vitessio/vitess/blob/main/doc/vtadmin/clusters.yaml). Cluster configuration is passed as the command line argument `--cluster` to VTAdmin API like so:
```bash
vtadmin \
  --addr ":14200" \
  --http-origin "http://localhost:14201" \
  --http-tablet-url-tmpl "http://{{ .Tablet.Hostname }}:15{{ .Tablet.Alias.Uid }}" \
  --tracer "opentracing-jaeger" \
  --grpc-tracing \
  --http-tracing \
  --logtostderr \
  --alsologtostderr \
  --rbac \
  --rbac-config="./vtadmin/rbac.yaml" \
  --cluster "id=local,name=local,discovery=staticfile,discovery-staticfile-path=./vtadmin/discovery.json,tablet-fqdn-tmpl={{ .Tablet.Hostname }}:15{{ .Tablet.Alias.Uid }}"
```
where, in this example, `discovery=staticfile` is specifying static file discovery.

VTAdmin API currently supports a few methods for discovery:

#### Static file discovery
With **static file discovery**, VTGate and Vtctld addresses are specified in a static file, whose path is provided as a parameter to the `--cluster` command line argument:
```bash
  --cluster "id=local,name=local,discovery=staticfile,discovery-staticfile-path=./vtadmin/discovery.json,tablet-fqdn-tmpl={{ .Tablet.Hostname }}:15{{ .Tablet.Alias.Uid }}"
```
<br/>
In this example, the file lives at `./vtadmin/discovery.json`, and might look like:

```json
{
    "vtctlds": [
        {
            "host": {
                "fqdn": "localhost:15000",
                "hostname": "localhost:15999"
            }
        }
    ],
    "vtgates": [
        {
            "host": {
                "fqdn": "localhost:15001",
                "hostname": "localhost:15991"
            }
        }
    ]
}
```

where `fqdn` specifies the address of the component's web UI, and `hostname` specifies the address of the component's gRPC server.

##### Multiple clusters
To specify multiple clusters, repeat the `--cluster` flag:
```bash
vtadmin \
  --addr ":14200" \
  --http-origin "http://localhost:14201" \
  --http-tablet-url-tmpl "http://{{ .Tablet.Hostname }}:15{{ .Tablet.Alias.Uid }}" \
  --tracer "opentracing-jaeger" \
  --grpc-tracing \
  --http-tracing \
  --logtostderr \
  --alsologtostderr \
  --rbac \
  --rbac-config="./vtadmin/rbac.yaml" \
  --cluster "id=local,name=local,discovery=staticfile,discovery-staticfile-path=./vtadmin/discovery-local.json,tablet-fqdn-tmpl={{ .Tablet.Hostname }}:15{{ .Tablet.Alias.Uid }}"
  --cluster "id=prod,name=prod,discovery=staticfile,discovery-staticfile-path=./vtadmin/discovery-prod.json,tablet-fqdn-tmpl={{ .Tablet.Hostname }}:15{{ .Tablet.Alias.Uid }}"
```
<br/>
The above multi-cluster configuration would show up in VTAdmin Web as:

<img src="/files/2022-12-05-vtadmin-intro/multiclusters.png" alt="Multiple clusters on the /clusters page in VTAdmin"/>

### Dynamic discovery
It is possible to discover clusters _after_ VTAdmin API has been initialized through **dynamic discovery**. When using dynamic discovery, a cluster configuration is passed as either [gRPC metadata](https://github.com/grpc/grpc-go/blob/master/Documentation/grpc-metadata.md) or an HTTP header cookie.

A very basic cluster configuration may look like:
```json
{
    "id": "dynamic",
    "name": "my-dynamic-cluster",
    "discovery": "dynamic",
    "discovery-dynamic-discovery": "{\"vtctlds\": [ { \"host\": { \"fqdn\": \"localhost:15000\", \"hostname\": \"localhost:15999\" } } ], \"vtgates\": [ { \"host\": {\"hostname\": \"localhost:15991\" } } ] }"
}
```
<br/>

In order to use dynamic discovery, set command line argument `--enable-dynamic-clusters=true`. At this time, it is only possible to discover a single cluster with each request. We're working on adding multicluster support to dynamic discovery.
#### HTTP header cookie
A cluster configuration can be passed as an HTTP cookie named `cluster` along with HTTP requests.

When passing a cluster configuration as an HTTP header cookie, the cluster configuration must first be base64 encoded and then URL encoded. A cURL request with the above cluster configuration would look like:

```bash
$ curl -X GET \
  http://localhost:14200/api/clusters \
  -H 'cookie: cluster=ewogICAgImlkIjogImR5bmFtaWMiLAogICAgIm5hbWUiOiAibXktZHluYW1pYy1jbHVzdGVyIiwKICAgICJkaXNjb3ZlcnkiOiAiZHluYW1pYyIsCiAgICAiZGlzY292ZXJ5LWR5bmFtaWMtZGlzY292ZXJ5IjogIntcInZ0Y3RsZHNcIjogWyB7IFwiaG9zdFwiOiB7IFwiZnFkblwiOiBcImxvY2FsaG9zdDoxNTAwMFwiLCBcImhvc3RuYW1lXCI6IFwibG9jYWxob3N0OjE1OTk5XCIgfSB9IF0sIFwidnRnYXRlc1wiOiBbIHsgXCJob3N0XCI6IHtcImhvc3RuYW1lXCI6IFwibG9jYWxob3N0OjE1OTkxXCIgfSB9IF0gfSIKfQ%3D%3D'

{"result":{"clusters":[{"id":"dynamic","name":"my-dynamic-cluster"}]},"ok":true}
```
<br/>

#### gRPC metadata
A cluster configuration can also be passed as gRPC metadata with the key `cluster`. The code snippet below does the following:
1. Creates a gRPC connection to the VTAdmin client at address `localhost:14200`
2. Creates an outgoing context and adds the cluster configuration as gRPC metadata
3. Calls `GetClusters` with the created context and gRPC metadata

```golang
package main

import (
	"context"
	"encoding/base64"
	"flag"
	"fmt"

	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"

	"vitess.io/vitess/go/cmd/vtctldclient/cli"
	"vitess.io/vitess/go/vt/log"

	vtadminpb "vitess.io/vitess/go/vt/proto/vtadmin"
)

func main() {
	addr := flag.String("addr", ":14200", "")

	flag.Parse()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	cc, err := grpc.DialContext(ctx, *addr, grpc.WithInsecure())
	fatal(err)

	defer cc.Close()

	client := vtadminpb.NewVTAdminClient(cc)
	clusterJSON := `{
    "id": "dynamic",
		"name": "my-dynamic-cluster",
		"vtctlds": [
			{
				"host": {
					"fqdn": "localhost:15000",
					"hostname": "localhost:15999"
				}
			}
		],
		"vtgates": [
			{
				"host": {
					"hostname": "localhost:15991"
				}
			}
		]
	}
	`

	ctx = metadata.NewOutgoingContext(ctx, metadata.New(map[string]string{
		"cluster": base64.StdEncoding.EncodeToString([]byte(clusterJSON)),
	}))

	resp, err := client.GetClusters(ctx, &vtadminpb.GetClustersRequest{})
	if err != nil {
		log.Fatal(err)
	}

	data, err := cli.MarshalJSON(resp)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("%s\n", data)
}
```
<br/>

The result of the above program is:
```bash
$ ./bin/vtadminclient
{
  "clusters": [
    {
      "id": "dynamic",
      "name": "my-dynamic-cluster"
    }
  ]
}
```
A full gist example can be found [here](https://gist.github.com/ajm188/5b5c8ba0cc5660298697e0f762081d45).