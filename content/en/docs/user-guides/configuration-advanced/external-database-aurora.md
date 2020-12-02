---
title: Configure Vitess with with RDS
weight: 
---

## Overview

This guide provides instructions on how to create a vttablet for an external database located within Aurora.  

The general steps to follow are below:

1. Log in to your AWS console
2. Create a Vitess tuned parameter group 
3. Create the Aurora cluster and instance
4. Configure your VPC and security groups
5. Prepare the RDS database for Vitess
6. Run the Vitess RDS script 
7. Connect to Vitess  

## 1. Log in to your AWS console

You will need to use your AWS account user credentials on the [Sign in page](https://signin.aws.amazon.com/console).

 ## 2. Create a Vitess tuned parameter group

You will then need to create two new parameter groups for Vitess. One at the cluster level and the other at the database instance level. Both parameters are named the same but are two different types. They can be copied from default ones. 

### Cluster level
         
From the cluster parameter group type you will want to clone: default.aurora-mysql5.7 and can name it something similar to: auroratest-cluster-mysql57
You will need to edit and save your new parameter group with the following parameter changes:

* binlog_format: ROW
* gtid_mode: ON
* enforce_gtid_consistency: ON
* sql_mode: STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION

### Database instance level
         Cloned from "instance" parameter group type (Parameter groups):         default.aurora-mysql5.7
         and named (for example): auroratest-db-mysql57


2. Create an aurora instance with the following configuration choices:
        Method: Standard Create
        Engine Option:                      Amazon Aurora
        Edition:                            Amazon Aurora with MySQL compatibility
        Version:                            Aurora (MySQL)-5.7.12
        Template:                           Dev/Test
        DB cluster identifier:              auroratest1
        Credential settings:                admin / **********
        DB instance size:                   <something small/simple for testing>
        Multi-AZ:                           Don't create
        Connectivity:                       Default VPC
        Additional Connectivity: 
                Publicly accessible         YES
        VPC security groups (example):  
                planetscale
                default
            IMPORTANT: make sure one of the security groups has added the following:
            Type            Protocol    Port range    Source 
            ------------    --------    ----------    ------
            MYSQL/Aurora    TCP         3306          0.0.0.0/0

        Database port:                      3306
        Database authentication:            Password
        Additional configuration:
                DB instance identifier:     auroratest1-instance-1
                Initial database name:      auroratest1
                DB cluster parameter group: Your custom CLUSTER parameter group, e.g., example: auroratest-cluster-mysql57
                DB parameter group:         Your custom DB parameter group, e.g., example: auroratest-db-mysql57

        All remaining configuration parameters can be left to defaults.   You may wish to enable Log exports




4. Run the script init_vt_external_aurora.sql directly on the aurora instance, to instantiate the default vitess accounts e.g.,:
        mysql --host <host string> --port 3306 --user=admin --password=********* -D auroratest1 < init_vt_external_aurora.sql

        and, for completeness, create the demo application tables:
        mysql --host <host string> --port 3306 --user=admin --password=********* -D auroratest1 < create_commerce_schema.sql



5. Execute the main script:
        ./external_aurora.sh

   and expect the following output:
        calling mkdir /Users/chrisr/temp/vt/vtdataroot/vt_0000000500
        add /vitess/global
        add /vitess/zone1
        add zone1 CellInfo
        etcd start done...
        Starting vtctld...
        running ./scripts/vttablet-external-aurora-up.sh
        Starting vttablet for zone1-0000000500...
        with VTDATAROOT=/Users/chrisr/temp/vt/vtdataroot
        HTTP/1.1 200 OK
        Date: Fri, 10 Apr 2020 21:38:18 GMT
        Content-Type: text/html; charset=utf-8
        
        creating vschema
        New VSchema object:
        {
          "tables": {
            "corder": {
        
            },
            "customer": {
        
            },
            "product": {
        
            }
          }
        }
        If this is not what you expected, check the input data (as JSON parsing will skip unexpected fields).
        starting vtgate
        Waiting for vtgate to be up...
        vtgate is up!
        Access vtgate at http://Mars.local:15001/debug/status


6. Connect to vitess:
        mysql -A -f 127.0.0.1 -P 3306 -umysql_user -pmysql_password -D auroratest1
