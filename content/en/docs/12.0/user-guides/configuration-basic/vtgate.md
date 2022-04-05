---
title: vtgate
weight: 11
---

VTGates are the primary interface to the application. They do not have any persistent state. You can bring up as many vtgates as necessary. An application can connect to any vtgate to get access to all the servers within a cell. We recommend configuring a load balancer to distribute traffic between them. A typical rule of thumb would be to bring up as many vtgates as there are vttablets.

It is better to bring up multiple vtgates within a single machine rather than trying to run a single instance that tries to use all the resources. This approach enables better amortization of Go’s garbage collector.

You can bring up the vtgates before creating any keyspaces or bringing up vttablets. The advantage of bringing up the vtgates last is that it allows them to immediately discover the existing vttablets. Otherwise, it will take up to one polling cycle before they are discovered. The default value for this flag (`-tablet_refresh_interval`) is one minute. If you intend to reduce this value, ensure that the increased polling frequency will not overwhelm the toposerver.

VTGate requires a cell to operate in. A vtgate’s main job is to forward requests to the vttablets in the local cell. However, vtgates can go cross-cell in two situations:

* vtgate receives queries to the primary, and the primary is not in the current cell.
* vtgate was configured to go to other cells in case no local vttablets were available.

Here is a sample vtgate invocation:

```text
vtgate <topo_flags> \
  -log_dir=${VTDATAROOT}/tmp \
  -cell=cell1 \
  -cells_to_watch=cell1 \
  -tablet_types_to_wait=PRIMARY,REPLICA \
  -port=15001 \
  -mysql_server_port=15306 \
  -mysql_auth_server_impl=static \
  -mysql_auth_server_static_file=mysql_creds.json \
  -grpc_port=15991 \
  -service_map='grpc-vtgateservice' \
  -vschema_ddl_authorized_users='dba%'
```
VTGate uses the global topo to get the topo addresses of the cells it has to watch. For this reason, you do not need to specify the topo addresses for the current cell.

VTGate does not require `<backup_flags>`.

For sending primary queries across cells, you must specify an additional `cells_to_watch` flag. This will make the vtgates watch those additional cells, and will allow them to keep track of the primaries in those cells.

The `cells_to_watch` flag is a required parameter and must at least include the current cell. This is an [issue](https://github.com/vitessio/vitess/issues/6126) we will fix soon.

Going cross-cell for non-primary requests is an advanced use case that requires setting up cell aliases. This topic will not be covered in this user guide.

For those who wish to use the MySQL protocol, you must specify a `mysql_server_port` and a `mysql_auth_server_impl` for configuring authentication. Predefined auth servers are `clientcert`, `static`, `ldap` and `none`. The most commonly used authentication is `static` that  allows you to specify the credentials through a `mysql_auth_server_static_file` parameter.

The `vschema_ddl_authorized_users` specifies which users can alter the vschema by issuing “vschema ddls” directly to vtgate. VSchema DDL is an experimental feature that will be documented soon.

Here are the contents of an example file that shows the ability to specify MySQL native passwords as well as plain text:

```json
{
  "mysql_user": [
    {
      "MysqlNativePassword": "*9E128DA0C64A6FCCCDCFBDD0FC0A2C967C6DB36F",
      "Password": "mysql_password",
      "UserData": "mysql_user"
    }
  ],
  "mysql_user2": [
    { 
      "Password": "mysql_password",
      "UserData": "mysql_user"
    }
  ],
  "mysql_user3": [
    {
      "MysqlNativePassword": "*9E128DA0C64A6FCCCDCFBDD0FC0A2C967C6DB36F",
      "UserData": "mysql_user"
    }
  ]
}
```

For those who wish to use the Java or Go grpc clients to vtgate, you must also configure `grpc_port` and specify the service map as `service_map='grpc-vtgateservice'`. Note that the `VStream` feature is only available via grpc.

You can also set the following flags to control load-balancing for replicas:

* `discovery_high_replication_lag_minimum_serving`: If the replication lag of a vttablet exceeds this value, vtgate will treat it as unhealthy and will not send queries to it. This value is meant to match vttablet’s `unhealthy_threshold` value.
* `discovery_low_replication_lag`: If a single vttablet lags beyond this value, vtgate will not send it any queries. However, if too many replicas exceed this threshold, then vtgate will send queries to the ones that have the least lag. A weighted average algorithm is used to exclude the outliers. This value is meant to match vttablet’s `degraded_threshold` value.

A vtgate that comes up successfully will show all the vttablets it has discovered in its `/debug/status` page under the `Health Check Cache` section.

![vtgate-healthy-tablets](../img/vtgate-healthy-tablets.png)

If vtgates cannot connect to one of the vttablets it discovered from the topo, or if the vttablet is unhealthy, it will be shown in red in the `Health Check Cache`, and a corresponding error message will be displayed next to it:

![vtgate-partially-healthy-tablets](../img/vtgate-partially-healthy-tablets.png)

You can verify that the vtgates came up successfully by using the MySQL client:

```text
~/...vitess/examples/local> mysql -h 127.0.0.1 -P 15306 --user=mysql_user --password=mysql_password
[snip]
mysql> show databases;
+----------+
| Database |
+----------+
| commerce |
+----------+
1 row in set (0.00 sec)
```

The `show databases` command presents the `commerce` keyspace as a database. Under the covers, the MySQL database backing it is actually `vt_commerce`.

Congratulations! You have successfully brought up a Vitess cluster.
