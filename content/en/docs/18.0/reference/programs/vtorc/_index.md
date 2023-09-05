---
title: vtorc
series: vtorc
---
## vtorc



```
vtorc [flags]
```

### Options

```
      --allow-emergency-reparent                     Whether VTOrc should be allowed to run emergency reparent operation when it detects a dead primary (default true)
      --audit-file-location string                   File location where the audit logs are to be stored
      --audit-purge-duration duration                Duration for which audit logs are held before being purged. Should be in multiples of days (default 168h0m0s)
      --audit-to-backend                             Whether to store the audit log in the VTOrc database
      --audit-to-syslog                              Whether to store the audit log in the syslog
      --clusters_to_watch strings                    Comma-separated list of keyspaces or keyspace/shards that this instance will monitor and repair. Defaults to all clusters in the topology. Example: "ks1,ks2/-80"
      --config string                                config file name
  -h, --help                                         help for vtorc
      --instance-poll-time duration                  Timer duration on which VTOrc refreshes MySQL information (default 5s)
      --prevent-cross-cell-failover                  Prevent VTOrc from promoting a primary in a different cell than the current primary in case of a failover
      --reasonable-replication-lag duration          Maximum replication lag on replicas which is deemed to be acceptable (default 10s)
      --recovery-period-block-duration duration      Duration for which a new recovery is blocked on an instance after running a recovery (default 30s)
      --recovery-poll-duration duration              Timer duration on which VTOrc polls its database to run a recovery (default 1s)
      --security_policy string                       the name of a registered security policy to use for controlling access to URLs - empty means allow all for anyone (built-in policies: deny-all, read-only)
      --shutdown_wait_time duration                  Maximum time to wait for VTOrc to release all the locks that it is holding before shutting down on SIGTERM (default 30s)
      --snapshot-topology-interval duration          Timer duration on which VTOrc takes a snapshot of the current MySQL information it has in the database. Should be in multiple of hours
      --sqlite-data-file string                      SQLite Datafile to use as VTOrc's database (default "file::memory:?mode=memory&cache=shared")
      --topo-information-refresh-duration duration   Timer duration on which VTOrc refreshes the keyspace and vttablet records from the topology server (default 15s)
      --wait-replicas-timeout duration               Duration for which to wait for replica's to respond when issuing RPCs (default 30s)
```

