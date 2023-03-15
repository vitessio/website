---
title: Running with Vitess Operator
description: How to configure Vitess Kubernetes Operator to run VTOrc
---

## Get Started

The Vitess operator deploys one VTOrc instance for each keyspace that it is configured for. Please look at the [VTOrc reference page](../../programs/vtorc)
to know all the flags that VTOrc accepts.

## Compatibility

v15 version of VTOrc is incompatible with 2.7.* versions of Vitess Operator and v14 version of VTOrc is incompatible with 2.8.* versions of VTOrc.
So when the users upgrade from 2.7.* version of Vitess Operator to 2.8.*, they should also update their deployment of VTOrc.

## Configuring VTOrc in Vitess Operator

The VTOrc can be configured to run for a given keyspace by specifying the `vitessOrchestrator` specification as part of the `keyspace` spec.
Resource limits and requests can be specified as part of the configuration and the default behaviour of VTOrc can be changed by specifying any 
desired flags in the `extraFlags` field.

The VTOrc UI runs on the port `15000` of the container and port-forwarding can be setup to access it.

Previously, VTOrc deployment also took a configuration file as a secret specified in the `configSecret` parameter. This field has been removed in this release of Vitess Operator.

## Example Configuration

An example deployment from the VTOrc [end to end test](https://github.com/planetscale/vitess-operator/tree/release-2.8/test/endtoend) on the Vitess Operator looks like:
```yaml
keyspaces:
  - name: commerce
    durabilityPolicy: semi_sync
    turndownPolicy: Immediate
    vitessOrchestrator:
      resources:
        limits:
          memory: 128Mi
        requests:
          cpu: 100m
          memory: 128Mi
      extraFlags:
        recovery-period-block-duration: 5s
```

The full configuration file is available [here](https://github.com/planetscale/vitess-operator/blob/release-2.8/test/endtoend/operator/101_initial_cluster_vtorc_vtadmin.yaml).


