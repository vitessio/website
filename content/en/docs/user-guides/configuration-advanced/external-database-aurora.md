---
title: Configure Vitess with with RDS
weight: 
---

## Overview

This draft guide input provides Aurora/MySQL creation instructions and adds new files to vitess examples/local to demonstrate vttablet with Aurora.  
High level:
        Log in to AWS console
        Create vitess-tuned parameter groups (2)
        Create the Auroroa cluster and instance (single)
        Add new "external" scripts to ../example/local and ../examples/local/scripts
        Prepare the database for vitess with a special db_init script
        Run the main script and connect through vitess

Details:

1. To accommodate specific vitess needs, we create two new parameter groups.  They are copied from default ones.
    Beware they are both named the same but of two "Types": 
      a) One at the Cluster level:
         Cloned from cluster parameter group type (DB cluster Parameter groups): default.aurora-mysql5.7,
         and named (for example): auroratest-cluster-mysql57

         Edit this new parameter group for the following parameters:
             binlog_format:               ROW
             gtid_mode:                   ON
             enforce_gtid_consistency:    ON
             sql_mode                     STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION


      b) One at the DB instance level:
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


3. Modify examples/local with the additional following files
        external_aurora.sh*
        init_vt_external_aurora.sql
        vttablet-external-aurora-up.sh  IMPORTANT: make sure to place this in the ..examples/local/scripts subdirectory


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
