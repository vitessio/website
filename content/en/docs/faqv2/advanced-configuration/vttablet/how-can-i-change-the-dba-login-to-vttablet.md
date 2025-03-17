---
title: "How can I change the DBA login to VTTablet?"
shorten_nav_links: true
notoc: true
weight: 4
---

If you are concerned about access security and want to change the admin user account for a given VTTablet you will need to perform the following steps:  
1. Create the new user in the database. 
2. Give that user the required permissions. The list of what Vitess requires can be found [here](https://github.com/vitessio/vitess/blob/master/config/init_db.sql).
3. Then when you start up Vitess you need to pass in the username and passwords to Vitess. That is done by setting `--db_user` and `--db-credentials-file`. The credentials file will have the format:

```sh
 {
   "<user name>": [
       "<password>"
   ]
 }
 ```

After you have followed the above steps the credentials file will tell VTTablet the account to use to connect to the database. 

You can read additional details on the credentials file format [here](https://github.com/vitessio/vitess/blob/master/examples/local/mysql_auth_server_static_creds.json).
