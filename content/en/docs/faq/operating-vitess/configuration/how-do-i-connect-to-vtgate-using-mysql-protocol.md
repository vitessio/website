---
title: "How do I connect to vtgate using MySQL protocol?"
shorten_nav_links: true
notoc: true
weight: 1
---

In the example [vtgate-up.sh](https://github.com/vitessio/vitess/blob/main/examples/common/scripts/vtgate-up.sh) script you'll see the following lines:

```sh
--mysql_server_port $mysql_server_port \
--mysql_server_socket_path $mysql_server_socket_path \
--mysql_auth_server_static_file "./mysql_auth_server_static_creds.json" \
```

In this example, vtgate accepts MySQL connections on port 15306 and the authentication information is stored in the json file. You can then connect to it using the following command:

```sh
mysql -h 127.0.0.1 -P 15306 -u mysql_user --password=mysql_password
```
