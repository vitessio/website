---
title: Backup and Restore
weight: 1
aliases: ['/docs/user-guides/backup-and-restore/']
---

{{< warning >}}
Backups of MySQL 8.0.30 and later are only supported in Vitess 14.0.2 and later. You can see additional details [here](https://github.com/vitessio/vitess/pull/10847).
{{< /warning >}}

Backup and Restore are integrated features provided by tablets managed by Vitess. As well as using _backups_ for data integrity, Vitess will also create and restore backups for provisioning new tablets in an existing shard.

## Concepts

Vitess supports pluggable interfaces for both [Backup Storage Services](https://github.com/vitessio/vitess/blob/main/go/vt/mysqlctl/backupstorage/interface.go) and [Backup Engines](https://github.com/vitessio/vitess/blob/main/go/vt/mysqlctl/backupengine.go).

Before backing up or restoring a tablet, you need to ensure that the tablet is aware of the Backup Storage system and Backup engine that you are using. To do so, use the following command-line flags when starting a vttablet or vtctld that has access to the location where you are storing backups.

### Backup Storage Services

Currently, Vitess has plugins for:

* File (using a path on shared storage, e.g. an NFS mount)
* Google Cloud Storage
* Amazon S3
* Ceph

### Backup Engines

The engine is the techology used for generating the backup. Currently Vitess has plugins for:

* Builtin: Shutdown an instance and copy all the database files (default)
* XtraBackup: An online backup using Percona's [XtraBackup](https://www.percona.com/software/mysql-database/percona-xtrabackup)

## VTTablet and Vtctld configuration

The following options can be used to configure VTTablet and Vtctld for backups:

<table class="responsive">
  <thead>
    <tr>
      <th colspan="2">Flags</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>backup_storage_implementation</code></td>
      <td>Specifies the implementation of the Backup Storage interface to
        use.<br><br>
        Current plugin options available are:
        <ul>
          <li><code>file</code>: Using shared storage (e.g. NFS).</li>
          <li><code>gcs</code>: Google Cloud Storage.</li>
          <li><code>s3</code>: Amazon S3.</li>
          <li><code>ceph</code>: Ceph Object Gateway S3 API.</li>
        </ul>
      </td>
    </tr>
    <tr>
      <td><code>backup_engine_implementation</code></td>
      <td>Specifies the implementation of the Backup Engine to
        use.<br><br>
        Current options available are:
        <ul>
          <li><code>builtin</code>: Copy all the database files into specified storage. This is the default.</li>
          <li><code>xtrabackup</code>: Percona <a href="https://www.percona.com/software/mysql-database/percona-xtrabackup">XtraBackup</a>.</li>
        </ul>
      </td>
    </tr>
    <tr>
      <td><code>backup_storage_hook</code></td>
      <td>If set, the content of every file to backup is sent to a hook. The
        hook receives the data for each file on stdin. It should echo the
        transformed data to stdout. Anything the hook prints to stderr will
        be printed in the vttablet logs.<br>
        Hooks should be located in the <code>vthook</code> subdirectory of the
        <code>VTROOT</code> directory.<br>
        The hook receives a <code>-operation write</code> or a
        <code>-operation read</code> parameter depending on the direction
        of the data processing. For instance, <code>write</code> would be for
        encryption, and <code>read</code> would be for decryption.</br>
      </td>
    </tr>
    <tr>
      <td><code>backup_storage_compress</code></td>
      <td>This flag controls if the backups are compressed by the Vitess code.
        By default it is set to true. Use
        <code>--backup_storage_compress=false</code> to disable.</br>
        This is meant to be used with a <code>--backup_storage_hook</code>
        hook that already compresses the data, to avoid compressing the data
        twice.
      </td>
    </tr>
    <tr>
      <td><code>file_backup_storage_root</code></td>
      <td>For the <code>file</code> plugin, this identifies the root directory
        for backups. This path <b>must</b> exist on shared storage to provide a global backup view for all vtctlds and vttablets.
      </td>
    </tr>
    <tr>
      <td><code>gcs_backup_storage_bucket</code></td>
      <td>For the <code>gcs</code> plugin, this identifies the
        <a href="https://cloud.google.com/storage/docs/concepts-techniques#concepts">bucket</a>
        to use.</td>
    </tr>
    <tr>
      <td><code>s3_backup_aws_region</code></td>
      <td>For the <code>s3</code> plugin, this identifies the AWS region.</td>
    </tr>
    <tr>
      <td><code>s3_backup_storage_bucket</code></td>
      <td>For the <code>s3</code> plugin, this identifies the AWS S3
        bucket.</td>
    </tr>
    <tr>
      <td><code>ceph_backup_storage_config</code></td>
      <td>For the <code>ceph</code> plugin, this identifies the path to a text
        file with a JSON object as configuration. The JSON object requires the
        following keys: <code>accessKey</code>, <code>secretKey</code>,
        <code>endPoint</code> and <code>useSSL</code>. Bucket name is computed
        from keyspace name and shard name is separated for different
        keyspaces / shards.</td>
    </tr>
    <tr>
      <td><code>restart_before_backup</code></td>
      <td>If set, perform a clean MySQL shutdown and startup cycle. Note this is not
       	executing any `FLUSH` statements. This enables users to work around <a href="https://jira.percona.com/browse/PXB-2205">xtrabackup
	DDL issues.</a></td>
    </tr>
    <tr>
      <td><code>restore_from_backup</code></td>
      <td>Indicates that, when started with an empty MySQL instance, the
        tablet should restore the most recent backup from the specified
        storage plugin.</td>
    </tr>
    <tr>
      <td><code>restore_from_backup_ts</code></td>
      <td>If set, restore the latest backup taken at or before this timestamp
        rather than using the most recent one. Example: ‘2021-04-29.133050’.
        (Vitess 12.0+)</td>
    </tr>
    <tr>
      <td><code>xbstream_restore_flags</code></td>
      <td>The flags to pass to the xbstream command during restore. These should be space separated and will be added to the end of the command. These need to match the ones used for backup e.g. <code>--compress</code> / <code>--decompress</code>, <code>--encrypt</code> / <code>--decrypt</code></td>
    </tr>
    <tr>
      <td><code>xtrabackup_root_path</code></td>
      <td>For the <code>xtrabackup</code> backup engine, directory location of the xtrabackup executable, e.g., `/usr/bin`</td>
    </tr>
    <tr>
      <td><code>xtrabackup_backup_flags</code></td>
      <td>For the <code>xtrabackup</code> backup engine, flags to pass to the backup command. These should be space separated and will be added to the end of the command.</td>
    </tr>
    <tr>
      <td><code>xtrabackup_stream_mode</code></td>
      <td>For the <code>xtrabackup</code> backup engine, which mode to use if streaming, valid values are <code>tar</code> and <code>xbstream</code>. Defaults to <code>tar</code>.</td>
    </tr>
    <tr>
      <td><code>xtrabackup_user</code></td>
      <td>For the <code>xtrabackup</code> backup engine, required user that xtrabackup will use to connect to the database server. This user must have all necessary privileges. For details, please refer to xtrabackup documentation.</td>
    </tr>
    <tr>
      <td><code>xtrabackup_stripes</code></td>
      <td>For the <code>xtrabackup</code> backup engine, if greater than 0, use data striping across this many destination files to parallelize data transfer and decompression.</td>
    </tr>
    <tr>
      <td><code>xtrabackup_stripe_block_size</code></td>
      <td>For the <code>xtrabackup</code> backup engine, size in bytes of each block that gets sent to a given stripe before rotating to the next stripe. Defaults to <code>102400</code>.</td>
    </tr>
    <tr>
      <td><code>xtrabackup_prepare_flags</code></td>
      <td>Flags to pass to the prepare command. These should be space separated and will be added to the end of the command.</td>
    </tr> 
  </tbody>
</table>

### Authentication

Note that for the Google Cloud Storage plugin, we currently only support
[Application Default Credentials](https://developers.google.com/identity/protocols/application-default-credentials). This means that access to Google Cloud Storage (GCS) is automatically granted by virtue of the fact that you're already running within Google Compute Engine (GCE) or Google Kubernetes Engine (GKE).

For this to work, the GCE instances must have been created with the [scope](https://cloud.google.com/compute/docs/authentication#using) that grants read-write access to GCS. When using GKE, you can do this for all the instances it creates by adding `--scopes storage-rw` to the `gcloud container clusters create` command.

### Backup Frequency

We recommend to take backups regularly -- e.g. you should set up a cron job for it.

To determine the proper frequency for creating backups, consider the amount of time that you keep replication logs (see the [binlog_expire_logs](https://dev.mysql.com/doc/refman/8.0/en/replication-options-binary-log.html#sysvar_binlog_expire_logs_seconds) variables) and allow enough time to investigate and fix problems in the event that a backup operation fails.

For example, suppose you typically keep four days of replication logs and you create daily backups. In that case, even if a backup fails, you have at least a couple of days from the time of the failure to investigate and fix the problem.

### Concurrency

The backup and restore processes simultaneously copy and either compress or decompress multiple files to increase throughput. You can control the concurrency using command-line flags:

* The vtctl [Backup](https://vitess.io/docs/reference/programs/vtctl/tablets/#backup) command uses the `--concurrency` flag.
* vttablet uses the `--restore_concurrency` flag.

If the network link is fast enough, the concurrency matches the CPU usage of the process during the backup or restore process.
