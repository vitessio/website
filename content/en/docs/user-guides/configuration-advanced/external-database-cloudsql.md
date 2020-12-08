---
title: Configure Vitess with with CloudSQL
weight: 
---

## Overview

This guide provides instructions on how to create a vttablet for an external database located within CloudSQL. 

The general steps to follow are below:

1. Log in to your GCP console
2. Create an CloudSQL cluster and instance 
3. Prepare the CloudSQL database for Vitess
4. Run the Vitess CloudSQL script 
5. Connect to Vitess  

## 1. Log in to your GCP console

You will need to use your GCP account user credentials on the [Sign in page](https://console.cloud.google.com/).

## 2. Create an CloudSQL cluster and instance 

You will need to create an CloudSQL cluster and instance with the following configuration choices:

* Database Engine: MySQL
* Instance ID: cloudsqltest1
* Root password: scalewithvitess (default user account is root)
* Region / Zone:  us-west1 / uswest1-a (example)
* Database version: MySQL 5.7
* Connectivity: Public IP
* Authorized networks: <your network IP/CIDR block>
* Machine type: db-f1-micro  (example, for simple demo purposes)
* Storage type: SSD
* Storage capacity: 20 GB
* Enable automatic storage increases
* Enable Automate backups
* Enable PITR
* Availability: Single zone
 
 You will need to set the following flags:
 
* binlog_row_image: FULL
* sql_mode: STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION
      
 All remaining configuration parameters can be left at their defaults and you may want to enable log exports.   

## 3. Prepare the CloudSQL database for Vitess

Run the script init_vt_external_cloudsql.sql directly on the CloudsSQL instance to create the default Vitess accounts. This script is found in the [/examples/local](https://github.com/vitessio/vitess/tree/master/examples/local) GitHub repository for Vitess:

```sh
mysql --host <host IP> --port 3306 --user=root --password=scalewithvitess < init_vt_external_cloudsql.sql 
```

Then create the example application tables:

```sh
mysql --host <host IP> --port 3306 --user=root --password=scalewithvitess -D cloudsqltest1 < create_commerce_schema.sql
```

## 4. Execute the Vitess CloudSQL script

Run the following script found in the [/examples/local](https://github.com/vitessio/vitess/tree/master/examples/local) GitHub repository for Vitess:

./external_cloudsql.sh

After you have run the script you should expect output similar to the following:

```sh
calling mkdir /Users/user/temp/vt/vtdataroot/vt_0000000500
add /vitess/global
add /vitess/zone1
add zone1 CellInfo
etcd start done...
Starting vtctld...
running ./scripts/vttablet-external-cloudsql-up.sh
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
 ```
 
You can also check the input data to confirm the scripts completion:

 ```sh
starting vtgate
Waiting for vtgate to be up...
vtgate is up!
Access vtgate at http://Mars.local:15001/debug/status
 ```

## 5. Connect to Vitess

```sh
mysql -A -f 127.0.0.1 -P 3306 -umysql_user -pmysql_password -D cloudsqltest1
 ```


