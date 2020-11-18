---
title: Configure Vitess with with CloudSQL
weight: 
---

## Overview

This draft guide input provides CloudSQL creation instructions and adds new files to vitess examples/local to demonstrate vttablet with CloudSQL.  
High level:
        Log in to GCP console
  Create an instance, including vitess-specific parameters
        Add new "external" scripts to ../example/local and ../examples/local/scripts
        Prepare the database for vitess with a special db_init script
        Run the main script and connect through vitess

Details:
1. Log in to GCP and create a CloudSQL instance
   Database Engine:                  MySQL
   Instance ID:                      cloudsqltest1
   Root password:                    scalewithvitess (default user account is root)
   Region / Zone:                    us-west1 / uswest1-a (example)
   Database version:                 MySQL 5.7
   Connectivity:                     Public IP
   Authorized networks:              <your network IP/CIDR block>
   Machine type:                     db-f1-micro  (example, for simple demo purposes)
   Storage type:                     SSD
   Storage capacity:                 20 GB
   Enable automatic storage increases
   Backups, recovery, and HA
      Enable Automate backups
      Enable PITR
      Availability:                  Single zone
  Flags - Set the following:
             binlog_row_image:            FULL
             sql_mode:                    STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION
      
        All remaining configuration parameters can be left to defaults.   


2. Modify examples/local with the additional following files:
            external_cloudsql.sh*
            init_vt_external_cloudsql.sql (actual database cloudsqltest1 is created here)
            vttablet-external-cloudsql-up.sh .  IMPORTANT: make sure to place this in the ..examples/local/scripts subdirectory

      NOTE: Be sure  to modify scripts/vttablet-external-cloudsql-up.sh for the actual values for -db_host, e.g.:
        -db_host <host or IP>


3. Create the actual database and prepare it for vitess:

   a) Run the script init_vt_external_cloudsql.sql directly on the CloudsSQL instance.
      This will instantiate the both the application database cloudsqltest1 and the default vitess accounts.
      Make sure you include the database name, e.g.,:
        mysql --host <host IP> --port 3306 --user=root --password=scalewithvitess < init_vt_external_cloudsql.sql 

   b) For completeness, create the demo application tables:
        mysql --host <host IP> --port 3306 --user=root --password=scalewithvitess -D cloudsqltest1 < create_commerce_schema.sql


4. Execute the main script:
        ./external_cloudsql.sh

   and expect the folllwing output:
        calling mkdir /Users/chrisr/temp/vt/vtdataroot/vt_0000000500
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
        If this is not what you expected, check the input data (as JSON parsing will skip unexpected fields).
        starting vtgate
        Waiting for vtgate to be up...
        vtgate is up!
        Access vtgate at http://Mars.local:15001/debug/status


6. Connect to vitess:
        mysql -A -f 127.0.0.1 -P 3306 -umysql_user -pmysql_password -D cloudsqltest1


