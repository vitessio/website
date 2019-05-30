---
author: "Abhi Vaidyanatha"
date: 2019-05-29T09:07:21-08:00
slug: "2019-05-29-unsharded-vitess-benefits"
tags: ['Guides', 'Unsharded', 'Benefits']
title: "The Benefits of Unsharded Vitess"
---

For many large companies seeking help with horizontal scaling, Vitess' value proposition is easily understood; running stateful workloads at astronomical scale is a hard problem that Vitess has boldly solved in the past. However, for small/emerging businesses, it may seem difficult to justify placing complex middleware in your data path with no immediate reward. I'm here to show you why unsharded Vitess is not just a pre-optimization - it provides many upgrades to the MySQL experience.

### Query Optimization
