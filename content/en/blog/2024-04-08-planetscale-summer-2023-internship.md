---
author: 'Arvind Murty'
date: 2024-04-08
slug: '2024-04-06-planetscale-summer-2023-internship'
tags: ['Vitess', 'PlanetScale', 'Golang', 'MySQL', 'Query Serving']
title: 'Planetscale Summer 2023 Internship'
description: "My experience working as an intern in the query serving team for PlanetScale"
---

My name is Arvind Murty, and from May to July of last year, I worked on Vitess via an internship with PlanetScale.

I was first introduced to Vitess a few years ago as a potential open-source project for me to work on. I had been interested in working on one because they’re a relatively easy way to get some real-world experience in large-scale software development. Vitess seemed like an good place to start, so I started contributing, mostly on internal cleanup. I had been doing this on and off until this spring, when Andrés Taylor approached me about doing an internship under his guidance. Needless to say, I agreed. 

## My Mission

When I started in mid-May, Andrés gave me my instructions: find as many bugs in the Vitess planner as possible.

We first looked into a tool called [SQLancer](https://github.com/sqlancer/sqlancer). From its README:

SQLancer (Synthesized Query Lancer) is a tool to automatically test Database Management Systems (DBMSs) in order to find logic bugs in their implementation. We refer to logic bugs as those bugs that cause the DBMS to fetch an incorrect result set (e.g., by omitting a record).

SQLancer had been very successful at finding bugs in well-established DBMSs, such as SQLite and MySQL, so we thought it might work well for Vitess. But there were three main problems:

* Vitess ideally should perfectly mimic MySQL, quirks included. SQLancer on the other hand compares queries to an oracle, which determines if queries are logically correct.
* Vitess has the added layer of the [VSchema](https://vitess.io/docs/19.0/reference/features/vschema/). The VSchema has many added considerations, such as sharding keys, which changes how Vitess plans the query.
* It would take a lot of work to properly integrate Vitess with SQLancer, due to each DBMS tester in SQLancer essentially being written completely separately with similar logic.

## Our Approach


We decided to go for the low-hanging fruit and build our own random query generator. Which turned out to not be that low-hanging since it yielded a bunch of failing queries. Andrés had already made a quick random query fuzzer that tested queries with aggregation, GROUP BY, ORDER BY, and LIMIT, so I started to build off of it in [this PR](https://github.com/vitessio/vitess/pull/13260). From a given set of tables, the fuzzer randomly selects a multiset of the tables, then chooses a random multiset of columns to provide to the clauses (SELECT, GROUP BY, WHERE etc.) and the random expression generator. Once the query is generated, it’s run on both Vitess and MySQL and the results and errors are compared. If there is a mismatch, it is reported.

Adding most types of queries was pretty straightforward (for example, for derived tables, generate a query q, then generate another query with q as a table), but there were two functionalities that were more complicated: random expressions and query simplification. Andrés had already built both of these, but for our purposes, they needed to be modified.

The [query simplifier](https://systay.github.io/2022/01/06/automatically-simplifying-queries.html) was a tool used to automatically simplify queries that produce errors. It uses a brute-force approach, removing or modifying nodes in the AST and checking if the new, simpler query still exhibits the same error. If it does, the simplifier is called on the new query. However, it was not originally intended to be used for end-to-end tests, so we had to figure out how to make it work—specifically, how to supply the VSchema information. After that, I made some minor improvements to the simplifier and refactored it in [this PR](https://github.com/vitessio/vitess/pull/13636).

The original random expression generator only generated random literal expressions, so the first step was to add columns. This was fairly simple for tables I knew the schema for, but became more complicated once I added derived tables and wanted to randomly choose columns from them.

The other improvement I made was to add aggregation to the expressions. Because aggregation can only exist in the SELECT statement or the GROUP BY, ORDER BY, and HAVING clauses, I had to make sure the generator only produced aggregations for the statements and clauses in which they are allowed.

## Conclusion

The fuzzer can always be improved, and I think the first step that should be taken is complicating or randomizing the schema and VSchema. All of the queries currently run on the widely-used EMP (employee) and DEPT (department) tables using a standard sharding based on EMPNO (employee number) and DEPTNO (department number), respectively. The other main improvement would be to clean up the code; currently, there is a flag `testFailingQueries` that prevents certain types of queries that were known to fail from being generated. With the query planner being improved since, this flag can either be deleted altogether, or at the very least be removed from many spots.

My experience at PlanetScale, while short, was instructive in more ways than one. Not only did I get to make some meaningful contributions, but I also learned how software development as a team works. For those two and a half months I was essentially a temporary member of the query serving team. And while I mainly worked with Andrés, I participated in the daily stand-ups and occasionally worked with the other members, for which I’d like to thank Harshit, Florent, and Manan. And of course thank you to Andrés for spearheading this project and mentoring me along the way.
