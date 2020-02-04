---
author: "Abhi Vaidyanatha"
date: 2020-01-14T09:09:21-08:00
slug: "2020-01-14-vitess-graduation-retrospective"
tags: ['graduation', 'vitess graduation']
title: "Vitess Graduation Retrospective"
---

Last November, Vitess became the eighth CNCF project to reach graduation, joining a host of amazing projects such as Kubernetes, Prometheus, Envoy, CoreDNS, containerd, Fluentd, and Jaeger. To contextualize this milestone, I picked some tidbits from the brain of Vitess co-creator, Sugu Sougoumarane, allowing him to share internal perspective about how we got here, the hurdles we faced, and where we’re headed.

### Incubation

Considering that it was only the February of 2018 when the CNCF agreed to host Vitess as an incubating project, Vitess has made efficient strides toward becoming the de-facto standard for horizontally scaling MySQL. Beyond horizontal scale, however, our main goal for Vitess on its acceptance to the CNCF was to spearhead the ability to run databases in Kubernetes. We're very excited at the progress we’ve made as a community and these juxtaposed quotes from Slack principal engineer, Michael Demmer, show the evolution of the project firsthand:

| Michael Demmer on Vitess incubation (2/5/2018) | Michael Demmer on Vitess graduation (11/5/2019) |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| “Slack is in the midst of a major migration of the MySQL infrastructure at the core of our service, driven by the need for an architecture that scales to meet the growing demands of our largest customers and features under the pressure to maintain a stable and performant service that executes billions of MySQL transactions per hour, said Michael Demmer, Senior Staff Engineer at Slack. “We needed a solution that would offer a familiar full featured SQL interface, and wanted to continue to use MySQL as the backing store to maintain our operations knowledge and comfort level. Vitess is a natural choice for this purpose and has served us well so far.” | “Vitess has been a clear success for Slack,” said Michael Demmer, principal engineer at Slack. “The project has both been more complicated and harder to do than anybody could have forecast, but at the same time, Vitess has performed in its promised role a lot better than people had hoped for. Our goal is that all MySQL at Slack is run behind Vitess. There’s no other bet we’re making in terms of storage in the foreseeable future.” |

### Post-Incubation

After beginning incubation, there was some speculation around whether Vitess would keep up with the rigorous requirements of the open source community in the areas of security and continuous integration. Sugu, however, wasn’t so scared:
 
> Given that Vitess is being continuously used in security-sensitive production environments like YouTube, Square’s Cash App, and Slack, it wasn’t a surprise that no material vulnerabilities were found. Another area of high scrutiny was related to diversity of employers among contributors. This wasn’t a challenge either; Vitess adopters deeply care about the project and have been continuously investing time and effort. We now have 14 active maintainers from many different companies.

### Preparing for Graduation

With the continued support of our open source maintainers and contributors, it slowly became obvious that Vitess had naturally reached the graduation requirements without directly trying. Sugu’s confidence continued into this period, as he believed that graduation was mostly a formality at this point. While many shared his confidence, the graduation process had changed since the last graduating project. 

The formal process starts with a Pull Request on the TOC repository with answers to the Graduation Criteria. As mentioned before, the incubation criteria had evolved since February 2018 (and in some respects, some of the incubation criteria are harder to meet). To accommodate for this, we included answers for both versions of the criteria. After our requirements were verified, we were given a date to present to the TOC. Even after verification, we had one more test to pass; a due diligence checkup from a TOC member. 

### Due Diligence 

While getting past this stage is [no easy feat](https://docs.google.com/document/d/1TDlRdgfTiEWunpav-G8gkaQF7Zk84-9tNAXyv1I0Kws/edit?ts=5da8eafc#heading=h.nu2qbsaqadff), the review came down to four things: quality, adoption, contribution, and support. While adoption, contribution, and community support came down to statistics, displaying quality proved to be slightly harder. 

We started with an outline of common questions we assumed that individuals would like to know about a database project, but it came down to these two: how do you test it, and how do you ensure performance? The reviewer, rightfully so, asked for clearer answers on this, making us expound on the ways that Vitess compares to other technologies that occupy a similar role. Additionally, we were more than happy to dive into details about adoption, maintainership, and the design process for new features with our reviewer, who was interested in all of these things and more. Above all else, Sugu seemed to be focused on appreciating the review:

> It was all good feedback. I think this will be an interesting line in the sand to see where Vitess is as we continue development moving forward.

### Where Are We Now?

| Vitess Project Stats (2/5/2018) | Vitess Project Stats (11/5/2019) |
|----------------------------------------------------------------------------------|-----------------------------------------------------------------------------------|
| <ul><li>105 contributors</li><li>5413 GitHub stars</li><li>15 releases</li><li>13733 commits</li><li>707 forks</li></ul> | <ul><li>187 contributors</li><li>8961 GitHub stars</li><li>24 releases</li><li>17428 commits</li><li>1179 forks</li></ul> |

From both the bustling community and the development of the project, it’s fairly clear that Vitess is continuing to gain momentum. The number of Vitess adopters and people running on Kubernetes is on the rise, a correlation that we predict will remain positive. Vitess is now is a pioneer in showing that one can indeed run stateful workloads in Kubernetes, a statement that many are quick to dismiss. With major companies committing to fully migrating to Vitess, it has emerged as one of the most trusted storage solutions in the cloud native space. 

#### *If you’re moving to Kubernetes, don’t leave your data behind.*

### Where Are We Going?

While our feature offering has continued to serve the public well, we are aware that getting on board with the product is not as straightforward as we’d like it to be. One of our principal focuses going forward is making Vitess more and more approachable. On this topic, Sugu is hopeful for the future:

> Bringing up a Vitess cluster shouldn’t be hard, and we’re going to make it extremely easy to do so. At the same time, making the migration path simpler for our users that want a drop-in replacement for MySQL will be pivotal to accelerating adoption.

If you are interested in joining the ever-growing force of Vitess contributors, make sure to check out our [community Slack](https://vitess.io/slack) to get started!
