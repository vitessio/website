---
title: Run Vitess with Vagrant
description: Instructions for building Vitess on your machine for testing and development purposes using Vagrant
weight: 4
featured: true
aliases: ['/docs/tutorials/vagrant/']
---

[Vagrant](https://www.vagrantup.com/) is a tool for building and managing virtual machine environments in a single workflow. With an easy-to-use workflow and focus on automation, Vagrant lowers development environment setup time, increases production parity, and makes the "works on my machine" excuse a relic of the past.

{{< warning >}}
The [local build instructions for macOS](../../contributing/build-on-macos/) have improved signficantly over the last few months, and our Vagrant deployment has not kept up with all core-Vitess changes. We are currently [seeking a new maintainer](https://github.com/vitessio/vitess/issues/5723) for Vagrant. If we do not find a maintainer, we intend to deprecate support for Vagrant.
{{< /warning >}}

The following guide will show you how to build and run Vitess in your local environment using this tool. 

{{< info >}}
If you run into issues or have questions, we recommend posting in our [Slack channel](https://vitess.slack.com), click the Slack icon in the top right to join. This is a very active community forum and a great place to interact with other users.
{{< /info >}}

## Install dependencies

1. Install [Vagrant](https://www.vagrantup.com/downloads.html) in your OS. 
1. Install [Virtual Box](https://www.virtualbox.org/)


## Build Vitess {#build-vitess-vagrant}

1. Clone Vitess repo into your local environment:

    ```sh
    git clone https://github.com/vitessio/vitess.git 
    ```

2. From the repo directory run the following command:

    ```sh
    vagrant up
    ```
    
    This will bootstrap the VM with all Vitess dependencies.

3. Once the bootstrap is done run the following:

    ```sh
    vagrant ssh
    ```

    The first time you connect to the VM, it will automatically build vitess for you.

4. Moving forward, if you want to build the project you just need to run:
    ```sh
    make build
    ```

## Run Tests

{{< info >}}
If you are using etcd, set the following environment variable:

```sh
export VT_TEST_FLAGS='--topo-server-flavor=etcd2'
```

If you are using Consul, set the following environment variable:

```sh
export VT_TEST_FLAGS='--topo-server-flavor=consul'
```
{{< /info >}}

The default targets when running `make test` contain a full set of tests intended to help Vitess developers to verify code changes. Those tests simulate a small Vitess cluster by launching many servers on the local machine. To do so, they require a lot of resources; a minimum of 8GB RAM and SSD is recommended to run the tests.

If you want only to check that Vitess is working in your environment, you can run a lighter set of tests:

```sh
make site_test
```

## Start a Vitess cluster

After completing the instructions above to [build Vitess](#build-vitess-vagrant), you can use the example scripts in the GitHub repo to bring up a Vitess cluster on your local machine. These scripts use `etcd2` as the default [topology service](../../concepts/topology-service) plugin.

1. **Start Cluster**

    ```sh
    (local) vagrant@vitess:/vagrant/src/vitess.io/vitess$ vagrant-scripts/vitess/start.sh
    ```

    **Note:** This will start a full Vitess cluster with a single shard and five tablets. 

2. **Connect to VTGate**
   
    From the VM, you can connect to VTGate using the MySQL protocol with the following command:
    
    ```sh
    mysql -umysql_user -pmysql_password -h vitess -P 15306
    ``` 
   
    There is a messages table ready for you to use:

    ```sh
    mysql> select count(*) from messages;
    +----------+
    | count(*) |
    +----------+
    |        0 |
    +----------+
    1 row in set (0.01 sec)
    ```

    Also, vtgate admin UI is available in http://localhost:15001
   
3. **Connect to Vtctld**
    
    Vitess cluster admin control UI is available in http://localhost:15000
   

### Run a Client Application

The `client.py` file is a simple sample application that connects to `vtgate` and executes some queries. To run it, you need to either

* use the `client.sh` wrapper script, which temporarily sets up the environment and then runs `client.py`.

    ```sh
    export VTROOT=/vagrant
    export VTDATAROOT=/tmp/vtdata-dev
    export MYSQL_FLAVOR=MySQL56
    cd "$VITESS_WORKSPACE"/examples/local
    ./client.sh
    ### example output:
    # Inserting into master...
    # Reading from master...
    # (5L, 1462510331910124032L, 'V is for speed')
    # (15L, 1462519383758071808L, 'V is for speed')
    # (42L, 1462510369213753088L, 'V is for speed')
    # ...
    ```

There are also sample clients in the same directory for Java, PHP, and Go. See the comments at the top of each sample file for usage instructions.

### Tear down the cluster

When you are done testing, you can tear down the cluster with the following script: 

```sh
(local) vagrant@vitess:/vagrant/src/vitess.io/vitess$ vagrant-scripts/vitess/stop.sh
```

## Troubleshooting

If anything goes wrong, check the logs in your `$VTDATAROOT/tmp` directory for error messages. There are also some tablet-specific logs, as well as MySQL logs in the various `$VTDATAROOT/vt_*` directories.

If you need help diagnosing a problem, send a message to our [Slack channel](https://vitess.slack.com). In addition to any errors you see at the command-line, it would also help to upload an archive of your `VTDATAROOT` directory to a file sharing service and provide a link to it.
