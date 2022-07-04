---
author: 'Shlomi Noach'
date: 2022-07-15
slug: '2022-07-15-schemadiff'
tags: ['Vitess','MySQL', 'DDL', 'schema']
title: 'schemadiff: a declarative library to diff, validate, and manipulate schemas'
description: 'Introducing schemadiff, a best kept secret library available in Vitess v14'
---

One of the interesting developments found in Vitess release v14 is an internal library called `schemadiff`, a best kept secret. At its core, `schemadiff` is a declarative library that can produce an SQL diff of entities: two tables, two views, or two full blown database schemas. But it then goes beyond that to normalize, validate, export, and even _apply_ schema changes, all declaratively and without use of a MySQL server. Let's dive in to understand its functionality and capabilities.

## Schemas, entities and diffs


