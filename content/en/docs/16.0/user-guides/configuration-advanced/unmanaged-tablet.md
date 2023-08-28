---
title: Unmanaged Tablet
weight: 45
aliases: ['/docs/user-guides/unmanaged-tablet/']
---

{{< info >}}
This guide follows on from the [local](../../../get-started/local) installation guide.
{{< /info >}}

This guide uses the Vitess components vtctld, Topology Service and VTGate which have already been started in the local installation guide. It assumes that you have an existing MySQL Server setup that you would like to add to Vitess as a new keyspace, which we will call `legacy`. The same set of steps can be used to create a tablet that uses Amazon RDS, AWS Aurora, or Google CloudSQL.

## Ensure all components are up

You should have previously executed `./101_initial_cluster.sh` in the get-started guide. This will ensure that you have a Topology Service, vtgate, vtctld. For the unmanaged MySQL instance, I will be using an instance running on `127.0.0.1:5726`:

```bash
source ../common/env.sh

# verify vtgate/vitess is up and running
mysql commerce -e 'show tables'

# verify my unmanaged mysql is running
mysql -h 127.0.0.1 -P 5726 -umsandbox -pmsandbox legacy -e 'show tables'
```

<br>Output:

```text
$ source ../common/env.sh

$ # verify vtgate/vitess is up and running
$ mysql commerce -e 'show tables' 
+-----------------------+
| Tables_in_vt_commerce |
+-----------------------+
| corder                |
| customer              |
| product               |
+-----------------------+
$ # verify my unmanaged mysql is running 
$ mysql -h 127.0.0.1 -P 5726 -umsandbox -pmsandbox legacy -e 'show tables'
mysql: [Warning] Using a password on the command line interface can be insecure.
+------------------+
| Tables_in_legacy |
+------------------+
| legacytable      |
+------------------+
```

## Start a tablet to correspond to legacy

The variables `TOPOLOGY_FLAGS` and `VTDATAROOT` should already be in the environment from sourcing env.sh earlier. We will call the new tablet UID 401.

```bash
mkdir -p $VTDATAROOT/vt_0000000401
vttablet \
 $TOPOLOGY_FLAGS \
 --logtostderr \
 --log_queries_to_file $VTDATAROOT/tmp/vttablet_0000000401_querylog.txt \
 --tablet-path "zone1-0000000401" \
 --init_keyspace legacy \
 --init_shard 0 \
 --init_tablet_type replica \
 --port 15401 \
 --grpc_port 16401 \
 --service_map 'grpc-queryservice,grpc-tabletmanager,grpc-updatestream' \
 --pid_file $VTDATAROOT/vt_0000000401/vttablet.pid \
 --vtctld_addr http://localhost:15000/ \
 --db_host 127.0.0.1 \
 --db_port 5726 \
 --db_app_user msandbox \
 --db_app_password msandbox \
 --db_dba_user msandbox \
 --db_dba_password msandbox \
 --db_repl_user msandbox \
 --db_repl_password msandbox \
 --db_filtered_user msandbox \
 --db_filtered_password msandbox \
 --db_allprivs_user msandbox \
 --db_allprivs_password msandbox \
 --init_db_name_override legacy \
 --init_populate_metadata \
 --disable_active_reparents &
```

Note that if your tablet is using a MySQL instance type where you do not have `SUPER` privileges to the database
(e.g. AWS RDS, AWS Aurora or Google CloudSQL), you should omit the `--init_populate_metadata` flag. The `--init_populate_metadata` flag should only be enabled if the cluster is being managed through Vitess.

You should be able to see debug information written to screen confirming Vitess can reach the unmanaged server. A common problem is that you may need to change the authentication plugin to `mysql_native_password` (MySQL 8.0).

Assuming that there are no errors, after a few seconds you can mark the server as externally promoted to primary:

```bash
vtctldclient TabletExternallyReparented zone1-401
```

## Connect via VTGate

VTGate should now be able to route queries to your unmanaged MySQL server:

```bash
$ mysql legacy -e 'show tables'
+------------------+
| Tables_in_legacy |
+------------------+
| legacytable    |
+------------------+
``` 

You can even join between the unmanaged tablet and the managed tablets. Vitess will execute the query as a scatter-gather:

```sql
mysql> use commerce;
Database changed

mysql> select corder.order_id from corder inner join legacy.legacytable on corder.order_id=legacy.legacytable.id;
Empty set (0.01 sec)
```

## Move legacytable to the commerce keyspace

Move the table:
```bash
vtctlclient MoveTables -- --source legacy --tables 'legacytable' Create commerce.legacy2commerce 
```
<br>
Monitor the workflow:

use `Show` or `Progress`
```bash
vtctlclient MoveTables -- Show commerce.legacy2commerce
vtctlclient MoveTables -- Progress commerce.legacy2commerce
```

You can also use the [`Workflow show`](../../../reference/vreplication/workflow/) command to get the progress as it has much more info as well.

```bash
vtctlclient Workflow commerce.legacy2commerce show
```
<br>Switch traffic:
```bash
vtctlclient MoveTables -- --tablet_type=rdonly,replica SwitchTraffic commerce.legacy2commerce
```
<br>Complete the `MoveTables`:
```bash
vtctlclient MoveTables Complete commerce.legacy2commerce
```
<br>Verify that the table was moved:
```bash
source ../common/env.sh

# verify vtgate/vitess is up and running
mysql commerce -e 'show tables'

# verify my unmanaged mysql is running
mysql -h 127.0.0.1 -P 5726 -umsandbox -pmsandbox legacy -e 'show tables'
```
<br>Output:

```text
$ source ../common/env.sh
$ 
$ # verify vtgate/vitess is up and running
$ mysql commerce -e 'show tables' 
+-----------------------+
| Tables_in_vt_commerce |
+-----------------------+
| corder                |
| customer              |
| legacytable           |
| product               |
+-----------------------+
$ # verify my unmanaged mysql is running 
$ mysql -h 127.0.0.1 -P 5726 -umsandbox -pmsandbox legacy -e 'show tables'
mysql: [Warning] Using a password on the command line interface can be insecure.
```

