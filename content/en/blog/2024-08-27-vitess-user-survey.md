---
author: 'Kirtan Chandak'
date: 2024-08-27
slug: '2024-08-27-vitess-user-survey'
tags: ['Vitess', 'PlanetScale', 'MySQL', 'VReplication', 'CDC', 'Debezium']
title: 'Vitess User Survey'
description: "Learn the basics of Change Data Capture (CDC) and how to leverage Vitess's VStream API to build data pipelines."
---

We recently conducted a survey of how Vitess is being used by the community. This blog post summarizes what we learned.

# What our users said - 

> **"Vitess solves an existential threat for services which outgrow a single MySQL database."**

> **"Horizontal sharding helps us scale quickly, and the new generation execution plan, Gen4, enables us to support more SQL queries."**

# Background

The story begins with the Vitess maintainer team wanting to conduct a user survey with community members and engineers using Vitess in production to gain a better understanding of how to improve the project. As an LFX Mentee'24, I worked with the Vitess maintainers to form the questions and create a format for conducting the user survey. We drafted the questions, reviewed them, and developed a final version of the survey. I'm happy to report that we received a number of responses.

# Summary Responses  - 

### 1. How long have you been using Vitess?
First of all, we decided to ask how long our community members have been using Vitess. Interestingly, quite a few people have been using Vitess for more than 3 years. 
<div style="width:500px">
<img src="/files/2024-08-27-vitess-user-survey/1-vitess-long.png" alt="Vitess Project Booth" style="margin-top:6px"/>
</div>

### 2. Are you running Vitess in production?
More than half of Vitess users have been in production for over 3 years, and an additional 25% have been in production for over 1 year.
<div style="width:500px">
<img src="/files/2024-08-27-vitess-user-survey/2-production.png" alt="Vitess Project Booth" style="margin-top:6px"/>
</div>

### 3. How often do you upgrade your Vitess version?
The most popular frequency for Vitess version upgrades is once a year. New versions of Vitess are released 3 times a year, and many users follow the same schedule.
<div style="width:500px">
<img src="/files/2024-08-27-vitess-user-survey/3-vitess-version-often.png" alt="Vitess Project Booth" style="margin-top:6px"/>
</div>

### 4. How often do you upgrade your MySQL version, including 8.0 minor version upgrades?
The most popular frequency for upgrading MySQL version is once a year. Most people upgrade their MySQL version at least once every two years. 
<div style="width:500px">
<img src="/files/2024-08-27-vitess-user-survey/4-minor.png" alt="Vitess Project Booth" style="margin-top:6px"/>
</div>

### 5. Which version of MySQL are you running?
The most popular MySQL version among our respondents is 8.0, with a slightly higher proportion of users on Percona vs Oracle MySQL. 
<div style="width:500px">
<img src="/files/2024-08-27-vitess-user-survey/5-current-version.png" alt="Vitess Project Booth" style="margin-top:6px"/>
</div>

### 6. Which version of MySQL do you plan to upgrade to next?
More than half of users have responded with NA and TBD for their next MySQL version upgrade. Others are planning to upgrade to Percona 8.x and Oracle 8.x in the future. 
<div style="width:500px">
<img src="/files/2024-08-27-vitess-user-survey/6-next.png" alt="Vitess Project Booth" style="margin-top:6px"/>
</div>

### 7. How soon do you plan to upgrade to the next MySQL version?
A majority of our users plan to perform a MySQL version upgrade sometime in the next two years. 
<div style="width:500px;">
<img src="/files/2024-08-27-vitess-user-survey/7-soon.png" alt="Vitess Project Booth" style="margin-top:6px"/>
</div>

### 8. How do you deploy Vitess?
Users deploying Vitess on Kubernetes are in the majority, followed by bare metal, VMs, etc. Interestingly, some deployments use a mixed architecture.
<div style="width:500px;">
<img src="/files/2024-08-27-vitess-user-survey/8-deploy.png" alt="Vitess Project Booth" style="margin-top:6px"/>
</div>

