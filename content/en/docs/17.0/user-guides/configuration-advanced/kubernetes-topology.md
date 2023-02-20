---
title: Using the Kubernetes Topology
weight: 5
aliases: []
---

Vitess is fully capable of using a custom resource in the Kubernetes API
for topology storage. This includes support of locking, watches, and recursive watches. Using
a Kubernetes API can significantly reduce operational overhead when running
Vitess inside a cluster as it does not require a separate topology service process
to be available and running.

It is also possible to use any Kubernetes API as a topology service even if Vitess is
not running locally. This document includes two primary examples:

1. Using the Kubernetes topo for a local install
2. Using the Kubernetes topo for a Kubernetes installed Vitess

## Prerequisites

* Local Vitess binaries in your `PATH`
* kubectl and a valid kubeconfig at `~/.kubeconfig`
  > A basic local test Kubernetes instance can be made with something like `minikube`, `k3s/k3d`, `kind`
    or any other tools used to create local Kubernetes instances. Examples below use `k3d` but those steps can
    be omitted if you already have a valid kubeconfig.

## Local Install - Managed k3s

The local example supports automatic setup and teardown using k3s to provide a Kubernetes endpoint. Make sure
you have `k3s` installed and in your `PATH` then export the required config vars.

```sh
export TOPO=k8s_k3s
# Now you can use the standard bootstrap scripts
./101_initial_cluster.sh
```

## Local Install - Existing Kubernetes

If you already have a valid kubeconfig it's possible to follow the standard [/get-started/local] process using Kubernetes for the topology. Just
export the required config vars first.

```sh
export KUBECONFIG=~/.kube/config
export TOPO=k8s
./101_initial_cluster.sh
# etc
```

## Kubernetes Install

When running Vitess inside Kubernetes you can leverage the built-in service account credentials to provide your components
with the required Kubernetes configuration.

A basic flow for running vitess in Kubernetes and using the Kubernetes topology implementation from within the cluster:

1. Provision a Kubernetes cluster (out of scope for this document)
2. Apply the "VitessTopoNodes" Custom Resource Definition to the cluster
  ```sh
  kubectl apply -f https://raw.githubusercontent.com/vitessio/vitess/main/go/vt/topo/k8stopo/VitessTopoNodes-crd.yaml
  ```
1. If you are using RBAC then you will need to grant the service account(s) for your vitess pods `["get", "list", "watch", "create", "update", "patch", "delete"]` access to the `VitessTopoNodes` resources.
2. Provide the vitess k8s topology flags to your Vitess component. Ex:
  ```sh
  vtctld --topo_implementation k8s --topo_k8s_kubeconfig ${K8S_KUBECONFIG} --topo_global_server_address ${K8S_ADDR}:${K8S_PORT} --topo_global_root /vitess/global
  ```

## Frequently Asked Questions

Q: Won't the Vitess components generate a high load on the Kubernetes API?

A: No, the topology service is not in the critical path for serving traffic. It is a relatively low use component, regardless of the implementation. Additionaly,
the Kubernetes topology service only maintains a single API watch for each component so the overall load on the API is very minimal.

Q: Can I inspect and interact with the Kubernetes resources directly with `kubectl`?

A: Sort of, each individual Kubernetes resource has a size limit. In order to maximize possible data space the Kubernetes topology objects contain compressed
and encoded data, not raw strings. The node resource names are also hashed so that they can reliably stay within Kubernetes Name limits.

The end result is that, while it's possible to use kubectl to interact with the topology, it can be tricky to work with directly. Instead it is highly recommended to use the `vtctl` command instead. 

