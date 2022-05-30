---
author: 'Kushal Kumar'
date: 2022-06-01
slug: '2022-06-01-lfx-experience'
tags: ['Vitess','CNCF', 'LFX', 'parser','internship', 'golang', 'sql', 'yacc']
title: 'LFX Spring Term 2022 Experience'
description: "Experience working on Vitess as part of LFX internship" 
---

My name is Kushal Kumar and I was selected as a LFX mentee for the spring term 2022 under the organization CNCF:Vitess. It was a great learning experience. The 3 month journey was an exciting one where I got to learn about parsers, queries in sql and golang.

## How did I Land up at Vitess

I had heard about LFX mentorship program from one of my friends and applied last year in the fall term. However, I wasn't able to make it previously. This time, I was actively waiting for the mentorship to reopen. As soon as the portal opened, I looked for projects which suited me and to which I think I would be able to contribute and work with. There were 2 projects which interested me. One was ELISA and other was CNCF:Vitess. The fact that attracted me to Vitess was the project title: Sweet and simple. I read about the project description on the portal and decided to give a shot to Vitess. So, I looked at issue number 8604 which contained the detailed description on the tasks that were required to be done during the term. I looked at couple of PRs and my first reaction was: this is too difficult.😓(It was not XD). The main reason for thinking such was that each PR contained atleast 10-12 file changes. Most of these are generated automatically, but I wasn't aware of the fact that time. Additionally, the sql.go file contained 1000+ line changes, which terrified me. I thought of giving up at one stage but I am glad I didn't.

I decided that I atleast should study the PRs and see what exactly is done in the PRs. At first, I couldn't understand much but then there was a [PR](https://github.com/vitessio/vitess/pull/9352) which had commits structured into 4 different categories. Using that PR, I was able to completely grasp the understanding of how Vitess handles the parsing of SQL functions. These 4 categories are: structs, formatting, parsing and tests.

Now I had understanding of what needs to be done and a basic idea of how it is implemented. So I drafted a proposal for the same which can be found [here](https://docs.google.com/document/d/1ieiTXQx2WqIukU-SrVDrLiT598MUz02EAOWuKXMUfUo/edit?usp=sharing). I still was completely unaware of the parsers and had zero understanding on it. Though, I did some research on compilers and found about yacc and lex but I was not able to understand much about it.

I had already joined Vitess slack and the channel for lfx-spring in there. There were 5-6 more people who had applied for the project which made me quite nervous. My mentor, Manan Gupta asked me to have a discussion about the project. The call was expected to be around 30 minutes but suprisingly, it took more than a hour as we were discussing things about Vitess, I asked my doubts related to the project and Vitess, and then he gave me a walkthrough of the project. I was also told that I would be selected for the mentorship in the call itself. To add, Vitess has a monthly meeting planned at every 3rd week of thursday and so I also interacted with the community on the day. Since there were few days left before the start of the project, I went through some more PRs and read some portion of the book [Compilers: Principles, Techniques and Tools](https://en.wikipedia.org/wiki/Compilers:_Principles,_Techniques,_and_Tools) to have a more clear understanding.

## The journey

The aim of my project was to add the parsing support for MySQL functions. The description and work done related to the project can be found [here](https://github.com/vitessio/vitess/issues/8604). 

The first day of my work was on 1 March and it was a beautiful birthday gift for me. I got introduced to the team at [PlanetScale](https://planetscale.com), one of the leading commercial entities maintaining Vitess. There were weekly meeting scheduled (Mon-Fri) which were setup in the morning initially, but had some changes and were shifted to evenings (according to IST) in the latter part of the project. I was not able to attend all of the meetings due to college stuff, but my mentor had no problems with it. 

The first PR which I worked on was multi-index hint list. Details [here](https://github.com/vitessio/vitess/pull/9811). I was quite confident that I will be able to quickly resolve the issue as the change was not much but in the end, I was not able to do anything valuable at all in this PR and asked my mentor to guide me. He was quite comfortable and showed me how the changes are made. This helped me a lot and I then went ahead with the project. I created the PR for the lateral prepare statements, trim grammar function and lateral keyword before moving onto my first big PR.

This PR was related to parsing of JSON functions. These are supported in 8.0 and an issue regarding the parsing of similar can be found [here](https://github.com/vitessio/vitess/issues/4099). It was a big change, so the PRs were divided into different parts, where each part dealt with one aspect of JSON Functions as mentioned in [SQL docs](https://dev.mysql.com/doc/refman/8.0/en/json-functions.html). The different PRs related to JSON Functions took over a month to get merged into the codebase and it was already mid-term.

After merging of the JSON PRs, I worked on introducing the parsing support for partitions and subpartitions. At that time, the support was partial and my task was to fully support them. I was able to implement the parser changes and created the [PR](https://github.com/vitessio/vitess/pull/10127). This was followed by PR for [subpatition](https://github.com/vitessio/vitess/pull/10232.

In my last month, I worked on adding the parsing support for Window functions and Regex Expression functions in Vitess. These two PRs were big changes and took almost 20-25 days to complete. There were some discussions, the best option for a particular case and code changes. Finally, I was able to complete the PRs. At the time of writing the blog, the PRs are still open(waiting to be merged).

## Wrap Up

All things must come to an end and this was the end of my 3 month journey at Vitess(only as a LFX mentee). If I look back on my journey, I would clearly be able to see myself grow from a person having no knowledge of parsers and grammars, and only slight knowledge on go and sql to a person who can now understand the above topics and work with them.

What I liked most about my journey are the connections I made and experiences. Vitess community is the one of the best community which I have worked with. With the daily standup and the monthly meetings, I was able to interact with some of the best persons and learn a lot from them.

Ending here, I would like to thank few people without whom I don't think I would have been able to do much. The first and foremost is my mentor, Manan Gupta, who constantly helped me and clarified even my silliest of the doubts. I would also like to thank Harshit Gangal, Andres Taylor and Florent Poinsard who helped me with their valuable feedback for the PRs. In the end, thanks to Vitess community for trusting in me and providing me with this opportunity.

P.S: I have no intention of leaving Vitess anytime soon. 😉