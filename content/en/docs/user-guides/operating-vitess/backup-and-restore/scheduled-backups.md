---
title: Scheduling Backups
weight: 5
aliases: ['/docs/user-guides/backup-and-restore/']
---

{{< info >}}
This guide follows on from the Get Started guides. Please make sure that you have
an [Operator](../../../../get-started/operator) installation ready. It also assumes
that the [MoveTables](../../../migration/move-tables/) and [Resharding](../../../configuration-advanced/resharding) user guides have been followed (which take you through
steps `101` to `306`).

This guide is useful only if you are using the vitess-operator.
{{< /info >}}

## Backups

If you are not already familiar with [how backups work](../overview/) in Vitess we suggest you familiarize yourself with them first.

## Scheduling backups

The vitess-operator uses `VitessBackupSchedule` resources to define when and what to back up. Each schedule contains one or more **strategies** that specify which shards to include.

### Strategy scopes

Use the `scope` field to target different levels of your cluster:

- **Shard** (default): Backs up a single shard. Requires both `keyspace` and `shard` fields.
- **Keyspace**: Discovers and backs up all shards in the specified keyspace. Requires only `keyspace`.
- **Cluster**: Discovers and backs up all shards across all keyspaces. No `keyspace` or `shard` required.

Keyspace and Cluster scopes automatically detect new shards added during resharding, so you don't need to update your backup configuration when shards change.

#### Shard scope example

This is the default behavior. You specify exactly which shard to back up:

```yaml
strategies:
  - name: customer-80
    keyspace: customer
    shard: "-80"
  - name: customer-80-
    keyspace: customer
    shard: "80-"
```

#### Keyspace scope example

Back up all shards in a keyspace without listing them individually:

```yaml
strategies:
  - name: customer-all
    scope: Keyspace
    keyspace: customer
```

#### Cluster scope example

Back up all shards in all keyspaces:

```yaml
strategies:
  - name: all-shards
    scope: Cluster
```

### Frequency-based scheduling

Instead of specifying a cron expression with `schedule`, you can use `frequency` with a Go duration string (like `24h`, `6h`, or `30m`). The `schedule` and `frequency` fields are mutually exclusive—you must use one or the other.

When you use `frequency`, the operator generates staggered cron schedules for each shard, preventing bandwidth spikes from simultaneous backups.

```yaml
apiVersion: planetscale.com/v2
kind: VitessBackupSchedule
metadata:
  name: daily-backup
spec:
  cluster: example
  frequency: "24h"
  strategies:
    - name: all-shards
      scope: Cluster
```

With frequency-based scheduling:
- Each shard gets a deterministic cron schedule offset within the interval
- Different shards back up at different times, spreading the load
- You can view the generated schedules in `.status.generatedSchedules` and the next scheduled times in `.status.nextScheduledTimes`

Supported frequencies must be representable as cron expressions. Common values include `30m`, `1h`, `2h`, `4h`, `6h`, `8h`, `12h`, and `24h`. If you specify an unsupported frequency (such as `45m` or `90m`), the operator rejects the configuration with an error message listing valid examples.

### Combining scopes with overrides

When you define a Keyspace-scope strategy for a keyspace, that keyspace is automatically excluded from any Cluster-scope strategies. This lets you set cluster-wide defaults while overriding specific keyspaces.

To use different frequencies for different parts of your cluster, create separate `VitessBackupSchedule` resources:

```yaml
# Cluster-wide default: daily backups
apiVersion: planetscale.com/v2
kind: VitessBackupSchedule
metadata:
  name: cluster-daily
spec:
  cluster: example
  frequency: "24h"
  strategies:
    - name: all
      scope: Cluster
---
# Override for customer keyspace: every 6 hours
apiVersion: planetscale.com/v2
kind: VitessBackupSchedule
metadata:
  name: customer-frequent
spec:
  cluster: example
  frequency: "6h"
  strategies:
    - name: customer-all
      scope: Keyspace
      keyspace: customer
```

In this example, the `customer` keyspace is backed up every 6 hours, while all other keyspaces are backed up daily. There's no overlap or duplicate backups because the Keyspace-scope strategy automatically excludes `customer` from the Cluster-scope strategy.

Shard-scope strategies do not trigger exclusion. They are additive, allowing you to schedule extra backups for specific high-traffic shards.

### Shard readiness requirements

Before scheduling a backup for a shard, the operator verifies that the shard is ready:

- The shard has a primary tablet
- The shard has an initial backup (from vtbackup)
- All tablets in the shard are in a ready state

If a shard doesn't meet these requirements (for example, during initial cluster bootstrap or while resharding), the operator skips scheduling backups for that shard and retries on the next reconcile. This prevents backup failures for shards that are still being set up.

### Adding the schedule

{{< warning >}}
Please note that is not recommended to run production backups every two minutes. These schedules are only an example.
{{</ warning >}}

For this example we are going to create two schedules: each will be executed every two minutes, the first one will backup
the two `customer` shards, and the second one will backup the `commerce` keyspace.
The backups will be stored directly inside the Minikube node, but if you want to backup to a cloud storage provider like S3, you can
change the `location` of the backup in `401_scheduled_backups.yaml`.

```bash
kubectl apply -f 401_scheduled_backups.yaml
```

After two minutes, we should see three new pods that were created by the operator. Under the hood, these pods
are managed by a Kubernetes Job, and their goal is to take a backup of Vitess, as we defined in the `strategies` field
of the `401_scheduled_backups.yaml` file.

```bash
$ kubectl get pods -n example
NAME                                                              READY   STATUS      RESTARTS      AGE
...
example-vbsc-commerce-ca641fc1-commerce-x-x-1740521040-b892727l   0/1     Completed   0             2m7s
example-vbsc-customer-05e172de-customer-80-x-1740521---04ar59dk   0/1     Completed   0             2m17s
example-vbsc-customer-05e172de-customer-x-80-1740521---6535gj8c   0/1     Completed   0             2m17s
...
```

### Listing backups

Now we can list the available backups by getting the `vtb` (`VitessBackup`) objects in our Kubernetes cluster.
We can see six backups: For every keyspace/shard, one backup by the initial vtbackup pod, that spawns
as we create a new shard, and we can see a second backup created more recently (~46 seconds ago) by the scheduled
backup CRD.

```bash
$ minikube ssh
docker@minikube:~$ sudo chmod o+rwx -R /tmp/example/ # required to give Minikube permissions to read the Vitess backups
docker@minikube:~$ exit

$ kubectl get vtb -n example
NAME                                                      AGE
example-commerce-x-x-20250225-214735-b82e162-74db1145     16m
example-commerce-x-x-20250225-220602-47f20b54-75d9f5c5    46s
example-customer-80-x-20250225-215751-5e335eca-fb525825   6m51s
example-customer-80-x-20250225-220602-706d77e3-b930b08c   46s
example-customer-x-80-20250225-215747-c74a3a36-45b61315   6m51s
example-customer-x-80-20250225-220558-26a8bbfe-0b58cca8   46s
```

### Cleanup

Congratulations, you have correctly scheduled recurring backups of your Vitess cluster.

If you want, you can now clean up the entire cluster by running: `minikube delete`. 
