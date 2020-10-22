---
author: 'Alkin Tezuysal'
date: 2020-10-27
slug: '2020-10-27-announcing-vitess-8'
tags: ['release']
title: 'Announcing Vitess 8'
---
On behalf of the Vitess maintainers’ team, I am pleased to announce the general availability of [Vitess 8](https://github.com/vitessio/vitess/releases/tag/v8.0.0).

## Major Themes
In this release, we have continued to make important improvements to the Vitess project with over 200 PRs in several areas. Some of the major bug fixes and changes in behaviors are documented in the Release Notes. Please read them carefully and report any issues via GitHub. We would like to highlight the following themes for this release. 
Compatibility (MySQL, frameworks)

Our ongoing work to make sure that Vitess accepts all queries that MySQL accepts. In particular, work has focused on SET and information_schema queries. Reserved connections are still not on by default, and you might need to enable it to see all queries and frameworks well supported.

We are proud to announce that we have initial support for:
* Wordpress
* MySQL Workbench
* SQLAlchemy
* Mycli
* Gorm
* Ruby on Rails - ActiveRecord
* JVM - JDBC and Hibernate
* Django 
* Javascript-land -  TypeORM and Sequelize
* PyMySQL
* Rust MySQL

### Migration
Performance and error metrics and improved logging related to VReplication workflows have been added for more visibility into operational issues. Additional vtctld commands VExec and Workflow allow easier inspection and manipulation of VReplication streams. 

The VStream API was enhanced to provide more information for integration with change data capture platforms: the Debezium Vitess adapter uses this capability.

We have incorporated several small feature enhancements and bug-fixes based on the increased traction that VReplication saw both among early adopters and large production setups.

## Usability 
Ease of usability and accessibility are very important for the Vitess community. Usability improvements were another highlight received from the community. 

## Innovation
We continue to add integration of popular open-source tools and utilities on top of the Vitess’s dynamic framework. There are a few of these in this release we would like to highlight. 

* VTorc : Integration of Orchestrator has continued and finally became part of Vitess. This proven open-source tool which has been the de-facto solution for MySQL failover mechanisms is now built into Vitess. Support is experimental in 8.0 and we will continue to harden it in future releases.
* [Online Schema Changes](https://vitess.io/docs/user-guides/schema-changes/): Understanding the ALTER TABLE problem and coming up with a solution using proven tools was our goal to achieve this release. We’re able to integrate both pt-online-schema-change and gh-ost to overcome major limitations for schema migrations. 

There is a shortlist of incompatible changes in this release. We encourage you to spend a moment reading the release notes.

Please download [Vitess 8](https://github.com/vitessio/vitess/releases/tag/v8.0.0) and try it out!

