---
author: 'Alkin Tezuysal'
date: 2021-01-26
slug: '2020-01-26-announcing-vitess-9'
tags: ['release','Vitess','MySQL','kubernetes','operator','cloud','GKE','sharding']
title: 'Announcing Vitess 9'
description: 'We are pleased to announce the general availability of Vitess 9. 
---
On behalf of the Vitess maintainers team, I am pleased to announce the general availability of [Vitess 9](https://github.com/vitessio/vitess/releases/tag/v9.0.0).

## Major Themes
In this release, we have focused on making Vitess more stable after the successful release of Version 8. There have been no major issues reported. So there were no patches released for Version 8. This has allowed us to push further on compatibility and adoption of common frameworks as priorities. We have compiled all improvements into the [Release Notes](https://github.com/vitessio/vitess/blob/master/doc/releasenotes/9_0_0_release_notes.md). Please read them carefully and report any issues via GitHub. We would like to highlight the following themes for this release:

### Compatibility (MySQL, frameworks)

Our ongoing work is to make sure that Vitess accepts all queries that MySQL does. We continually focus on SET and information_schema queries in this release as well as other common and complex queries. Several parts of the query serving module have been refactored to facilitate further compatibility enhancements. 

Please note that reserved connections are still not on by default, and you should plan to test it first in a test environment, to ensure that all your queries and frameworks are supported, before enabling it in production.

### Migration
Enhanced logging and metrics have been added to VReplication for helping to debug stalled and failing VReplication workflows and for increased visibility into other operational and performance-related issues.

VReplication support for JSON columns, which was previously incomplete, has been refactored and is now functionally complete.

A new version (v2) of the VReplication workflow CLI commands have been introduced. These incorporate functional and UX improvements based on user experience and feedback. These are deemed experimental (but fully functional) and we welcome feedback and suggestions on improving them further. 

### Innovation
There has been a significant push towards streamlining Online Schema Changes. 
* Changed syntax: The syntax for online DDL has been changed and finalized. We introduce the @@ddl_strategy session variable, or the -ddl_strategy command line flag to determine whether migration is executed normally (direct) or online (gh-ost or pt-osc). Further, migrations now use the standard ALTER TABLE syntax.
* Better auditing: A migration is now associated with a context as well as the identity of the issuing vttablet.
* Better managed: It’s possible to list migrations by context, to cancel all pending migrations. Vitess will automatically retry migrations that fail due to a failover.
* More statements: Online DDL now also works for CREATE and DROP statements. This allows us to group together migrations with the same context.
* Safe, lazy and managed DROPs: Online DDL DROP statements are converted to RENAME statements, which send the tables to the lifecycle mechanism: tables are held for safekeeping for a period of time, then slowly and safely purged and dropped, without risking database lockdown. A multi-table DROP statement is exploded into distinct single-table operations.

As always, please validate any new features in your test environments before using them in production.

### Documentation
Two new user guides have been created for new adopters of Vitess:

* [VSchema and Query Serving](https://deploy-preview-664--vitess.netlify.app/docs/user-guides/vschema-guide/)
* [Running Vitess in Production](https://deploy-preview-664--vitess.netlify.app/docs/user-guides/configuration-basic/)



There is a shortlist of incompatible changes in this release. We encourage you to spend a moment reading the release notes and see if any of these will affect you.

Please download [Vitess 9](https://github.com/vitessio/vitess/releases/tag/v9.0.0) and try it out!
