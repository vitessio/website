---
title: Scheduled Backups
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
$ kubectl get pods
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

$ kubectl get vtb
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
