---
title: Configuration
description: Frequently Asked Questions about Configuration
---

## Does the application need to know about the sharding scheme underneath Vitess?

The application does not need to know about how the data is sharded. This information is stored in a VSchema which the VTGate servers use to automatically route your queries. This allows the application to connect to Vitess and use it as if it’s a single giant database server.

### Can I override the default db name from vt_xxx to my own?

Yes. You can start vttablet with the `-init_db_name_override` command line option to specify a different db name. There is no downside to performing this override

### How do I connect to vtgate using MySQL protocol?

If you look at the example [vtgate-up.sh](https://github.com/vitessio/vitess/blob/master/examples/local/vtgate-up.sh) script, you'll see the following lines:

```shell
-mysql_server_port $mysql_server_port \
-mysql_server_socket_path $mysql_server_socket_path \
-mysql_auth_server_static_file "./mysql_auth_server_static_creds.json" \
```

In this example, vtgate accepts MySQL connections on port 15306 and the authentication info is stored in the json file. So, you should be able to connect to it using the following command:

```shell
mysql -h 127.0.0.1 -P 15306 -u mysql_user --password=mysql_password
```

## I cannot start a cluster, and see these errors in the logs: Could not open required defaults file: /path/to/my.cnf

Most likely this means that AppArmor is running on your server and is preventing Vitess processes from accessing the my.cnf file. The workaround is to uninstall AppArmor:

```shell
sudo service apparmor stop
sudo service apparmor teardown
sudo update-rc.d -f apparmor remove
```

You may also need to reboot the machine after this. Many programs automatically install AppArmor, so you may need to uninstall again.
