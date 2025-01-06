---
title: VTTablet
weight: 3
---

## Can VTTablets start without sql_mode set to STRICT_TRANS_TABLES?

Yes. This check can be disabled by  setting `--enforce_strict_trans_tables=false` on the VTTablet.

## What does it mean if a VTTablet is unhappy?

An unhappy VTTablet is one whose replication is lagging beyond the limit to which the `--degraded_threshold` is set. An unhappy VTTablet could still be serving queries. 

VTGate will always prefer happy VTTablets over unhappy VTTablets, however if all your VTTablets are unhappy then it will serve all of them. 

## Are there recommended thresholds for health statuses?

We don’t have recommended thresholds as Vitess doesn’t make any functional decisions based on the statuses, beyond representing the current status in the UI. You do need to be sure to set your alerting to something lower than the threshold you choose.

Another option is if you have the replication heartbeat enabled, you can monitor that statistic.  

Or if you’re exporting the mysqld stats using something like [mysqld-exporter](https://github.com/prometheus/mysqld_exporter) you can monitor the replication lag via those statistics directly. 

If you are using this option you will need to set the alert at something like: "Fire when lag is > X seconds for Y minutes". Otherwise you'll get false alerts, since the `Seconds_Behind_Source` reporting from MySQL often jumps around when either the replication is stopped/started or when traffic is low. 

After either of those occur the `Seconds_Behind_Source` reporting can take some time to settle. 

## How can I change the DBA login to VTTablet?

If you are concerned about access security and want to change the admin user account for a given VTTablet you will need to perform the following steps:  
1. Create the new user in the database. 
2. Give that user the required permissions. The list of what Vitess requires can be found [here](https://github.com/vitessio/vitess/blob/master/config/init_db.sql).
3. Then when you start up Vitess you need to pass in the username and passwords to Vitess. That is done by setting `--db_user` and `--db-credentials-file`. The credentials file will have the format:

```sh
 {
   "<user name>": [
       "<password>"
   ]
 }
 ```

After you have followed the above steps the credentials file will tell VTTablet the account to use to connect to the database. 

You can read additional details on the credentials file format [here](https://github.com/vitessio/vitess/blob/master/examples/local/mysql_auth_server_static_creds.json).

## If mysqld replication thread isn't running what restarts it?

VTOrc will automatically restart replication if it is not running.

## What is semi-sync replication?

Semi-sync replication enables you to prevent your primary from acknowledging a transaction to the client until a replica confirms that it has received all the changes. This adds an extra guarantee that at least one other machine has a copy of the changes.

This addresses the problem of a combination of lagging replication and network issues resulting in data loss. With semi-sync replication, even if you have network issues you shouldn’t lose your data.

Please do note that when using semi-sync replication you will have to wait for your data to flow from the primary to the replica and then get a confirmation back to the primary. Thus each transaction may take longer. The length of time depends on the round trip time from the primary to the replica.

## Why would I use semi-sync replication?

Semi-sync replication ensures data durability between the primary and at least one replica. Hardware failures are unavoidable but don't need to result in data loss if you run with semi-sync replication.
