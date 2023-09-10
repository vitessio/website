---
title: init
series: mysqlctl
---
## mysqlctl init

Initializes the directory structure and starts mysqld.

```
mysqlctl init [flags]
```

### Options

```
  -h, --help                      help for init
      --init_db_sql_file string   Path to .sql file to run after mysqld initiliaztion.
      --wait_time duration        How long to wait for mysqld startup. (default 5m0s)
```

### Options inherited from parent commands

```
      --mysql_port int           MySQL port. (default 3306)
      --mysql_socket string      Path to the mysqld socket file.
      --security_policy string   the name of a registered security policy to use for controlling access to URLs - empty means allow all for anyone (built-in policies: deny-all, read-only)
      --tablet_uid uint32        Tablet UID. (default 41983)
```

### SEE ALSO

* [mysqlctl](../)	 - mysqlctl initializes and controls mysqld with Vitess-specific configuration.

