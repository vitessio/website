---
title: Backups and Restore for Local Environment
weight: 5
aliases: ['/docs/user-guides/backup-and-restore/']
---

{{< info >}}
This guide follows on from the Get Started guides. Please make sure that you have
an [local](../../../../get-started/local) installation ready. It also assumes
that the [MoveTables](../../../migration/move-tables/) and [Resharding](../../../configuration-advanced/resharding) user guides have been followed (which take you through
steps `101` to `306`).

This guide is useful only if you are using Vitess in a local environment.
{{< /info >}}

## Backups

If you are not already familiar with [how backups work](../overview/) in Vitess we suggest you familiarize yourself with them first.

## Local Environment Backup Scheduling

### Adding a Backup Schedule for Local Environment

In this section, we will explain how to perform backups of the customer keyspace and its shards to ensure data protection. The backups will be stored locally on your machine. You can customize the script to change the backup location if needed.

Run the script:
```bash
$ ./401_backup.sh
```
This will start the backup process for the customer keyspace and all its shards.

Expected Output
When you run the script, the following output can be expected:

```bash
Ensuring keyspace customer exists and shards are healthy...
Backing up shard -80 in keyspace customer...
...
customer/-80 (zone1-0000000300): time:{seconds:1728639914 nanoseconds:403262115} file:"backup.go" line:152 value:"Starting backup 2024-10-11.094514.zone1-0000000300"
...
Backup succeeded for shard -80.
...
customer/80- (zone1-0000000401): time:{seconds:1728639980 nanoseconds:482699704} file:"backup.go" line:152 value:"Starting backup 2024-10-11.094620.zone1-0000000401"
...
Backing up shard 80- in keyspace customer...
Backup succeeded for shard 80-.
Backup process completed successfully for all shards in customer.
```

### Listing Backups

Now we can list the available backups created in our local environment by executing the appropriate script or command. These backups are stored directly on your local machine (or VM), as defined in the configuration.

Run the following command to list the available backups:
``` bash
./402_list_backup.sh
```

This will display the backups you’ve created. Each backup will be labeled according to the keyspace and shard it belongs to.

Expected Output When you run the script, the following output can be expected:
```bash
Listing available backups for keyspace customer and shard -80...
2024-10-11.094337.zone1-0000000302
2024-10-11.094514.zone1-0000000300
2024-10-11.094557.zone1-0000000302
2024-10-11.094614.zone1-0000000300
Listing available backups for keyspace customer and shard 80-...
2024-10-11.094342.zone1-0000000402
2024-10-11.094602.zone1-0000000402
2024-10-11.094620.zone1-0000000401
Backup listing process completed.
```
Since this is a local environment, the backups will be stored directly on your machine, and you can view them in the specified backup directory.

For example, navigating to the directory:
```bash
cd /path/to/local/backup/directory
ls -l
```

This will display a detailed list of backups stored locally, such as:
```bash
-rw-r--r-- 1 shail_pujan shail_pujan  45 Oct  1 14:02 commerce---20241001-140228.tar.gz
-rw-r--r-- 1 shail_pujan shail_pujan  45 Oct  1 14:02 commerce---20241001-140253.tar.gz
-rw-r--r-- 1 shail_pujan shail_pujan  45 Oct  1 14:02 customer-80--20241001-140228.tar.gz
-rw-r--r-- 1 shail_pujan shail_pujan  45 Oct  1 14:02 customer-80--20241001-140253.tar.gz
-rw-r--r-- 1 shail_pujan shail_pujan 116 Oct  1 13:54 mybackup_20241001_135413.tar.gz
```
Each backup directory contains the necessary data files that can be restored later.

### Restore From Backup

To restore your backups for the customer keyspace and its shards, you can use the provided script to easily initiate the restoration process. The backups will be restored from the local machine where they were saved.

Run the script to initiate the restoration process:
```bash
./403_restore_from_backup.sh
```
This will start the restoration process for the customer keyspace and all its shards from the previously taken backups.

Expected Output
When you run the restore script, the following output can be expected:
```bash
Finding replica tablets for shard -80...
Restoring tablet zone1-0000000300 from backup for shard -80...
...
customer/-80 (zone1-0000000300): time:{seconds:1728641586 nanoseconds:564470645} file:"restore.go" line:250 value:"Restore: original tablet type=REPLICA"
...
Finding replica tablets for shard 80-...
Restoring tablet zone1-0000000401 from backup for shard 80-...
...
customer/80- (zone1-0000000401): time:{seconds:1728641929 nanoseconds:165948068} file:"restore.go" line:250 value:"Restore: original tablet type=REPLICA"
...
Restore process completed successfully for customer.
```
### Clean Up
Congratulations! You have successfully completed the backup and restore process for your local Vitess environment.

To clean up your local environment, you can remove the backup files created during this process by running:

```bash
rm ~/backups/*.tar.gz
```
This command will delete all backup archives, helping you maintain a clean workspace.