### 9. How big is your data size?
A significant majority of Vitess deployments have a data size greater than 10 TB.
<div style="width:500px;">
<img src="/files/2024-08-27-vitess-user-survey/9-data.png" alt="Vitess Project Booth" style="margin-top:6px"/>
</div>

### 10. How big is your Vitess deployment in terms of keyspaces?
Most Vitess users have fewer than 100 keyspaces, but some have many more. 
<div style="width:500px;">
<img src="/files/2024-08-27-vitess-user-survey/10-keyspaces.png" alt="Vitess Project Booth" style="margin-top:6px"/>
</div>

### 11. How big is your Vitess deployment in terms of shards?
Most Vitess users have fewer than 100 shards, but a significant number of them have a high number of shards. 
<div style="width:500px;">
<img src="/files/2024-08-27-vitess-user-survey/11-shards.png" alt="Vitess Project Booth" style="margin-top:6px"/>
</div>

### 12. Have you run a resharding process?
A majority of the Vitess users have gone through a resharding process. 
<div style="width:500px;">
<img src="/files/2024-08-27-vitess-user-survey/12-resharding.png" alt="Vitess Project Booth" style="margin-top:6px"/>
</div>

### 13. Do you contribute code to Vitess?
50% of our respondents contribute code to Vitess. 
<div style="width:500px;">
<img src="/files/2024-08-27-vitess-user-survey/13-contribute.png" alt="Vitess Project Booth" style="margin-top:6px"/>
</div>

### 14. Cloud
50% of our users use Public cloud and most of them use GCP and Azure.
<div style="width:500px;">
<img src="/files/2024-08-27-vitess-user-survey/14-cloud.png" alt="Vitess Project Booth" style="margin-top:6px"/>
</div>

### 15. Which major version of Vitess are you running? 
23% of the users are running version 19.0 and other versions has a distributed split as seen in the graph below.
<div style="width:500px;">
<img src="/files/2024-08-27-vitess-user-survey/15-version.png" alt="Vitess Project Booth" style="margin-top:6px"/>
</div>

# Insights

### We asked our users how Vitess has helped their business. We got some interesting answers from different companies.

1. Scalability: Generally, it has scaled the performance of databases by horizontal sharding.
For eg. -
[How Shopify horizontally scaled the backend of an important Rails application.]("https://shopify.engineering/horizontally-scaling-the-rails-backend-of-shop-app-with-vitess")
 
2. Operational Efficiency: Vitess reduced the burden of managing MySQL clusters at scale, especially in distributed environments like Kubernetes.
3. High Availability: Hardware issues do not cause downtime while they are being repaired.
4. High Connections: Vitess is able to manage high connection counts and rates of churn, essential for highly trafficked and concurrent applications.
5. Efficient Online Schema Changes: Online DDL support in Vitess, combined with horizontal sharding, has let users efficiently change their schema, reducing operational workload for faster product iteration.
6. Lowered DevOps Burden: By abstracting away the complexities of sharding and scaling, Vitess empowers teams to concentrate on higher-level development rather than getting bogged down in database management.
7. Flexibility and stability: Vitess has brought stability even to unsharded setups by managing the connection limits and setting the number of concurrent threads so that databases run as smoothly as possible without any performance issues.

### We also asked them what the biggest missing feature in Vitess is. Here is a curated sample of the responses. 

1. Improved Observability: A consistent dashboard for observing the vreplication streams, with controls over schema changes, can give a better overview of operations.
2. Unified Web UI: A single, easy-to-use web interface for all administrative tasks would ease management and enhance usability.
3. Circuit Breaking and Adaptive Concurrency Limits: We need features to prevent clients from being blocked by slow shards, and manage concurrency.
4. More Clear Upgrade Path with LTS Versions: a well-defined upgrade path with LTS versions is important for stability and fewer bugs.
5. Auto Sharding Improvements: More advanced auto-sharding capabilities would be nice, such as in TiDB.
6. Vitess Keyspace History: Add a feature to track and review changes over time to a keyspace—such as reparents, backups, or scaling events for historical analysis and debugging.

# Conclusion
We appreciate all of you for your time to fill up the survey and share the inputs from your side. Your feedback has provided us with crucial findings that will guide our future efforts.

Thank you to all once again :)