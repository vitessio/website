---
title: Get Started
description: Deploy Vitess on your favorite platform
weight: 2
aliases: ['/docs/tutorials/']
---

Choose the right installation method for your use case. Each option serves different needs, from local development to production deployments.

## Quickstart Guide
 If you are new to Vitess, start with the local install guide to install Vitess locally for testing purposes, from pre-compiled binaries. 

The [Local Install](local/) guide runs Vitess directly on Linux using pre-compiled binaries. Use the local install to get hands-on experience without container orchestration.

**Prerequisites:** 4GB+ RAM, 20GB disk, MySQL 8.0, etcd, Node.js.


## Installation Options

### Vitess Operator for Kubernetes

The [Vitess Operator](operator/) automates deploying and managing Vitess on Kubernetes, handling scaling, failover, and upgrades through declarative configuration.

**Prerequisites:** Kubernetes cluster (Minikube for testing, or GKE/EKS/AKS for production), kubectl, and Docker.


### Local Install via Source (macOS)

The [Local Install via source for Mac](local-mac/) builds Vitess from source on macOS. This is the recommended path since pre-compiled binaries only fully support Ubuntu.

**Prerequisites:** Homebrew, Go, MySQL, etcd, Node.js.

### Vttestserver Docker Image

The [Vttestserver Docker Image](vttestserver-docker-image/) runs all Vitess components in a single container. This option is ideal for integration testing and CI/CD pipelines.

**Prerequisites:** Docker.

## Production Deployment Alternatives

The Vitess Operator on Kubernetes is the most common production method, but Vitess also runs on bare-metal or VMs. See the [Planning](../user-guides/configuration-basic/planning/) guide for multi-datacenter deployments without Kubernetes.

For non-Kubernetes production:
- Deploy Vitess binaries on Linux servers
- Use systemd for process management
- Configure etcd, ZooKeeper, or Consul as your topology service
- Implement your own monitoring, backup, and failover

## Supported Operating Systems

**Pre-compiled binaries:** Ubuntu only.

**Build from source:** Ubuntu 19.10+, Debian 10+, CentOS 7+, macOS (via Homebrew).

**Docker and Kubernetes:** Platform-independent.

For other operating systems, [build from source](../../contributing/build-on-ubuntu) or use Docker images.

## Building from Source

- [Build on Ubuntu/Debian](../../contributing/build-on-ubuntu)
- [Build on CentOS](../../contributing/build-on-centos)
- [Build on macOS](../../contributing/build-on-macos)
