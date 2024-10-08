---
title: Information Gathering
description: Frequently Asked Questions about Vitess
weight: 2
---

## Capturing a tcpdump network trace for vtgate

Occasionally, when a problem is application or application MySQL driver specific, you may want to collect a tcpdump network trace of the data flowing from the application to the vtgate MySQL listener.

In a production environment, this may be complicated by the fact that you may have a network loadbalancer in front of multiple vtgate instances.  In this case, you may have to run network captures across multiple hosts hosting the vtgate instances simultaneously to get all the information we need to debug the problem.  However, the method for collecting the network trace on each host would remain the same.

To collect a network trace, let's review what you need:

- You will typically need sudo or root access on the host in question to capture network traffic.
- You need to determine which TCP port your vtgate instance is listening on.  If you look at your vtgate start script or at a process listing via:

```sh
ps -ef | grep vtgate
```

- You should see the vtgate port as the value of the -mysql_server_port parameter.  Make a note of this port number.
- Next, you need to determine which physical network interface the application traffic is coming into the vtgate server.  Typically it could be something like eth0 or eno0, but you would verify by checking the output of: 

```sh
ip addr
```

- and matching up the ip address the application is using to access the vtgate instance.

To actually capture the traffic (we assume you are using sudo) run:

```sh
sudo tcpdump -i<interface> -s0 -n -nn -B 32768 -w /path/to/tempfile.dump port <tcpport>
```

Where:

- <interface> is the physical network interface you determined earlier, e.g. eth0
 - /path/to/tempfile.dump is the filesystem path to a location where you have sufficient space for the dump file.  Note that in a production environment, a tcpdump of live traffic can generate a dumpfile of many gigabytes pretty quickly, so be careful.
- <tcpport> is the port number you determined earlier that vtgate is listening on for MySQL traffic.

When you are done, you can use this dump file to review these logs for any errors or issues.

## Collecting information for troubleshooting

In order to troubleshoot issues occurring in your implementation of Vitess you will need to provide the community as much context as possible.

When you reach out you should include, if possible, a summary/overview deployment document of what components are involved and how they interconnect, etc. Customers often maintain something like this for internal support purposes.

Beyond the overview deployment document, we recommend that for the best experience, you collect as many of the items listed below as possible from production Vitess systems:

- Logs (vtgate, vttablet, underlying MySQL)
- Metrics (vtgate, vttablet, underlying MySQL)
- Other statistics (MySQL processlist, MySQL InnoDB engine status, etc.)
- Application DB pool configurations
- Load balancer configurations (if in the MySQL connection path)
- Historical load patterns