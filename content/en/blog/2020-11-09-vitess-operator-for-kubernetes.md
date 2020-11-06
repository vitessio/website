---
author: 'Alkin Tezuysal'
date: 2020-11-09
slug: '2020-11-09-vitess-operator-for-kubernetes'
tags: ['Vitess','MySQL','kubernetes','operator','cloud','GKE','sharding']
title: 'Vitess Operator for Kubernetes'

---
### Introduction 
In this blog, I would like to uncover our newly announced [Vitess Operator for Kubernetes](https://github.com/planetscale/vitess-operator). This post demonstrates the sample implementation of [Vitess](https://vitess.io/) in Kubernetes topology. I also explore common DBA tasks by demonstrating how they are handled in the Vitess ecosystem. Vitess, out of the box, comes with a lot of tools and utilities that one has to either incorporate or develop to manage MySQL topology. Let’s take a look at the capabilities of Vitess in these areas and demonstrate how they are performed under the operator realm. 
#### Prerequisites 
* GKE Account 
* Kubectl 
* MySQL Client 
* Install vtctlclient locally 
   * go get vitess.io/vitess/go/cmd/vtctlclient 
* Download the Operator example files
   * git clone git@github.com:vitessio/vitess.git 
* cd vitess/examples/operator
* Run sample database implementation (Optional). 

#### Install the Vitess Operator
```sh linenums="1"
$ gcloud container clusters create vitess-k8s-operator --cluster-version 1.14 --zone us-east1-b --enable-autoscaling --min-nodes 8 --max-nodes 12
Creating cluster vitess-k8s-operator in us-east1-b... Cluster is being health-checked (master is healthy)...done.
Created [https://container.googleapis.com/v1/projects/planetscale-dev/zones/us-east1-b/clusters/vitess-k8s-operator].
To inspect the contents of your cluster, go to: https://console.cloud.google.com/kubernetes/workload_/gcloud/us-east1-b/vitess-k8s-operator?project=planetscale-dev
kubeconfig entry generated for vitess-k8s-operator.

NAME                 LOCATION    MASTER_VERSION  MASTER_IP      MACHINE_TYPE   NODE_VERSION    NUM_NODES  STATUS
vitess-k8s-operator  us-east1-b  1.14.10-gke.50  35.237.26.125  n1-standard-1  1.14.10-gke.50  3          RUNNING
```
```
$ cd vitess/examples/operator
$ kubectl apply -f operator.yaml
customresourcedefinition.apiextensions.k8s.io/etcdlockservers.planetscale.com created
customresourcedefinition.apiextensions.k8s.io/vitessbackups.planetscale.com created
customresourcedefinition.apiextensions.k8s.io/vitessbackupstorages.planetscale.com created
customresourcedefinition.apiextensions.k8s.io/vitesscells.planetscale.com created
customresourcedefinition.apiextensions.k8s.io/vitessclusters.planetscale.com created
customresourcedefinition.apiextensions.k8s.io/vitesskeyspaces.planetscale.com created
customresourcedefinition.apiextensions.k8s.io/vitessshards.planetscale.com created
serviceaccount/vitess-operator created
role.rbac.authorization.k8s.io/vitess-operator created
rolebinding.rbac.authorization.k8s.io/vitess-operator created
priorityclass.scheduling.k8s.io/vitess created
priorityclass.scheduling.k8s.io/vitess-operator-control-plane created
deployment.apps/vitess-operator created

$ kubectl get pods
NAME                               READY   STATUS    RESTARTS   AGE
vitess-operator-8454d86687-hv9lg   1/1     Running   0          41s
```
Bring up an initial test cluster
```
$ kubectl apply -f 101_initial_cluster.yaml
vitesscluster.planetscale.com/example created
secret/example-cluster-config created

$ kubectl get pods
NAME                                             READY   STATUS    RESTARTS   AGE
example-etcd-faf13de3-1                          1/1     Running   0          54s
example-etcd-faf13de3-2                          1/1     Running   0          54s
example-etcd-faf13de3-3                          1/1     Running   0          53s
example-vttablet-zone1-2469782763-bfadd780       3/3     Running   1          54s
example-vttablet-zone1-2548885007-46a852d0       2/3     Running   1          54s
example-zone1-vtctld-1d4dcad0-59d8498459-54p68   1/1     Running   1          54s
example-zone1-vtgate-bc6cde92-6fcfbb6666-5bcjc   1/1     Running   1          53s
vitess-operator-8454d86687-hv9lg                 1/1     Running   0          2m28s
```
Setup Port-forward
```
$ ./pf.sh &
[1] 34424
askdba:operator askdba$ You may point your browser to http://localhost:15000, use the following aliases as shortcuts:
alias vtctlclient="vtctlclient -server=localhost:15999 -logtostderr"
alias mysql="mysql -h 127.0.0.1 -P 15306 -u user"
Hit Ctrl-C to stop the port forwards
Forwarding from 127.0.0.1:15306 -> 3306
Forwarding from [::1]:15306 -> 3306
Forwarding from 127.0.0.1:15000 -> 15000
Forwarding from [::1]:15000 -> 15000
Forwarding from 127.0.0.1:15999 -> 15999
Forwarding from [::1]:15999 -> 15999
```
```
$ vtctlclient ApplySchema -sql="$(cat create_commerce_schema.sql)" commerce
$ vtctlclient ApplyVSchema -vschema="$(cat vschema_commerce_initial.json)" commerce
Handling connection for 15999
New VSchema object:
{
  "tables": {
    "corder": {
    },
    "customer": {
    },
    "product": {
    }
  }
}
If this is not what you expected, check the input data (as JSON parsing will skip unexpected fields).
```

After this section it’s recommended to to continue with the sample [database](https://vitess.io/docs/get-started/local/) steps to have a running database in this cluster(optional). 
### Database Operations

In this section as we’ve mentioned above, I’d like to show how to perform functional operations as follows: 

1. Backup & Recovery 
2. Failover to Replica 
3. Schema Change

#### Backup Vitess Tablet

At this stage, our cluster within Kubernetes is up, but backups won’t work until we configure a place to store them. 
First, we will check existing backups and as you can see there are none.
```$ kubectl get vitessbackups
No resources found in default namespace.
```
In order to perform backups, we need to set up a backup storage bucket in GCS.
Fill in your own values for all the my-* names. The bucket name in particular must be globally unique across all GCS users.
Select GCP project
```
$  gcloud config set project [project-name]
Updated property [core/project].
```
Create a GCS bucket
```
$  gsutil mb -l us-central1 -b on gs://my-vitess-operator-backup-bucket
Creating gs://my-vitess-operator-backup-bucket/...
```
Create a GCP service account
```
$ gcloud iam service-accounts create my-backup-service-account
Created service account [my-backup-service-account].
```
Grant the service account access to the bucket gsutil iam ch
```
$ gsutil iam ch serviceAccount:my-backup-service-account@planetscale-dev.iam.gserviceaccount.com:objectViewer,objectCreator,objectAdmin gs://my-vitess-operator-backup-bucket
```
Create and download a key for the service account
```
$ gcloud iam service-accounts keys create ~/gcs_key.json --iam-account my-backup-service-account@planetscale-dev.iam.gserviceaccount.com
created key [ccd65b5a198298f9ca07ee6ab901a2492ea142c7] of type [json] as [/Users/askdba/gcs_key.json] for [my-backup-service-account@planetscale-dev.iam.gserviceaccount.com]
```
Upload the service account key as a k8s Secret
```
$ kubectl create secret generic gcs-auth --from-file=gcs_key.json="$HOME/gcs_key.json"
secret/gcs-auth created
```
Delete the local copy
```
$ rm ~/gcs_key.json
```
Check Tablet(s) status
```
$ kubectl describe vt | grep 'Tablets'
      Desired Tablets:  2
      Ready Tablets:    2
      Tablets:          2
      Updated Tablets:  2
      Desired Tablets:  6
      Ready Tablets:    6
      Tablets:          6
      Updated Tablets:  6
```
Note: The numbers will be different if you ran the optional sample database steps. 
At this stage, our cluster still has no association with the GSC bucket. We need to apply the correct backup method (xtrabackup) and bucket definition to the cluster via YAML file.

Add a backup section under spec in each VitessCluster YAML before applying it. Since this is an idempotent operation we can edit and re-apply 101_initial_cluster.yaml file.
```
yaml
spec: 
  backup:
    engine: xtrabackup
    locations:
    - gcs:
      bucket: my-vitess-backup-bucket
      authSecret:
        name: gcs-auth
        key: gcs_key.json
```
```
$ kubectl apply -f 101_initial_cluster.yaml
vitesscluster.planetscale.com/example configured
secret/example-cluster-config configured
$ kubectl get pods
NAME                                                 READY   STATUS             RESTARTS   AGE
example-90089e05-vitessbackupstorage-subcontroller   1/1     Running            0          29s
example-commerce-x-x-vtbackup-init-c6db73c9          0/1     CrashLoopBackOff   1          29s
example-etcd-faf13de3-1                              1/1     Running            0          7m51s
example-etcd-faf13de3-2                              1/1     Running            0          7m51s
example-etcd-faf13de3-3                              1/1     Running            0          7m51s
example-vttablet-zone1-2469782763-bfadd780           3/3     Running            0          15s
example-vttablet-zone1-2548885007-46a852d0           3/3     Running            2          7m51s
example-zone1-vtctld-1d4dcad0-59d8498459-qg4rv       1/1     Running            3          7m51s
example-zone1-vtgate-bc6cde92-6fcfbb6666-gz6mm       1/1     Running            3          7m50s
vitess-operator-8454d86687-m225m                     1/1     Running            0          8m5s
```

If we had configured backups in the VitessCluster before the initial deployment, the operator would initialize backup storage automatically. Since we initially started the cluster without backups configured, the automatic backup initialization will fail:
```
$ kubectl logs example-commerce-x-x-vtbackup-init-c6db73c9
ERROR: logging before flag.Parse: E0928 12:08:20.897936       1 syslogger.go:122] can't connect to syslog
E0928 12:08:21.075860       1 vtbackup.go:177] Can't take backup: refusing to upload initial backup of empty database: the shard commerce/- already has at least one tablet that may be serving (zone1-2469782763); you must take a backup from a live tablet instead
```
This means we need to take a backup manually to initialize backup storage:
```
$ vtctlclient -logtostderr BackupShard commerce/-
…
I0928 15:13:29.818114   80158 main.go:64] I0928 12:13:29.492382 backup.go:162] I0928 12:13:29.492048 xtrabackupengine.go:309] xtrabackup stderr: 200928 12:13:29 [00] Streaming <STDOUT>
I0928 15:13:29.818123   80158 main.go:64] I0928 12:13:29.492404 backup.go:162] I0928 12:13:29.492133 xtrabackupengine.go:309] xtrabackup stderr: 200928 12:13:29 [00]        ...done
I0928 15:13:29.818131   80158 main.go:64] I0928 12:13:29.492415 backup.go:162] I0928 12:13:29.492217 xtrabackupengine.go:309] xtrabackup stderr: xtrabackup: Transaction log of lsn (2747504) to (2747513) was copied.
I0928 15:13:29.818145   80158 main.go:64] I0928 12:13:29.594417 backup.go:162] I0928 12:13:29.593983 xtrabackupengine.go:309] xtrabackup stderr: 200928 12:13:29 completed OK!
I0928 15:13:29.818160   80158 main.go:64] I0928 12:13:29.622037 backup.go:162] I0928 12:13:29.615593 xtrabackupengine.go:631] Found position: 3d370970-0182-11eb-9c3b-767b9aee7c34:1-9,3d3e599f-0182-11eb-88a6-a69501e63cc3:1-3
I0928 15:13:29.818168   80158 main.go:64] I0928 12:13:29.622109 backup.go:162] I0928 12:13:29.615717 xtrabackupengine.go:115] Closing backup file backup.xbstream.gz-000
I0928 15:13:30.160490   80158 main.go:64] I0928 12:13:29.999008 backup.go:162] I0928 12:13:29.996710 xtrabackupengine.go:115] Closing backup file backup.xbstream.gz-001
I0928 15:13:30.321497   80158 main.go:64] I0928 12:13:30.160952 backup.go:162] I0928 12:13:30.160183 xtrabackupengine.go:115] Closing backup file backup.xbstream.gz-002
I0928 15:13:30.493284   80158 main.go:64] I0928 12:13:30.333110 backup.go:162] I0928 12:13:30.332349 xtrabackupengine.go:115] Closing backup file backup.xbstream.gz-003
I0928 15:13:30.594650   80158 main.go:64] I0928 12:13:30.433818 backup.go:162] I0928 12:13:30.433292 xtrabackupengine.go:115] Closing backup file backup.xbstream.gz-004
I0928 15:13:30.752338   80158 main.go:64] I0928 12:13:30.591845 backup.go:162] I0928 12:13:30.590837 xtrabackupengine.go:115] Closing backup file backup.xbstream.gz-005
I0928 15:13:30.862331   80158 main.go:64] I0928 12:13:30.702971 backup.go:162] I0928 12:13:30.702169 xtrabackupengine.go:115] Closing backup file backup.xbstream.gz-006
I0928 15:13:31.027650   80158 main.go:64] I0928 12:13:30.868250 backup.go:162] I0928 12:13:30.867350 xtrabackupengine.go:115] Closing backup file backup.xbstream.gz-007
I0928 15:13:31.209019   80158 main.go:64] I0928 12:13:31.049203 backup.go:162] I0928 12:13:31.047831 xtrabackupengine.go:162] Writing backup MANIFEST
I0928 15:13:31.209046   80158 main.go:64] I0928 12:13:31.049501 backup.go:162] I0928 12:13:31.048074 xtrabackupengine.go:196] Backup completed
I0928 15:13:31.209057   80158 main.go:64] I0928 12:13:31.049599 backup.go:162] I0928 12:13:31.048087 xtrabackupengine.go:115] Closing backup file MANIFEST
```
Within a minute or so, we should see the new backup appear when listing VitessBackup CRDs:
```
$ kubectl get pods
NAME                                                 READY   STATUS    RESTARTS   AGE
example-90089e05-vitessbackupstorage-subcontroller   1/1     Running   0          6m41s
example-etcd-faf13de3-1                              1/1     Running   0          14m
example-etcd-faf13de3-2                              1/1     Running   0          14m
example-etcd-faf13de3-3                              1/1     Running   0          14m
example-vttablet-zone1-2469782763-bfadd780           3/3     Running   0          6m27s
example-vttablet-zone1-2548885007-46a852d0           3/3     Running   0          5m33s
example-zone1-vtctld-1d4dcad0-59d8498459-qg4rv       1/1     Running   3          14m
example-zone1-vtgate-bc6cde92-6fcfbb6666-gz6mm       1/1     Running   3          14m
vitess-operator-8454d86687-m225m                     1/1     Running   0          14m
$ kubectl get vitessbackups
NAME                                                     AGE
example-commerce-x-x-20200928-121327-97ece60f-b8bc0ec7   2m18s
```

#### Restore Vitess Tablet 
Under normal circumstances, you shouldn’t ever have to restore a backup manually. Extending the number of tablets in a cluster will make the new vttablets automatically restore from the latest backup, then point themselves at the current master. Once caught up, they’ll go into serving state. Here’s how to do it manually for demonstration purposes.
```
$ vtctlclient ListAllTablets
Handling connection for 15999
zone1-2469782763 commerce - master 10.100.1.37:15000 10.100.1.37:3306 []
zone1-2548885007 commerce - replica 10.100.4.17:15000 10.100.4.17:3306 []

$ vtctlclient -logtostderr RestoreFromBackup zone1-2548885007
I0928 15:28:04.783441   80378 main.go:64] I0928 12:28:04.172914 backup.go:247] I0928 12:28:04.172087 xtrabackupengine.go:398] Restore: returning replication position 3d370970-0182-11eb-9c3b-767b9aee7c34:1-9,3d3e599f-0182-11eb-88a6-a69501e63cc3:1-3
I0928 15:28:04.783449   80378 main.go:64] I0928 12:28:04.173170 backup.go:247] I0928 12:28:04.172126 backup.go:308] Restore: starting mysqld for mysql_upgrade
I0928 15:28:07.271912   80378 main.go:64] I0928 12:28:07.177696 backup.go:247] I0928 12:28:07.176828 backup.go:315] Restore: running mysql_upgrade
I0928 15:28:08.752154   80378 main.go:64] I0928 12:28:08.657377 backup.go:247] I0928 12:28:08.656674 backup.go:326] Restore: populating local_metadata
I0928 15:28:08.777876   80378 main.go:64] I0928 12:28:08.683299 backup.go:247] I0928 12:28:08.682656 backup.go:334] Restore: restarting mysqld after mysql_upgrade
```
List cells/keyspaces/shards/tablets
```
$ kubectl describe vtc
Name:         example-zone1-5abb61ae
Namespace:    default
Labels:       planetscale.com/cell=zone1
              planetscale.com/cluster=example
Annotations:  <none>
API Version:  planetscale.com/v2
Kind:         VitessCell
Metadata:
  Creation Timestamp:  2020-09-28T12:00:26Z
  Generation:          1
  Owner References:
    API Version:           planetscale.com/v2
    Block Owner Deletion:  true
    Controller:            true
    Kind:                  VitessCluster
    Name:                  example
    UID:                   323a1cfa-0182-11eb-9bbc-42010a8e01fe
  Resource Version:        2105764
$  kubectl get vtk
NAME                        AGE
example-commerce-fb9b866a   30m
```
List tablets for a particular keyspace/shard
```
$  kubectl get pods -l planetscale.com/component=vttablet,planetscale.com/keyspace=commerce,planetscale.com/shard=x-x
NAME                                         READY   STATUS    RESTARTS   AGE
example-vttablet-zone1-2469782763-bfadd780   3/3     Running   0          24m
example-vttablet-zone1-2548885007-46a852d0   3/3     Running   0          23m
```

#### Failover Scenario
In this section, let’s say we think our primary is not in good shape and we’d like to force a failover to the replica. We could use the drain feature of the operator to request a graceful failover to a replica. The operator will choose another suitable replica if one is available, healthy, and not itself drained.

First check who is the current master of a given shard.
```
$ kubectl describe vts example-commerce-x-x-0f5afee6 | grep 'Master Alias'
  Master Alias:           zone1-2469782763
```
List tablets for that shard:
```
$ kubectl get pods -l planetscale.com/component=vttablet,planetscale.com/keyspace=commerce,planetscale.com/shard=x-x
NAME                                         READY   STATUS    RESTARTS   AGE
example-vttablet-zone1-2469782763-bfadd780   3/3     Running   0          28m
example-vttablet-zone1-2548885007-46a852d0   3/3     Running   0          27m

$ vtctlclient ListAllTablets
Handling connection for 15999
zone1-2469782763 commerce - master 10.100.1.37:15000 10.100.1.37:3306 []
zone1-2548885007 commerce - replica 10.100.4.17:15000 10.100.4.17:3306 []
```

Drain mastership to some other tablet (e.g. to prepare to drain the Node it’s on) by annotating the current master tablet.
```
$ kubectl annotate pod example-vttablet-zone1-2469782763-bfadd780 drain.planetscale.com/started="Draining for blog"
pod/example-vttablet-zone1-2469782763-bfadd780 annotated
```

Check failover status to see that a new master has been elected:

```
$ kubectl describe vts example-commerce-x-x-0f5afee6 | grep 'Master Alias'
  Master Alias:           zone1-2548885007
```

To avoid leaving any tablets in a drained state, we can undrain all of them by removing the annotation:
```
$ kubectl annotate pod -l planetscale.com/component=vttablet drain.planetscale.com/started-
pod/example-vttablet-zone1-2469782763-bfadd780 annotated
pod/example-vttablet-zone1-2548885007-46a852d0 annotated
```

At the time of writing this blog post there’s a huge amount of work by PlanetScale’s Vitess team to integrate failovers with the Orchestrator project. You can see a demo by Sugu here.
### Schema Changes

In this section, I’d like to demonstrate how to apply schema changes to the Vitess cluster. For this operation it’s possible to use the following methods:

* ApplySchema - We’ve seen examples of ApplySchema during initialization steps of the cluster. 
* VTGate - This is a method to send direct DDL statements to the Vitess cluster. 
* Directly to MySQL using Online Schema Change tools such as pt-online-schema and gh-ost. 
* New and Experimental in Vitess 8.0: managed Online DDL. Users will use a special ALTER TABLE syntax, either via ApplySchema or via VTGate, and Vitess will automate an online schema change via gh-ost or pt-online-schema-change on relevant shards, giving the user visibility and control over the migration. The user will not need to know how to run gh-ost or online-schema-change. Vitess will take care of setup, discovery, throttling, and finally, cleanup.


We find that there is no common practice to automating schema changes in production on large, sharded databases. Some companies develop their own automation flow. In many others that we’ve observed, schema changes are applied manually by database engineers. These engineers will have resolved which clusters are to be affected, which shards are in those clusters, which servers are in those shards, and what migration commands to run. The engineers will run gh-ost or online-schema-change manually, check for errors, and handle cleanup of tables and triggers etc. This is why we have created the Online DDL flow in [Vitess 8.0](https://github.com/vitessio/vitess/releases/tag/v8.0.0).

This new functionality is still Experimental, and we will discuss it another time. Meanwhile, let’s describe how an engineer would manage online schema changes directly, by running pt-online-schema-change manually on relevant shards. Our friends at Percona were kind enough to build a Docker Image with Percona Toolkit and MySQL Client. Here’s where you can find this image that we’re going to use as a sidecar to our operator implementation. This will give us a clean cluster with a sidecar built in. 

Note: This will remove customized backup configurations in prior sections. 
```
$ kubectl apply -f 101_initial_cluster.yaml.sidecar
vitesscluster.planetscale.com/example configured

$ kubectl get pods
NAME                                             READY   STATUS    RESTARTS   AGE
example-etcd-faf13de3-1                          1/1     Running   0          119m
example-etcd-faf13de3-2                          1/1     Running   0          119m
example-etcd-faf13de3-3                          1/1     Running   0          119m
example-vttablet-zone1-2469782763-bfadd780       4/4     Running   1          119m
example-vttablet-zone1-2548885007-46a852d0       4/4     Running   1          119m
example-zone1-vtctld-1d4dcad0-59d8498459-ksvqp   1/1     Running   2          119m
example-zone1-vtgate-bc6cde92-6fcfbb6666-2j9cz   1/1     Running   2          119m
vitess-operator-8454d86687-hj77s                 1/1     Running   0          3d5h

$ kubectl describe pods example-vttablet-zone1-2548885007-46a852d0 | grep percona
                            image: perconalab/percona-toolkit
                            name: percona-toolkit
```
Our default example consists of commerce database with three tables as seen below:
```
mysql> use commerce
Database changed
mysql> show tables;
+-----------------------+
| Tables_in_vt_commerce |
+-----------------------+
| corder                |
| customer              |
| product               |
+-----------------------+
3 rows in set (0.15 sec)
```

Let’s say we need to alter corder table and modify order_id column. We’ll assume this table is big so we would like to make this schema migration online with minimum impact to production workloads. 

```
$ vtctlclient ListAllTablets
Handling connection for 15999
zone1-2469782763 commerce - master 10.100.4.34:15000 10.100.4.34:3306 []
zone1-2548885007 commerce - replica 10.100.5.32:15000 10.100.5.32:3306 []

$ kubectl exec --stdin --tty -c percona-toolkit example-vttablet-zone1-2469782763-bfadd780  -- bash
```
```
bash-4.4$ pt-online-schema-change --socket /vt/socket/mysql.sock --user=vt_dba h=localhost,D=vt_commerce,t=corder --critical-load threads_running=10000000000 --max-load threads_running:20 --tries create_triggers:10000:1,drop_triggers:10000:1,swap_tables:10000:1,update_foreign_keys:10000:1,copy_rows:10000:1 --set-vars lock_wait_timeout=5 --pause-file=/tmp/pause-osc --alter="MODIFY order_id bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT" --recursion-method=none --execute
No slaves found.  See --recursion-method if host example-vttablet-zone1-2469782763-bfadd780 has slaves.
Not checking slave lag because no slaves were found and --check-slave-lag was not specified.
Operation, tries, wait:
  analyze_table, 10, 1
  copy_rows, 10000, 1
  create_triggers, 10000, 1
  drop_triggers, 10000, 1
  swap_tables, 10000, 1
  update_foreign_keys, 10000, 1
Altering `vt_commerce`.`corder`...
Creating new table...
Created new table vt_commerce._corder_new OK.
Altering new table...
Altered `vt_commerce`.`_corder_new` OK.
2020-10-12T12:09:05 Creating triggers...
2020-10-12T12:09:05 Created triggers OK.
2020-10-12T12:09:05 Copying approximately 1 rows...
2020-10-12T12:09:05 Copied rows OK.
2020-10-12T12:09:05 Analyzing new table...
2020-10-12T12:09:05 Swapping tables...
2020-10-12T12:09:05 Swapped original and new tables OK.
2020-10-12T12:09:05 Dropping old table...
2020-10-12T12:09:05 Dropped old table `vt_commerce`.`_corder_old` OK.
2020-10-12T12:09:05 Dropping triggers...
2020-10-12T12:09:05 Dropped triggers OK.
Successfully altered `vt_commerce`.`corder`.

$mysql -S /vt/socket/mysql.sock -u vt_dba
mysql> show create table corder;
+--------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Table  | Create Table                                                                                                                                                                                                                                                       |
+--------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| corder | CREATE TABLE `corder` (
  `order_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `customer_id` bigint(20) DEFAULT NULL,
  `sku` varbinary(128) DEFAULT NULL,
  `price` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 |
+--------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)
```
Let’s say we have followed the instructions and built a sharded cluster in such a state. 
```
$ echo "show vitess_tablets;" | mysql --table
Handling connection for 15306
+-------+----------+-------+------------+-------------+------------------+-------------+
| Cell  | Keyspace | Shard | TabletType | State       | Alias            | Hostname    |
+-------+----------+-------+------------+-------------+------------------+-------------+
| zone1 | commerce | -     | MASTER     | SERVING     | zone1-2469782763 | 10.100.6.13 |
| zone1 | commerce | -     | REPLICA    | SERVING     | zone1-2548885007 | 10.100.5.37 |
| zone1 | customer | -     | MASTER     | NOT_SERVING | zone1-1250593518 | 10.100.5.36 |
| zone1 | customer | -     | REPLICA    | SERVING     | zone1-3778123133 | 10.100.4.38 |
| zone1 | customer | -80   | MASTER     | SERVING     | zone1-0120139806 | 10.100.1.59 |
| zone1 | customer | -80   | REPLICA    | SERVING     | zone1-2289928654 | 10.100.2.25 |
| zone1 | customer | 80-   | MASTER     | SERVING     | zone1-0118374573 | 10.100.0.25 |
| zone1 | customer | 80-   | REPLICA    | SERVING     | zone1-4277914223 | 10.100.3.45 |
+-------+----------+-------+------------+-------------+------------------+-------------+
```
We would have to do the same for each shard’s MASTER. 

As you can see above the same approach can be followed with other tools such as gh-ost, proxysql etc. Sidecar approach is gaining popularity to tackle some of the operational database problems recently. 

### Conclusion

In conclusion, Vitess Operator is a very powerful option when it comes to deploying your database cluster in Kubernetes. By testing possibilities and initial challenges I hope you found this demonstration useful. Kubernetes Operators are growing rapidly and empower the world’s best cloud services.

#### Credits & References
* Percona Engineering and Release team
* PlanetScale Vitess Engineering team
