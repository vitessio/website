---
title: Planning
weight: 3
aliases: ['/docs/user-guides/configuration-basic/configuring-components/'] 
---

This guide explains how to bring up and manage a Vitess cluster. We cover every individual component of Vitess and how they interact with each other. If you are deploying on Kubernetes, a lot of the wire-up is automatically handled by the operator. However, it is still important to know how the components work in order to be able to troubleshoot problems if they occur in production.

We assume that you are familiar with the setup of your production environment. If operating in Kubernetes, you should be able to access all the logs, and be able to reach any ports of the pods that are getting launched. In addition, you should be familiar with provisioning storage.

In self-hosted environments, you are expected to have the ability to troubleshoot network issues, firewalls and hostnames. You will also have to configure and setup certificates for components to talk to each other securely. This topic will not be covered in this guide. In addition, you are expected to perform all other sysadmin work related to provisioning, resource allocation, etc.

Vitess is capable of running on a variety of platforms. They may be self-hosted, in the public cloud, or in a cloud orchestration environment like Kubernetes.

In this guide, we will assume that we are deploying in a self-hosted environment that has multiple data centers. This setup allows us to better understand the interaction between the components.

Before starting, we assume that you have downloaded Vitess and finished the [Get Started](../../../get-started) tutorial.

## External tools

Vitess relies on two external components, and we recommend that you choose them upfront:

1. [TopoServer](../../../concepts/topology-service/): This is the server in which Vitess stores its metadata. We recommend etcd if you have no other preference.
2. [MySQL](../../../overview/supported-databases/): Vitess supports MySQL/Percona Server 5.7 to 8.0. We recommend MySQL 8.0 for new installations.

In this guide, we will be covering the case where the MySQL instances are managed by Vitess. A different section covers the details of running against [externally managed databases](../../configuration-advanced/unmanaged-tablet).

## Provisioning

Some high level decisions have to be made about the number of cells you plan to deploy on. This will loosely tie into how many replicas you intend to run per MySQL primary. You are likely to deploy at least one replica per cell.

Vitess resource consumption is mostly driven by QPS, but there may be variations depending on your use case. As a starting point, you can use a rule of thumb of provisioning about 1 CPU for every 1000QPS. This CPU will be divided between MySQL, vttablets and vtgates, about 1/3 each. As for memory, you can start with approximately 1GB per CPU provisioned for Vitess components. MySQL memory will be largely guided by the buffer pool size, which may take some trial and error or prior experience to tune.

Resources for other servers like the toposerver, vtctld, Vtadmin and VTOrc are minimal. They are likely not going to exceed one CPU per server instance.

## Environment variables

Setting up a few environment variables upfront will improve the manageability of the system:

* `VTDATAROOT`: Setting up this value will make Vitess create the MySQL data files under this directory. Other Vitess binaries will also use this variable to locate such files as needed. If not specified, the default value is `/vt`. Typically, no other files get stored under this directory. However, many idiomatic deployments tend to reuse this as root directory for other purposes like log files, etc.
* `VT_MYSQL_ROOT`: Informs Vitess about where to find the `mysqld` binary. If this is not specified, Vitess will try to find `mysqld` in the current `PATH`.

Vitess will automatically detect the flavor of MySQL and will adjust its behavior accordingly. You can override this behavior by specifying an explicit flavor with the `--db_flavor` command line argument to the various components.

## Backups

Backups will need to be shared across vttablet instances and multiple cells. You need to plan and allocate shared storage that must be accessible from all cells. Depending on the choice made, you will need to prepare a group of command line arguments to include with the Vitess components to launch. Here is an example:

```text
--backup_storage_implementation file --file_backup_storage_root <mounted_path_dir>
```

{{< warning >}}
When using the file backup storage engine the backup storage root path must be on shared storage to provide a global view of backups to all vitess components.
{{< /warning >}}

Please refer to the [Backup and Restore](../../operating-vitess/backup-and-restore) guide for instructions on how to configure other storage options.

To avoid repetition we will use `<backup_flags>` in our examples to signify the above flags.

## Logging

Vitess servers write to log files, and they are rotated when they reach a maximum size. It’s recommended that you run at INFO level logging. The information printed in the log files can come in handy for troubleshooting. You can limit the disk usage by running cron jobs that periodically purge or archive them.

All Vitess servers accept a `--log_dir` argument and will create the log files in that specified directory. For example:

```text
--log_dir=${VTDATAROOT}/tmp
```
