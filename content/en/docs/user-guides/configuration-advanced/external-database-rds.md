---
title: Configure Vitess with with RDS
weight: 
---

## Overview

This guide provides instructions on how to create a vttablet for an external database located within RDS. 

The general steps to follow are below:

1. Log in to your AWS console
2. Create a Vitess tuned parameter group 
3. Create the RDS cluster and instance
4. Configure your VPC and security groups
5. Prepare the RDS database for Vitess
6. Run the Vitess RDS script 
7. Connect to Vitess  

## 1. Log in to your AWS console

You will need to use your AWS account user credentials on the [Sign in page](https://signin.aws.amazon.com/console).
 
 ## 2. Create a Vitess tuned parameter group
  
You will then need to create a new parameter group for Vitess. This can be copied from a default one. 
The default you want to clone from is: default.mysql5.7 and can be named similarly to: rdstest-external-mysql57
You will need to edit and save your new parameter group with the following parameter changes:

* binlog_format: ROW
* gtid_mode: ON
* enforce_gtid_consistency: ON
* sql_mode: STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION

## 3. Create an RDS cluster and instance 

You will need to create an RDS cluster and instance with the following configuration choices:

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
 
 All remaining configuration parameters can be left at their defaults and you may want to enable log exports.
 
## 4. Configure your VPC and security groups

You will need to configure your VPC as follows:

```sh             
planetscale
default
```

You will also need to make sure that one of the security groups has added the following:    

+-------------------+-------+-----------+-------------+
|Type | Protocol | Port range | Source |    
+-------------------+-------+-----------+-------------+ 
| MYSQL/Aurora | TCP | 3306 | 0.0.0.0/0 
+-------------------+-------+-----------+-------------+ 

## 5. Prepare the RDS database for Vitess

Run the script init_vt_external_rds.sql directly on your RDS instance to create the default Vitess accounts. This script is found in the [/examples/local](https://github.com/vitessio/vitess/tree/master/examples/local) GitHub repository for Vitess:

```sh       
mysql --host <host string> --port 3306 --user=admin --password=********* -D rdstest1 < init_vt_external_rds.sql
```

Then create the example application tables:

```sh
mysql --host <host string> --port 3306 --user=admin --password=********* -D rdstest1 < create_commerce_schema.sql
```

## 6. Execute the Vitess RDS script

Run the following script found in the [/examples/local](https://github.com/vitessio/vitess/tree/master/examples/local) GitHub repository for Vitess:

./external_rds.sh

After you have run the script you should expect output similar to the following:

```sh
calling mkdir /Users/user/temp/vt/vtdataroot/vt_0000000500
add /vitess/global
add /vitess/zone1
add zone1 CellInfo
etcd start done...
Starting vtctld...
running ./scripts/vttablet-external-rds-up.sh
Starting vttablet for zone1-0000000500...
with VTDATAROOT=/Users/user/temp/vt/vtdataroot
HTTP/1.1 200 OK
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
 ```
 
You can also check the input data to confirm the scripts completion:

 ```sh
starting vtgate
Waiting for vtgate to be up...
vtgate is up!
Access vtgate at http://Mars.local:15001/debug/status
 ```

## 7. Connect to Vitess

```sh
mysql -A -f 127.0.0.1 -P 3306 -umysql_user -pmysql_password -D rdstest1
 ```
