---
title: "How can I resize my Kubernetes storage when using Vitess?"
shorten_nav_links: true
notoc: true
weight: 2
---

If you use Vitess with Kubernetes and need to grow your disk space, Kubernetes has capabilities to resize persistent storage. 
These are specific to your Kubernetes provider, please refer to their documentation.
As an alternative, you can migrate to new storage by performing a series of planned vertical or horizontal sharding operations.

In general, persistent storage in Kubernetes can be resized up, but not down. Host local storage cannot be resized.
Shrinking storage will require spinning up new tablets with the desired (smaller) sized persistent storage, restoring them from backups and decommissioning the old tablets.
