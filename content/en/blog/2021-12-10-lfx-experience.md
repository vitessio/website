---
author: 'Ritwiz Sinha'
date: 2021-12-10
slug: '2021-12-10-lfx-experience'
tags: ['Vitess','CNCF', 'LFX', 'parser','internship']
title: 'LFX experience'
description: "Experience working on Vitess as part of LFX internship" 
---

I was a part of the [LFX Fall Intern program](https://www.cncf.io/blog/2021/08/16/cncf-lfx-projects-are-open-for-fall-2021-apply-by-august-22nd/) working on [Vitess](https://contribute.cncf.io/contributors/projects/#vitess) for 2021 and it was a great learning experience for me. I got introduced to Kubernetes in my previous internship through which I came to know about [CNCF](https://www.cncf.io) and then about the [LFX program](https://mentorship.lfx.linuxfoundation.org/#projects_all) (CNCF is part of the LinuxFoundation). Participating in LFX helped me develop my interest towards the internals of databases, query parsing and distributed systems, topics which I hope to explore in my final year. I tried contributing to and understanding other projects under CNCF like [Jaeger](https://contribute.cncf.io/contributors/projects/#jaeger), [OpenTelementry](https://contribute.cncf.io/contributors/projects/#opentelemetry) and core [Kubernetes](https://contribute.cncf.io/contributors/projects/#kubernetes) before I applied to be an LFX intern on Vitess. I couldn’t do any actual code contributions in those organizations, so I started to read up more about distributed systems, logging systems, managing large Go projects etc. which proved to be useful in this internship.

## The Application Process

After the projects were announced on the LFX GitHub [repo](https://github.com/cncf/mentoring/blob/main/lfx-mentorship/2021/03-Fall/README.md), I scanned through most of them and got an understanding of what each project was about.
The [CNCF project landscape](https://landscape.cncf.io) is vast, and as a newbie software developer, most of the project ideas proposed in LFX Mentorship 2021 made little sense to me. As the barrier to understanding projects and their proposals is high, I decided to go ahead and focus on one particular project which was Vitess. The docs for Vitess are good enough such that a person who has worked with at least relational databases would get an idea of what this project is about. Every project specific term is explained along with the project’s architecture which makes understanding the project's goals easier. I went through [the documentation](https://vitess.io/docs/) once, got an understanding of the project, set it up locally and ran the basic queries as specified in the documentation. Every LFX project has a dedicated mentor assigned, who acts as a guide through the duration of mentorship. So, after getting the project set up, I contacted the mentor for the projects to get an understanding of what exactly we were trying to achieve. We are allowed to apply to three projects, but with the amount of time we were given before the application, I was only able to study about one of the projects, which was to [Track MySQL Parser support in Vitess](https://github.com/vitessio/vitess/issues/8604).

The fun part about this project was that I had no idea whatsoever about how we were going to do what was intended in this project. I wrote up a bare bones [proposal](https://docs.google.com/document/d/1NQQznGXuzYFSQHwHUjgLSbI96D24DSuBWNd10rjGfZY/edit?usp=sharing) of whatever vague idea I had regarding the project and submitted it expecting not much to come out of it. Apparently the skill set required for this project had something to do with parsers, lexers and context free grammars, terms I was highly uneducated about at that time. I had a Formal Language and Automata course at college but like any other course at college, nothing came out of it (mostly my fault).

Surprisingly, I got an invite from the mentor, Manan Gupta for discussing more about this project where I got confirmation that I would be selected. We had time before starting out on September 1st, and he suggested that I study more about parsers and lexers and tools such as Yacc and Lex. I read up on the documentation for both the tools, tried making a simple JSON parser and lexer, watched some videos to get acquainted with the topic.

The best part of learning these was that I got to go through the book [Compilers: Principles, Techniques and Tools](https://en.wikipedia.org/wiki/Compilers:_Principles,_Techniques,_and_Tools). I have not yet completed the book but I sure hope to, now that I have quite a lot of free time in my winter vacations.


## The project and working period

My project involved improving the parser with many of the modern constructs of MySQL. Most of the work done can be seen in this [issue](https://github.com/vitessio/vitess/issues/8604). 

After starting as an LFX intern, I got introduced to the team at [PlanetScale](https://planetscale.com), one of the leading commercial entities maintaining Vitess. We had meetings scheduled daily in the morning to discuss what was to be done today and what we did yesterday for all team members. Although I could not attend most of the meetings due to having college class at the same time, my mentor was cool with it. 


My first issue included porting over all the test cases which were present in the MySQL repository and adding them to the parsing tests of Vitess so that we could get an idea about what was supported by our parser and what was not. I scraped all of the test files present on GitHub for MySQL server and added glue code in the Vitess codebase for adding them. I was quite new to Golang (Hello World type of new), thus Manan helped me a lot in writing those test case runners and getting that PR merged. 

After merging my first PR, we moved on to a more substantial change where we changed the entire select and union grammar of vitess so that we could pass some edge cases in queries comfortably without hacking into our grammar any more. This was quite a substantial change and it took me almost 15 days to get this merged.
After my second PR I got quite confident on what was to be done. All that theoretical knowledge about LR parsers, shift-reduce conflicts, reduce-reduce conflicts and solving them finally made sense when I actually encountered and solved them in some real software. 

After this PR, I worked till the end of the month on minor issues of adding support for small grammar constructs. I also had to take multiple breaks due to college exams. In October, I worked on changing the grammar of how our expressions were parsed. It solved many problems, some which we didn’t even set out to fix. Thanks to the tests imported in the beginning we got an idea of what was getting corrected gradually. 

Finally, in the month of November, I worked on getting another Pull Request merged which was abandoned by someone. It dealt with adding partitions support in the Parser and just needed some changes to be approved. 

## Wrap Up

This was the end of my 3 month long journey contributing to Vitess, and I can confidently say, this has been one of my best internship experiences so far, mainly because starting with no knowledge at all about parsing and grammars, it was a lot of fun to study about what was to be done and get those pull requests merged.

Apart from the contributed code, the best things were the new topics I found out about, like distributed database architecture, query optimization and query planning. I also got to attend one of the PlanetScale research paper discussion sessions where they condensed various research papers related to query optimization and decided how the additions might be useful to Vitess.

When I look back at all of my code contributions --  although many were perhaps not that significant -- I see how they helped me a lot to learn about databases themselves. With my second to last semester over winter break starting, I will be exploring more literature on query planning and optimization and looking at how Vitess does that. It will be a lot of fun.

