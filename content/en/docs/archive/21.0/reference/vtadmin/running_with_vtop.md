---
title: Running with Vitess Operator
description: How to configure Vitess Kubernetes Operator to run VTAdmin
---

## Get Started

{{< info >}}
VTAdmin only runs in a single Vitess cluster configuration in the Vitess operator.
{{< /info >}}

Please also read the [Operator's Guide](../operators_guide) to learn more about configurations available and how to use them.

## Compatibility

Support for deploying VTAdmin in Vitess Operator has been added in [release 2.7.1](https://github.com/planetscale/vitess-operator/releases/tag/v2.7.1) onwards.

## Overview

Vitess Operator deploys VTAdmin in two separate containers running on the same pod. One for running the `vtadmin-api` and one for `vtadmin-web`. Please look at the [architecture docs](../architecture) for details on how they interact with each other.

Vitess Operator then creates services on top of both `vtadmin-api` and `vtadmin-web`, which can be used to access them after either port-forwarding or assigning an external IP address to the service.

Finally, Vitess Operator creates the `discovery.json` file automatically which is needed to connect to `vtctld` and `vtgate` services. It connects to the global `vtctld` service and per-cell service of `vtgates`, both of which Vitess Operator creates automatically. No configuration from the users is required for discovering these components.

## Configuring VTAdmin in Vitess Operator

The VTAdmin configuration section lives at the same level as the `vtctld` configuration in the cluster specification.

The following options are available for configuring VTAdmin:

- `RBAC` is a secret source. It is the role-based access control rules to use for VTAdmin API. More information on role-based access control can be found [here](../role-based-access-control).
- `Cells` is a list of strings. It is the cells where VTAdmin must be deployed. Defaults to deploying instances of VTAdmin in all cells.
- `APIAddresses` as a list of strings. Since the VTAdmin web UI runs on the client side, it needs the API address to use to query the API. We can't use the internal kubernetes service address or the ip of the pod, since they aren't visible outside the cluster. The API Address must be provided by the user based on how they export the service of VTAdmin API. In our example configuration (see below) we port-forward the service to port `14001` and therefore that is the address provided there. This value is a list because the address to be used for VTAdmin web in each cell might be different. If only 1 value is provided then, that is used for all the cells. The ideal way to deploy this would be to export each individual VTAdmin service (that we create) in each cell and attach external IPs to them and provide those IPs here.
- `Replicas` - Number of VTAdmin deployments required per cell. We setup a service on top of the web and API connections, so load-balancing comes out of the box.
- `WebResources` - Resource requests and limits for the container running the VTAdmin web server.
- `APIResources` - Resource requests and limits for the container running the VTAdmin API server.
- `ReadOnly` - Configuration to set the VTAdmin web UI to be read-only.

Apart from the VTAdmin configuration, the image to use for the containers also needs to be provided. Currently `vitess/lite` image doesn't contain the binaries to deploy vtadmin, so the more specific `vitess/vtadmin` image needs to be used.

## Example Configuration

The VTAdmin configuration that is used in Vitess Operator [end to end tests](https://github.com/planetscale/vitess-operator/tree/main/test/endtoend) looks like:

```yaml
spec:
  images:
    vtadmin: vitess/vtadmin:latest
  vtadmin:
    rbac:
      name: example-cluster-config
      key: rbac.yaml
    cells:
      - zone1
    apiAddresses:
      - http://localhost:14001
    replicas: 1
    readOnly: false
    apiResources:
      limits:
        memory: 128Mi
      requests:
        cpu: 100m
        memory: 128Mi
    webResources:
      limits:
        memory: 128Mi
      requests:
        cpu: 100m
        memory: 128Mi
```
