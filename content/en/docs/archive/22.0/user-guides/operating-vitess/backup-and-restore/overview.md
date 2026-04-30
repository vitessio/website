---
title: Overview
weight: 1
aliases: ['/docs/user-guides/backup-and-restore/']
---

Backup and Restore are integrated features provided by tablets managed by Vitess. As well as using _backups_ for data integrity, Vitess will also create and restore backups for provisioning new tablets in an existing shard.

## Concepts

Vitess supports pluggable interfaces for both [Backup Storage Services](https://github.com/vitessio/vitess/blob/main/go/vt/mysqlctl/backupstorage/interface.go) and [Backup Engines](https://github.com/vitessio/vitess/blob/main/go/vt/mysqlctl/backupengine.go).

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
* MySQL Shell: a logical backup engine using the upstream [mysqlsh](https://dev.mysql.com/doc/mysql-shell/8.0/en/) dump/load tool (EXPERIMENTAL)

### Backup types

Vitess supports full backups as well as incremental backups, and their respective counterparts full restores and point-in-time restores.

* A full backup contains the entire data in the database. The backup represents a consistent state of the data, i.e. it is a snapshot of the data at some point in time.
* An incremental backup contains a changelog, or a transition of data from one state to another. Vitess implements incremental backups by making a copy of MySQL binary logs.

Generally speaking and on most workloads, the cost of a full backup is higher, and the cost of incremental backups is lower. The time it takes to create a full backup is significant, and it is therefore impractical to take full backups in very small intervals. Moreover, a full backup consumes the disk space needed for the entire dataset. Incremental backups, on the other hand, are quick to run, and have very little impact, if any, to the running servers. They only contain the changes in between two points in time, and on most workloads are more compact.

Full and incremental backups are expected to be interleaved. For example: one would create a full backup once per day, and incremental backups once per hour.

Full backups are simply states of the database. Incremental backups, however, need to start with some point and end with some point. The common practice is for an incremental backup to continue from the point of the last good backup, which can be a full or incremental backup. An inremental backup in Vitess ends at the point in time of execution.

The identity of the tablet on which a full backup or an incremental backup is taken is immaterial. It is possible to take a full backup on one tablet and incremental backups on another. It is possible to take full backups on two different tablets. It is also possible to take incremental backups, independently, on two different tablets, even though the contents of those incremental backups overlaps. Vitess uses MySQL GTID sets to determine positioning and prune duplicates.

### Restores

Restores are the counterparts of backups. A restore uses the engine utilized to create a backup. One may run a restore from a full backup, or a point-in-time restore (PITR) based on additional incremental backups.

A Vitess restore operates on a tablet. The restore process completely wipes out the data in the tablet's MySQL server and repopulates the server with the backup(s) data. The MySQL server is shutdown during the process. As a safety mechanism, Vitess by default prevents a restore onto a `PRIMARY` tablet. Any non-`PRIMARY` tablet is otherwise eligible to restore.

### Restore Types

Vitess supports full restores and incremental (AKA point-in-time) restores. The two serve different purposes.

* A full restore loads the dataset from a full backup onto a non-`PRIMARY` tablet. Once the data is loaded, the restore process starts the MySQL service and makes it join the replication stream. It is expected that a freshly restored server will lag behind the shard's `PRIMARY` for a period of time.
  The full restore flow is useful for seeding new replica tablets. It may also be used to fix replicas that have been corrupted.
* An incremental, or a point-in-time restore, restores a tablet/MySQL up to a specific position or time. This is done by first loading a full backup dataset, followed by applying the changelog captured in zero or more incremental backups. Once that is complete, the tablet type is set to `DRAINED` and the tablet does _not_ join the replication stream.
  The common purpose of point-in-time restore is to recover data from an accidental write/deletion. If the database administrator knows at about what time the accidental write took place, they can restore a replica tablet to a point in time shortly before the accidental write. Since the server does not join the replication stream, its data then remains static, and the administrator may review or copy the data as they please. Finally, it is then possible to change the tablet type back to `REPLICA` and have it join the shard's replication.

## Vtbackup, VTTablet and Vtctld

Vtbackup, VTTablet, and Vtctld may all participate in backups and restores.

 * Vtbackup is a standalone program that restores the last backup into an empty mysqld installation, replicates new changes into that installation, and takes a new backup from that installation.
 * VTTablet can be configured to restore from a backup, or to take a new backup.
 * Vtctld can be instructed to take backups with commands like `Backup` and `BackupShard`.

### Configuration

Before backing up or restoring a tablet, you need to ensure that the tablet is aware of the Backup Storage system and Backup Engine that you are using.

To do so, use command-line flags to configure vtbackup, vttablet, or vtctld programs that have access to the location where you are storing backups.

__Common flags:__

All three programs can be made aware of Backup Engine and Backup Storage using these common flags.

<table class="responsive">
  <thead>
    <tr>
      <th>Name</th>
      <th>Definition</th>
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
      <td><code>backup_storage_compress</code></td>
      <td>This flag controls if the backups are compressed by the Vitess code.
        By default it is set to true. Use
        <code>--backup_storage_compress=false</code> to disable.</br>
      </td>
    </tr>
    <tr>
      <td><code>backup_storage_block_size</code></td>
      <td>If <code>--backup_storage_compress</code> is true, <code>backup_storage_block_size</code> sets the block size in bytes to use while compressing (default is 250000).
      </td>
    </tr>
    <tr>
      <td><code>backup_storage_number_blocks</code></td>
      <td>If <code>--backup_storage_compress</code> is true, <code>backup_storage_number_blocks</code> sets the number of blocks that can be processed, in parallel, before the writer blocks, during compression. It should be equal to the number of CPUs available for compression. (default 2)
      </td>
    </tr>
    <td><code>compression-level</code></td>
      <td>Select what is the compression level (from `1..9`) to be used with the builtin compressors.
        It doesn't have any effect if you are using an external compressor. Defaults to
        <code>1</code> (fastest compression).
      </td>
    </tr>
    <tr>
      <td><code>compression-engine-name</code></td>
      <td>
        This indicates which compression engine to use. The default value is <code>pargzip</code>.
        If using an external compressor (see below), this should be a compatible compression engine as the
        value will be saved to the MANIFEST when creating the backup and can be used to decompress it.
      </td>
    </tr>
    <tr>
      <td><code>external-compressor</code></td>
      <td>
      Instead of compressing inside the <code>vttablet</code> process, use the external command to
      compress the input. The compressed stream needs to be written to <code>STDOUT</code>.</br></br>
      An example command to compress with an external compressor using the fastest mode and lowest CPU priority: </br>
      <code>--external-compressor "nice -n 19 pigz -1 -c"</code><br/><br/>
      If the backup is supported by one of the builtin engines, make sure to use <code>--compression-engine-name</code>
      so it can be restored without requiring <code>--external-decompressor</code> to be defined.
      </td>
    </tr>
    <tr>
      <td><code>external-compressor-extension</code></td>
      <td>
      Using the <code>--external-compressor-extension</code> flag will set the correct extension when
      writing the file. Only used for the <code>xtrabackupengine</code>.<br/><br/>
      Example: <code>--external-compressor-extension ".gz"</code>
      </td>
    </tr>
    <tr>
      <td><code>external-decompressor</code></td>
      <td>
      Use an external decompressor to process the backups. This overrides the builtin
      decompressor which would be automatically select the best engine based on the MANIFEST information.
      The decompressed stream needs to be written to <code>STDOUT</code>.</br></br>
      An example of how to use an external decompressor:</br>
      <code>--external-decompressor "pigz -d -c"</code>
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

__Restore flags:__

Only VTTablet can be configured to restore from a previous backup. The flags below only apply to VTTablet.

<table class="responsive">
  <thead>
    <tr>
      <th>Name</th>
      <th>Definition</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>restore_from_backup</code></td>
      <td>Indicates that, when started with an empty MySQL instance, the
        tablet should restore the most recent backup from the specified
        storage plugin. This flag only applies to VTTablet.</td>
    </tr>
    <tr>
      <td><code>restore_from_backup_ts</code></td>
      <td>If set, restore the latest backup taken at or before this timestamp
        rather than using the most recent one. Example: ‘2021-04-29.133050’.
        (Vitess 12.0+)</td>
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

### Backup Compression

By default, `vttablet` backups are compressed using `pargzip` that generates `gzip` compatible files. 
You can select other builtin engines that are supported, or choose to use an external process to do the
compression/decompression for you. There are some advantages of doing this, like being able to set the
scheduling priority or even to choose dedicated CPU cores to do the compression, things that are not possible when running inside the `vttablet` process.

The built-in supported engines are:

__Compression:__
- `pargzip` (default)
- `pgzip`
- `lz4`
- `zstd`

__Decompression:__
- `pgzip`
- `lz4`
- `zstd`

To change which compression engine to use, you can use the `--compression-engine-name` flag. The compression
engine will also be saved to the backup manifest, which is read during the decompression process to select
the right engine to decompress (so even if it gets changed, the `vttablet` will still be able to restore
previous backups).

If you want to use an external compressor/decompressor, you can do this by setting:
- `--external-compressor` with the command that will actually compress the stream;
- `--external-compressor-extension` (only if using xtrabackupengine): this will let you use the extension of the file saved
- `--compression-engine-name` with the compatible engine that can decompress it. Use `external` if you are using an external engine not included in the above supported list. This value will be saved to the backup
MANIFEST; If it is not added (or engine is `external`), backups won't be able to restore unless you pass the parameter below:
- `--external-decompressor` with the command used to decompress the files;

The `vttablet` process will launch the external process and pass the input stream via STDIN and expects
the process will write the compressed/decompressed stream to STDOUT.

If you are using an external compressor and want to move to a builtin engine:
- If the engine is supported according to the list above, you just need to make sure your `--compression-engine-name` is correct and you can remove
the `--external-compressor` parameter
- If you want to move away from an unsupported engine to a builtin one, then you have to:
    - First change the `--compression-engine-name` to a supported one and remove the `--external-compressor`
    - Once the first backup is completed, you can then remove `--external-decompressor`
    - After this all new backups will be done using the new engine. Restoring an older backup will still require the `--external-decompressor` flag to be provided
