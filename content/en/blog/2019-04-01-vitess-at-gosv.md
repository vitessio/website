---
author: "Adrianna Tan"
published: 2019-04-01T07:15:00-07:00
slug: "2019-04-01-vitess-at-gosv"
tags: ['events']
title: "Vitess at GoSV"
---

When Vitess started at YouTube back in 2010, it was designed to work in Google’s Borg. As a result of that interesting bit of history (and the Google origin story), Vitess wound up being one of the earliest adopters of (a) Go and (b) Kubernetes.

At last week’s GoSV meetup (organized by the indefatigable [Aarti](https://twitter.com/classyhacker) and [Conrad](https://twitter.com/conradwt); [join their meetup](https://www.meetup.com/Go-Silicon-Valley/) to get the latest updates on other Go events in Silicon Valley), Vitess co-creator Sugu Sougoumarane shared background stories about Vitess’ origin story, why Go was selected, and how the teams working on Vitess and Go overlapped during their time at Google.

Some highlights from the talk:

* Vitess was cloud native from the start (because of how it was designed to run in Borg). Vitess was ready for Kubernetes before 1.0

* Stateful workloads not generally recommended in Kubernetes (as [this Twitter discussion](https://twitter.com/kelseyhightower/status/1109714010369200129) brings up), but Sugu made a point about Vitess's stateless vtgate component making changes quickly available; Vitess is used statefully in production traffic in Kubernetes environments by several companies 

He also demonstrated VReplication, an upcoming Vitess feature that will benefit anyone who needs materialized views and rollups.

Here’s a [deck](../../files/2019-vitess-gosv.pdf) for you to find out more. 

For a VReplication demo with audio and a transcript, check out [Sugu’s talk at QCon San Francisco 2018](https://www.infoq.com/presentations/vitess) (scroll through to the ‘demo’ section). 

For questions about VReplication and how it works, feel free to join the [Vitess community](https://vitess.slack.com) (click [here](https://join.slack.com/t/vitess/shared_invite/enQtMzIxMDMyMzA0NzA1LTYxMjk2M2M2NjAwNGY0ODljY2E1MjBlZjRkMmZmNDVkZTBhNDUxNzNkOGM4YmEzNWEwOTE2NjJiY2QyZjZjYTE) to join).
