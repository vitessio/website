---
title: Configure Vitess with with Aurora
weight: 
---

## Overview

This guide provides instructions on how to create a vttablet for an external database located within Aurora.  

The general steps to follow are below:

1. Log in to your AWS console
2. Create a Vitess tuned parameter group 
3. Create the Aurora cluster and instance
4. Configure your VPC and security groups
5. Prepare the Aurora database for Vitess
6. Run the Vitess Aurora script 
7. Connect to Vitess  

## 1. Log in to your AWS console

You will need to use your AWS account user credentials on the [Sign in page](https://signin.aws.amazon.com/console).

 ## 2. Create a Vitess tuned parameter group

You will then need to create a new parameter group for Vitess. This can be copied from a default one. 
The default you want to clone from is: default.aurora-mysql5.7 and can be named similarly to: auroratest-db-mysql57
You will need to edit and save your new parameter group with the following parameter changes:

* binlog_format: ROW
* gtid_mode: ON
* enforce_gtid_consistency: ON
* sql_mode: STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION

## 3. Create an Aurora instance with the following configuration choices:
        
* Method: Standard Create
* Engine Option: Amazon Aurora
* Edition: Amazon Aurora with MySQL compatibility
* Version: Aurora (MySQL)-5.7.12
* Template: Dev/Test
* DB cluster identifier: auroratest1
* Credential settings: admin / **********
* DB instance size:  <something small/simple for testing>
* Multi-AZ: Don't create
* Connectivity: Default VPC
* Publicly accessible: YES
* Database port: 3306
* Database authentication: Password
* DB instance identifier: auroratest1-instance-1
* Initial database name: auroratest1
* DB cluster parameter group: Your custom CLUSTER parameter group, e.g., example: auroratest-cluster-mysql57
* DB parameter group: Your custom DB parameter group, e.g., example: auroratest-db-mysql57

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

Run the script init_vt_external_aurora.sql directly on your Aurora instance to create the default Vitess accounts. This script is found in the [/examples/local](https://github.com/vitessio/vitess/tree/master/examples/local) GitHub repository for Vitess:

```sh       
mysql --host <host string> --port 3306 --user=admin --password=********* -D auroratest1 < init_vt_external_aurora.sql
```

Then create the example application tables:

```sh 
mysql --host <host string> --port 3306 --user=admin --password=********* -D auroratest1 < create_commerce_schema.sql
```


## 6. Execute the Vitess Aurora script

Run the following script found in the [/examples/local](https://github.com/vitessio/vitess/tree/master/examples/local) GitHub repository for Vitess:

./external_aurora.sh

After you have run the script you should expect output similar to the following:

```sh
calling mkdir /Users/user/temp/vt/vtdataroot/vt_0000000500
add /vitess/global
add /vitess/zone1
add zone1 CellInfo
etcd start done...
Starting vtctld...
running ./scripts/vttablet-external-aurora-up.sh
Starting vttablet for zone1-0000000500...
with VTDATAROOT=/Users/user/temp/vt/vtdataroot
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

You can also check the input data to confirm the scripts completion:

 ```sh
starting vtgate
Waiting for vtgate to be up...
vtgate is up!
Access vtgate at http://Mars.local:15001/debug/status
 ```

## 7. Connect to Vitess

```sh
mysql -A -f 127.0.0.1 -P 3306 -umysql_user -pmysql_password -D auroratest1
 ```
 