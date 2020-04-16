---
title: Helm
description: Frequently Asked Questions about Helm
---

## How can I deploy in GKE?

The new Vitess helm charts require Kubernetes 1.16 or later. Currently this requires switching to the rapid channel in GKE:

![Selecting Kubernetes 1.16 in GKE](/img/gke.png)

## How can I deploy in EKS or AKS?

EKS and AKS do not currently support Kubernetes 1.16 or later, which is now a requirement for running Vitess Helm charts. We are currently evaluating republishing an earlier version of the helm charts (which will only work in Kubernetes 1.15 and earlier). If this affects you, please connect with us on Vitess slack.
