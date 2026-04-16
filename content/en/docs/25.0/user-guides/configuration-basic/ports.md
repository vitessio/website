---
title: Ports
weight: 16
aliases: ['/docs/launching/server-configuration/', '/docs/user-guides/server-configuration/', '/docs/user-guides/configuring-components/']
---
# Ports and Network interactions in Vitess

Many/most of these ports are fully configurable, but we are listing their
defaults or the defaults we use in examples here. Your
environment may differ considerably, depending on your configuration options
for the various components:

  * Data path:
    * Main query path:
      * application &rarr; vtgate
        * TCP port 3306 or 15306 (MySQL)
        * TCP port 15999 (gRPC)
      * vtgate &rarr; vttablet
        * TCP port 16000 + vttablet UID (gRPC); e.g port 16100 for UID 100
      * vttablet &rarr; MySQL
        * local Unix domain socket (if MySQL is local)
        * TCP port 3306 (if MySQL is remote)
      * vttablet &rarr; vttablet: vreplication within or across shards
        * TCP port 16000 + vttablet UID (gRPC); e.g port 16100 for UID 100
      * MySQL &rarr; MySQL:  within-shard replication
        * TCP port 3306 (MySQL protocol)
  * Control or meta-data paths:
    * vtctld &rarr; vttablet
      * TCP port 16000 + vttablet UID (gRPC); e.g port 16100 for UID 100
    * vtctldclient &rarr; vtctld
      * TCP port 15999 (gRPC)
    * vtadmin &rarr;
      * TCP port 14200 (gRPC and HTTP)
    * vtgate &rarr; topology server
      * Depends on topology server, e.g.:
         * for etcd typically TCP port 2379
         * for consul typically TCP port 8502
         * for zookeeper typically TCP port 2888
    * administrator using web browser &rarr; vtgate web UI
      * TCP port 15001 (HTTP)
    * administrator using web browser &rarr; vttablet web UI
      * TCP port 15000 + vttablet UID (HTTP); e.g port 15100 for UID 100
    * administrator using web browser &rarr; vtadmin web UI
      * TCP port 14201 (HTTP)
    * administrator using web browser &rarr; vtorc web UI
      * TCP port 16000 (HTTP)
    * Metrics scraper (e.g. Prometheus) &rarr; vtgate web port
      * TCP port 15001 (HTTP)
    * Metrics scraper (e.g. Prometheus) &rarr; vttablet web port
      * TCP port 15000 + vttablet UID (HTTP); e.g port 15100 for UID 100
    * Metrics scraper (e.g. Prometheus) &rarr; vtctld web port
      * TCP port 15000 (HTTP)

