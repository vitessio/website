---
title: VTTablet
description: Frequently Asked Questions about Vitess
weight: 3
---

## Can vttablets start without sql_mode set to STRICT_TRANS_TABLES?

Yes. This check can be disabled by  setting `-enforce_strict_trans_tables=false` on the vttablet.

## What does it mean if a vttablet is unhappy?

An unhappy vttablet is one that is at whatever limit to which the -degraded_threshold is set. An unhappy vttablet will still be serving queries. 

vtgate will always prefer happy vttablets over unhappy vttablets, however if all your vttablets are unhappy then it will serve all of them. 

To make sure that your vttablets are reporting their replica lag you need to set the flag `-enable_replication_reporter`.  With that flag set vttablets will transmit their replica lag to vtgates allowing them to balance load better. Enabling this flag will also cause vttablets to restart replication if it's stopped, as long as the flag `-disable_active_reparents` isn't set.

## Are there recommended thresholds for health statuses?

We don’t have recommended thresholds as Vitess doesn’t make any functional decisions based on the statuses, beyond representing the current status in the UI. You do need to be sure to set your alerting to something lower than the threshold you choose.

Another option is if you have the replication heartbeat enabled, you can monitor that statistic.  

Or if you’re exporting the mysqld stats using something like [this](https://github.com/prometheus/mysqld_exporter) you can monitor the replication lag via those statistics directly. 

If you are using this option you will need to set the alert at something like: "Fire when lag is > X seconds for Y minutes". Otherwise you'll get false alerts, since the seconds_behind_master reporting inside MySQL often jumps around when either the replication is stopped/started or when traffic is low. 

After either of those occur the seconds_behind_master reporting can take some time to settle. 

## How can I change the DBA login to vttablet?

If you are concerned about access security and want to change the admin user account for a given vttablet you will need to perform the following steps:  
1. Create the new user in the database. 
2. Give that user the required permissions.The list of what vitess requires can be found [here](https://github.com/vitessio/vitess/blob/master/config/init_db.sql).
3. Then when you start up Vitess you need to pass in the username and passwords to Vitess. That is done by setting `-db_user` and `-db-credentials-file`. The credentials file will have the format:

```sh
 {
   "<user name>": [
       "<password>"
   ]
 }
 ```

After you have followed the above steps the credentials file will tell vttablet the account to use to connect to the database. 

You can read additional details on the credentials file format [here](https://github.com/vitessio/vitess/blob/master/examples/local/mysql_auth_server_static_creds.json).

## If mysqld slave thread isn't running what restarts it?

The replication reporter will automatically restart mysqld slave thread if it is not running. The replication reporter can be enabled within vttablet with the flag `-enable_replication_reporter`.
