---
title: Vttestserver Docker Image
weight: 4
featured: true
aliases: ['/docs/tutorials/vttestserver/']
---

This guide covers using the vttestserver docker image for testing purposes. This is also the docker image that we use for testing in [Vitess Framewok Testing](https://github.com/planetscale/vitess-framework-testing).

## Get the docker image

The first step is to get the docker image. There are two ways of doing this :

### <span style="color:red"> 1. From the vitessio/vitess repository </span>

#### Check out the vitessio/vitess repository

Clone the GitHub repository via:

- SSH: `git clone git@github.com:vitessio/vitess.git`, or:
- HTTP: `git clone https://github.com/vitessio/vitess.git`

```shell
cd vitess
```

#### Build the docker image

In your shell, execute:

```shell
make docker_vttestserver
```

This creates 2 docker images named `vitess/vttestserver:mysql57` and `vitess/vttestserver:mysql80`

### <span style="color:red"> 2. Pulling from docker hub </span>

Alternately, you can get the latest docker images from the docker hub. In your shell, execute:

```shell
docker pull vitess/vttestserver:mysql57
docker pull vitess/vttestserver:mysql80
```

## Run the docker image

At this point, you should have a docker image named `vitess/vttestserver:mysql57` or `vitess/vttestserver:mysql80`.

### Environment variables

The docker image expects some of the environment variables to be set to function properly. The following table lists all the environment variables available along with their usages.

| Environment variable | Required | Use |
| -- | -- | -- |
| *KEYSPACES* | yes | Specifies the names of the keyspaces to be created as a comma separated value. |
| *NUM_SHARDS* | yes | Specifies the number of shards in each keyspace. It is a comma separated value as well, read in conjunction with the KEYSPACES. |
| *PORT* | yes | The starting of the port addresses that vitess will use to register its components like vtgate, etc. |
| *MYSQL_MAX_CONNECTIONS* | no | Maximum number of connections that the MySQL instance will support. If unspecified, it defaults to 1000. |
| *MYSQL_BIND_HOST* | no | Which host to bind the MySQL listener to. If unspecified, it defaults to `127.0.0.1`. |
| *MYSQL_SERVER_VERSION* | no | MySQL server version to advertise. If unspecified, it defaults to `8.0.21-vitess` or `5.7.9-vitess` according to the version of vttestserver run. |
| *CHARSET* | no | Default charset to use. If unspecified, it defaults to `utf8mb4`. |
| *FOREIGN_KEY_MODE* | no | This is to provide how to handle foreign key constraint in create/alter table. Valid values are: allow (default), disallow. |
| *ENABLE_ONLINE_DDL* | no | Allow users to submit, review and control Online DDL. Valid values are: true (default), false. |
| *ENABLE_DIRECT_DDL* | no | Allow users to submit direct DDL statements. Valid values are: true (default), false. |
| *PLANNER_VERSION* | no | Sets the default planner to use when the session has not changed it. Valid values are: Gen4 (default), v3, Gen4Greedy and Gen4Fallback. Gen4Fallback tries the new gen4 planner and falls back to the V3 planner if the gen4 fails. |

Environment variables in docker can be specified using the `-e` aka `--env` flag.

### Sending queries to vttestserver container from outside

The vtgate listens for MySQL connections on 3 + the `PORT` environment variable specified. i.e. if you specify `PORT` to be 33574, then vtgate will be listening to connections on 33577, on the `MYSQL_BIND_HOST` which defaults to localhost. But this port will be on the docker container side. To connect to vtgate externally from a MySQL client, you will need to publish that port as well and specify the `MYSQL_BIND_HOST` to `0.0.0.0`. This can be done via the `-p` aka `--publish` flag to docker. For eg: adding `-p 33577:33577` to the `docker
run` command will publish the container's 33577 port to your local 33577 port, which can now be used to connect to the vtgate.

## Example

An example command to run the docker image is as follows :

```shell
docker run --name=vttestserver -p 33577:33577 -e PORT=33574 -e PLANNER_VERSION=gen4fallback -e KEYSPACES=test,unsharded -e NUM_SHARDS=2,1 -e MYSQL_MAX_CONNECTIONS=70000 -e MYSQL_BIND_HOST=0.0.0.0 --health-cmd="mysqladmin ping -h127.0.0.1 -P33577" --health-interval=5s --health-timeout=2s --health-retries=5 vitess/vttestserver:mysql57
```

Now, we can connect to the vtgate from a MySQL client as follows :
 
```shell
mysql --host 127.0.0.1 --port 33577 --user "root"
```

We have 2 keyspaces which we can use, `test` which has 2 shards and `unsharded` which has a single shard.
