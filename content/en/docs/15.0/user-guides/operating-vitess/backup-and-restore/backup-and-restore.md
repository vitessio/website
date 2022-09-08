	---
title: Backup and Restore
weight: 1
aliases: ['/docs/user-guides/backup-and-restore/']
---

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

### Backup Compression

By default, `vttablet` backups are compressed using `pargzip` that generates `gzip` compatible files. 
You can select other builtin engines that are supported, or choose to use an external process to do the
compression/decompression for you. There are some advantages of doing this, like being able to set the
scheduling priority or even to choose dedicated CPU cores to do the compression, things that are not possible when runningg inside the `vttablet` process.

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
