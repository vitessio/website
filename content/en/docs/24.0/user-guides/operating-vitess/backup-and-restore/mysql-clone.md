---
title: MySQL CLONE for Tablet Provisioning
weight: 6
---

MySQL CLONE uses MySQL's native [CLONE plugin](https://dev.mysql.com/doc/refman/8.0/en/clone-plugin-remote.html) to transfer data directly from a running MySQL server (the "donor") to a tablet being provisioned (the "recipient"). Unlike traditional backup and restore, CLONE copies data over the network at the physical level without staging in object storage. This makes provisioning faster, eliminates the storage intermediate, and lets the recipient start replicating from a position close to the donor's current state.

## Requirements

### MySQL Version

MySQL CLONE requires MySQL 8.0.17 or later on both donor and recipient servers. Cloning across point releases (e.g., 8.0.37 to 8.0.41) is not permitted before MySQL 8.0.37.

### Storage Engine

Only InnoDB tables can be cloned. If your databases contain MyISAM or other non-InnoDB tables, you cannot use MySQL CLONE.

### Clone Plugin

Both donor and recipient MySQL servers must have the `mysql_clone.so` plugin installed and active. Vitess can configure this automatically when you enable clone support (see Configuration below).

### Permissions

The clone user connecting to the donor must have `BACKUP_ADMIN` privilege, and the clone user on the recipient must have `CLONE_ADMIN` privilege. Vitess creates a `vt_clone` user with these privileges when you enable clone support.

## Configuration

### Enabling Clone Support

To enable MySQL CLONE, configure both the MySQL servers and the Vitess components.

__MySQL Configuration:__

When initializing MySQL with `mysqlctl` or `mysqlctld`, enable clone support:

```sh
mysqlctl --mysql-clone-enabled init
```

This flag loads the MySQL CLONE plugin (`mysql_clone.so`) and creates the `vt_clone` user with the required privileges (`BACKUP_ADMIN`, `CLONE_ADMIN`).

__Clone Credentials:__

Configure the clone user credentials for vtbackup and vttablet:

<table class="responsive">
  <thead>
    <tr>
      <th>Name</th>
      <th>Definition</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>--db-clone-user</code></td>
      <td>MySQL user for clone operations. Default: <code>vt_clone</code></td>
    </tr>
    <tr>
      <td><code>--db-clone-password</code></td>
      <td>Password for the clone user. Default: (empty)</td>
    </tr>
    <tr>
      <td><code>--db-clone-use-ssl</code></td>
      <td>Use SSL for clone connections. Default: <code>true</code></td>
    </tr>
  </tbody>
</table>

Example:

```sh
vttablet ... --db-clone-user=vt_clone \
             --db-clone-password=secret \
             --db-clone-use-ssl=false
```

## Using CLONE with VTTablet

You can use MySQL CLONE to provision a new vttablet instead of restoring from a backup.

__Startup Flags:__

<table class="responsive">
  <thead>
    <tr>
      <th>Name</th>
      <th>Definition</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>--restore-with-clone</code></td>
      <td>Enable clone-based restore. Mutually exclusive with <code>--restore-from-backup</code>.</td>
    </tr>
    <tr>
      <td><code>--clone-from-primary</code></td>
      <td>Clone data from the shard's primary tablet.</td>
    </tr>
    <tr>
      <td><code>--clone-from-tablet &lt;alias&gt;</code></td>
      <td>Clone data from a specific tablet (e.g., <code>zone1-123</code>).</td>
    </tr>
    <tr>
      <td><code>--clone-restart-wait-timeout</code></td>
      <td>Timeout for waiting for MySQL to restart after clone. Default: 5m.</td>
    </tr>
  </tbody>
</table>

### Clone from Primary

To provision a new tablet by cloning from the shard's primary:

```sh
vttablet --init-keyspace=commerce \
         --init-shard=0 \
         --init-tablet-type=replica \
         --restore-with-clone \
         --clone-from-primary \
         --db-clone-user=vt_clone \
         --db-clone-use-ssl=false
```

### Clone from Specific Tablet

To clone from a specific tablet (useful to avoid loading the primary):

```sh
vttablet --init-keyspace=commerce \
         --init-shard=0 \
         --init-tablet-type=replica \
         --restore-with-clone \
         --clone-from-tablet=zone1-0000000101 \
         --db-clone-user=vt_clone \
         --db-clone-use-ssl=false
```

## Using CLONE with VTBackup

VTBackup can use MySQL CLONE for its restore phase instead of restoring from the most recent backup. This can significantly speed up the backup process when the primary has data newer than the latest backup.

To run vtbackup with clone-based restore:

```sh
vtbackup --init-keyspace=commerce \
         --init-shard=0 \
         --mysql-clone-enabled \
         --restore-with-clone \
         --clone-from-primary \
         --db-clone-user=vt_clone \
         --db-clone-use-ssl=false
```

The `--restore-with-clone` flag tells vtbackup to clone from a donor tablet instead of restoring from backup storage. After the clone completes, vtbackup proceeds with its normal workflow: catching up on replication and taking a new backup.

## Use Cases

### Initializing New Tablets

When adding new replica tablets to a shard, MySQL CLONE can provision them faster than restoring from object storage backups. This is especially beneficial for large databases where backup restore times are significant.

### Repairing Broken Replicas

If replica tablets experience replication errors (such as `HA_ERR_FOUND_DUPP_KEY` or `HA_ERR_KEY_NOT_FOUND`) that prevent them from making progress, you can use MySQL CLONE to quickly reprovision them from the primary. This avoids the need to take a new backup or perform manual mysqldump operations.

### Speeding Up VTBackup

For shards with high write activity, the catch-up phase of vtbackup can be lengthy if the latest backup is old. Using CLONE, vtbackup starts with a dataset close to the primary's current state, minimizing the catch-up time.

## Limitations

* Both donor and recipient must run MySQL 8.0.17+.
* Only InnoDB tables can be cloned.
* A donor can only support one clone operation at a time.
* The recipient tablet must not be a primary tablet.
* Clone transfers data over the network, so ensure adequate bandwidth between donor and recipient.
