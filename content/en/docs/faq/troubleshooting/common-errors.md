---
title: Common Errors
weight: 1
---

## Why is an SQL update with a primary key slow?

Using tuples in a WHERE clause can cause a MySQL slowdown. Consider:

```sql
UPDATE tbl SET col=1 WHERE (pk1, pk2, pk3) IN (1,2,3), (4,5,6)
```

After a few tuples, MySQL may switch to a full table scan and lock the entire table for the duration. It should perform as expected once `FORCE INDEX (PRIMARY)` is added.  

You can read further information on 'FORCE INDEX' in the MySQL documentation [here](https://dev.mysql.com/doc/refman/8.0/en/index-hints.html).

## What can I do if I see a CPU increase after upgrading Vitess?

If you are running Vitess 7.0 or above, we introduced the schema tracker, which could be running on the VTTablets now. You can disable it in order to prevent that reporting. 

You will need to add `track_schema_versions` as false in the VTTablet.

## What are the steps to take after an unplanned failover?

In order to avoid creating orphaned VTTablets you will need to follow the steps below:

1. Stop the VTTablets
2. Delete the old VTTablet records
3. Create the new keyspace
4. Restart the VTTablets that are pointed at the new keyspace
5. Use TabletExternallyReparented to inform Vitess of the current primary
6. Recursively delete the old keyspace

## Error: Could not open required defaults file: /path/to/my.cnf

If you cannot start a cluster and see that error in the logs it most likely means that AppArmor is running on your server and is preventing Vitess processes from accessing the my.cnf file. 

The workaround is to uninstall AppArmor:

```sh
sudo service apparmor stop
sudo service apparmor teardown
sudo update-rc.d -f apparmor remove
```

You may also need to reboot the machine after this. Many programs automatically install AppArmor, so you may need to uninstall again.

## Error: mysqld not found in any of /usr/bin/{sbin,bin,libexec}

If you're all set up with Vitess but mysqld won't start, with an error like this:

```sh
E0430 17:02:43.663441    5297 mysqlctl.go:254] failed start mysql: mysqld not found in any of /usr/bin/{sbin,bin,libexec}
```

You will need to perform the following steps:

- Verify that mysqld is located in /usr/bin on all its hosts 
- Verify that PATH has been set and sourced in .bashrc 

If you have confirmed the above and are still getting the error referenced, it is likely that `VT_MYSQL_ROOT` has not been set correctly. 

On most systems `VT_MYSQL_ROOT` should be set to `/usr`  because Vitess expects to find a bin directory below that.

## What is the default behavior of connection pooling after a failover on an external (unmanaged) MySQL?

The expected behavior is that the connection to the old primary will close and that Vitess will try to reconnect to the new primary.

To ensure that the expected behavior occurs when using AWS/Aurora you will need to set the vttablet flag `-pool_hostname_resolve_interval` to something other than the default. This is because the default is 0. When this flag is set to the default, Vitess will never re-resolve the AWS/Aurora DNS name.
