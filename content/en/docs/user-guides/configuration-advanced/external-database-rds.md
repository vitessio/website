---
title: Configure Vitess with with RDS
weight: 
---

## Overview

This guide provides instructions on how to create a vttablet for an external database located within RDS. 

The general steps to follow are below:

1. Log in to your AWS console
2. Create a vitess-tuned parameter group 
3. Create the RDS cluster and instance (single)
4. Prepare the database for vitess with a special db_init script
5. Run the main script  
6. Connect to Vitess  

## 1. Log in to your AWS console


 
 ## 2. Create a Vitess tuned parameter group
  
To accommodate specific vitess needs, you will need to create a new parameter group. This can be copied from a default one. 
The default to clone from is: default.mysql5.7 and can be named similarly to: rdstest-external-mysql57
You will need to edit and save your new parameter group with the following parameter changes:

* binlog_format: ROW
* gtid_mode: ON
* enforce_gtid_consistency: ON
* sql_mode: STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION

## 3. Create an RDS instance 

You will need to crate an RDS instance with the following configuration choices:

* Method: Standard Create
* Engine Option: MySQL
* Edition: MySQL Community
* Version: MySQL 5.7.26 (example)
* Template: Free tier
* DB instance identifier: rdstest1
* Credential settings: admin / **********
* DB instance size: Standard classes (example db.t2.large)
* Storage: General Purpose
* Allocated Storage: 20 GIB
* Storage Autoscaling: Enabled
* Availability: Do not create a standby instance
* Connectivity: Default VPC
* Subnet Group: default
* Publicly accessible: Yes
* Availability zone: <any>
* Database port: 3306
* Database authentication: Password
* DB instance identifier: rdstest1-instance-1
* Initial database name: rdstest1
* DB parameter group:  Your custom DB parameter group, e.g., example: rdstest-external-mysql57
* Option Group: default
 
 All remaining configuration parameters can be left at their defaults and you may want to enable Log exports
 
You will need to configure your VPC as follows:
            
planetscale
                default
You will also need to make sure that one of the security groups has added the following:    
                    Type            Protocol    Port range    Source    
                    ------------    --------    ----------    ------    
                    MYSQL/Aurora    TCP         3306          0.0.0.0/0 


## 4. Run the script init_vt_external_rds.sql directly on the rds instance, to instantiate the default vitess accounts e.g.,:
        mysql --host <host string> --port 3306 --user=admin --password=********* -D rdstest1 < init_vt_external_rds.sql

        and, for completeness, create the demo application tables:
        mysql --host <host string> --port 3306 --user=admin --password=********* -D rdstest1 < create_commerce_schema.sql



## 5. Execute the main script:
        ./external_rds.sh

   and expect the following output:
        calling mkdir /Users/chrisr/temp/vt/vtdataroot/vt_0000000500
        add /vitess/global
        add /vitess/zone1
        add zone1 CellInfo
        etcd start done...
        Starting vtctld...
        running ./scripts/vttablet-external-rds-up.sh
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


## 6. Connect to vitess:
        mysql -A -f 127.0.0.1 -P 3306 -umysql_user -pmysql_password -D rdstest1
