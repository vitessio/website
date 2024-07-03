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
Please note that is not recommended to run production backups every minute. These schedules are only an example.
{{</ warning >}}

For this example we are going to create two schedules: each will be executed every minute, the first one will backup
the two `customer` shards, and the second one will backup the `commerce` keyspace.
The backups will be stored directly inside the Minikube node, but if you want to backup to a cloud storage provider like S3, you can
change the `location` of the backup in `401_scheduled_backups.yaml`.

```bash
kubectl apply -f 401_scheduled_backups.yaml
```

After a minute or so, we should see two new pods that were created by the operator. Under the hood, these pods
are managed by a Kubernetes Job, and their goal is to take a backup of Vitess, as we defined in the `strategies` field
of the `401_scheduled_backups.yaml` file.

```bash
$ kubectl get pods
NAME                                                           READY   STATUS             RESTARTS        AGE
...
example-vbsc-every-minute-commerce-ac6ff735-1715963880-4rt6r   0/1     Completed          0               31s
example-vbsc-every-minute-customer-8aaaa771-1715963880-n7cm7   0/1     Completed          0               31s
...
```

### Listing backups

Now we can list the available backups, by getting the `vtb` (`VitessBackup`) objects in our Kubernetes cluster.
We can see we have three backups, that is because the schedule `every-minute-customer` takes two backups (one for each shard, `-80` and `80-`),
and the other schedule (`every-minute-commerce`) takes only one backup (for the shard `-`). 

```bash
$ kubectl get vtb --no-headers
example-commerce-x-x-20240517-163802-97ece60f-8f2a3d47    111s
example-customer-80-x-20240517-163812-70e40ad-78a0d60b    58s
example-customer-x-80-20240517-163803-729301e-02e8899b    111s
```

Since we are running on Minikube, our backups are stored locally on the Minikube node, we can take a look at them like so:

```bash
$ minikube ssh
docker@minikube:~$ cd /tmp/example/
docker@minikube:/tmp/example$ ls
commerce  customer
docker@minikube:/tmp/example$ ls commerce/-/ customer/
-80/ 80-/ 
docker@minikube:/tmp/example$ ls -l commerce/-/ customer/-80/ customer/80-/
commerce/-/:
total 0
drwxr-xr-x 2 999 docker 220 May 17 16:38 2024-05-17.163802.zone1-2548885007
drwxr-xr-x 2 999 docker 220 May 17 16:39 2024-05-17.163903.zone1-2548885007
drwxr-xr-x 2 999 docker 220 May 17 16:40 2024-05-17.164003.zone1-2548885007
drwxr-xr-x 2 999 docker 220 May 17 16:41 2024-05-17.164102.zone1-2548885007
drwxr-xr-x 2 999 docker 220 May 17 16:42 2024-05-17.164202.zone1-2548885007

customer/-80/:
total 0
drwxr-xr-x 2 999 docker 220 May 17 16:38 2024-05-17.163803.zone1-0120139806
drwxr-xr-x 2 999 docker 220 May 17 16:39 2024-05-17.163902.zone1-2289928654
drwxr-xr-x 2 999 docker 220 May 17 16:40 2024-05-17.164003.zone1-2289928654
drwxr-xr-x 2 999 docker 220 May 17 16:41 2024-05-17.164102.zone1-2289928654
drwxr-xr-x 2 999 docker 220 May 17 16:42 2024-05-17.164202.zone1-2289928654

customer/80-/:
total 0
drwxr-xr-x 2 999 docker 220 May 17 16:38 2024-05-17.163812.zone1-0118374573
drwxr-xr-x 2 999 docker 220 May 17 16:39 2024-05-17.163911.zone1-4277914223
drwxr-xr-x 2 999 docker 220 May 17 16:40 2024-05-17.164010.zone1-4277914223
drwxr-xr-x 2 999 docker 220 May 17 16:41 2024-05-17.164111.zone1-4277914223
drwxr-xr-x 2 999 docker 220 May 17 16:42 2024-05-17.164208.zone1-4277914223
docker@minikube:/tmp/example$
```

### Cleanup

Congratulations, you have correctly scheduled recurring backups of your Vitess cluster.

If you want, you can now clean up the entire cluster by running: `minikube delete`. 
