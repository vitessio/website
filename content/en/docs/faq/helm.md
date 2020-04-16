---
title: Helm
description: Frequently Asked Questions about Helm
---

## How can I deploy in GKE?

The new Vitess helm charts require Kubernetes 1.16 or later. Currently this requires switching to the rapid channel in GKE:

![Selecting Kubernetes 1.16 in GKE](/img/gke.png)

## How can I deploy in AKS?

As of writing, the default Kubernetes version is 1.15. To deploy on AKS, make sure you select Kubernetes 1.16 or greater.

## How can I deploy in EKS?

EKS does not currently support Kubernetes 1.16 or later, which is now a requirement for running Vitess Helm charts. We are currently evaluating republishing an earlier version of the helm charts (which will only work in Kubernetes 1.15 and earlier). If this affects you, please connect with us on Vitess slack.
