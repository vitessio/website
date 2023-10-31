---
author: 'Vitess Maintainer Team'
date: 2023-11-07
slug: '2023-11-07-announcing-vitess-18'
tags: ['release','Vitess','MySQL','kubernetes','operator','sharding', 'Orchestration', 'Failover', 'High-Availability']
title: 'Announcing Vitess 18'
description: "Vitess 18 is now Generally Available"
---

Vitess 18 is now Generally Available, with a number of new enhancements designed to improve usability, performance and MySQL compatibility.

# MySQL Compatibility Improvements

## Foreign Keys

In the past, foreign keys had to be managed outside Vitess. This was a significant blocker for adoption.
We are now able to support Vitess-managed foreign keys within the same shard. 
This includes the ability to import data into Vitess from an existing MySQL database with foreign keys. 
We plan to extend foreign key support to cross-shard relationships in the next release.

### General Compatibility

The Vitess query planner has been significantly enhanced, paving the way for advanced query capabilities. 
The newly revamped version is more robust and flexible. 
This allows Vitess to provide better support for complex aggregations, sophisticated subqueries, and derived tables. 
Complex queries on sharded databases will perform better as a result of these changes.

# Usability Enhancements

## Cobra

The Vitess CLI has been migrated to [cobra](https://github.com/spf13/cobra).
In addition to standardizing and modernizing our CLI infrastructure, this change provides two major benefits.

We now auto-generate reference documentation for both released and development versions of Vitess.

This means that developers spend less time performing mechanical documentation changes and 
more time on features, bug fixes, and more in-depth documentation, and end users get more reliably up-to-date 
reference docs.

In addition, Vitess commands now support shell completion:

![cobra-autocomp.gif](/files/2023-11-07-announcing-vitess-18/cobra-autocomp.gif)

## Vtctldclient

We have completed the migration of all client commands to vtctldclient. The legacy vtctl/vtctlclient binaries 
are now fully deprecated and we plan to remove them in Vitess 19.

This migration provides several benefits:
- Clean separation of commands makes it easier to develop new features without impacting other commands.
- It presents an API that other clients (both Vitess and 3rd-party) can use to interface with Vitess.
- It enables future features. For example, we can now use configuration files and start building support for dynamic configuration.

# VReplication and Online DDL

We now have the ability to import data with foreign key relationships, in such a way that we properly maintain those relationships.

Also, we now support near-zero downtime migration of data from an external database. 
Previously, there was a perceptible cutover duration during which queries would error out.
Online DDL can now provide better progress estimates.

# Point in Time Recoveries
While Vitess has supported Point in Time Recovery for years, the functionality was dependent on running a binlog server, and was not widely used. 
In this release, we add the ability to restore to a specific timestamp without relying on an external binlog server. 
Recovery to a known GTID position without a binlog server has been supported since Vitess 17.
The old functionality that relied on a binlog server is now deprecated, and will be removed in a future release.

# Tablet Throttler

The throttler now uses gRPC for communication with other tablets instead of http except as a fallback during version upgrades. 
The use of http was a security concern and it will be removed in the next release.

# Arewefastyet

Arewefastyet, our benchmarking system, now has a new look aimed at improving the reliability and usability of the website. 
We have also made several bug fixes and enhancements to the benchmarking system.

# Try It Out

We are very pleased with the great strides we have made with v18 and hope that you will be as well. 
We encourage all current users of Vitess and everyone who has been considering it to try this new release! 
We also look forward to your feedback, which can be provided via Vitess GitHub issues or the Vitess Slack.
