---
author: "Anthony Yeh"
published: 2016-03-10T11:13:00.001000-08:00
slug: "2016-03-10-percona-live-featured-talk-with-sugu-sougoumarane-vitess-the-complete-story"
tags: [ "conference",]
title: "Percona Live featured talk with Sugu Sougoumarane \u2013 Vitess: The Complete Story"
---
*Cross-posted from [Percona
Blog](https://www.percona.com/blog/2016/03/10/percona-live-featured-talk-with-sugu-sougoumarane-vitess-the-complete-story/).*  


Welcome to the next installment of our talks with [Percona Live Data Performance Conference 2016](https://www.percona.com/live/data-performance-conference-2016/) speakers! In this series of blogs, we’ll highlight some of the speakers that will be at this year’s conference, as well as discuss the technologies and outlooks of the speakers themselves. Make sure to read to the end to get a special Percona Live registration bonus!

In this installment, our Percona Live featured talk with Sugu Sougoumarane, Infrastructure & Storage Engineer at [YouTube](https://www.youtube.com/) is about [Vitess: The Complete Story](https://www.percona.com/live/data-performance-conference-2016/sessions/vitess-complete-story). I had a chance to speak with Sugu and learn a bit more about YouTube and
Vitess:

**Percona**: Give me a brief history of yourself: how you got into database development, where you work, what you love about it.

**Sugu**: My involvement with databases goes back to Informix in the 90s. This was during the 4GL and client-server days. I was part of the development team for a product called NewEra.

I later joined PayPal, where we used Oracle and eventually scaled it to the biggest machine money could buy. I have to say that I’m still a fan of the mighty hash join. During my time there, I wrote the system that balanced the books, which helped me gain some unique perspectives on consistency. Word on the street is that the tool is still in use.

These experiences at PayPal influenced the founders of YouTube to try a different approach: scaling with commodity hardware. When I joined YouTube, the only MySQL database we had was just beginning to run out of steam, and we boldly executed the first resharding in our lives. It took an entire night of master downtime, but we survived. These experiences eventually led to the birth of Vitess.

**Percona**: Your talk is going to be on “*Vitess*: The Complete Story.” How
has *Vitess* moved from a YouTube fix to a viable enterprise data
solution?

**Sugu**: This was around 2010. YouTube was growing, not only organically, but also internally. There were more engineers writing code that could potentially impair the database, and our tolerance for downtime was also decreasing. It was obvious that this combination was not sustainable. My colleague (Mike Solomon) and I agreed that we had to come up with something that would leap ahead of the curve instead of just fighting fires. When we finally built the initial feature list, it was obvious that we were addressing problems that are common to all growing organizations.

This led us to make the decision to develop this project as open source, which had a serendipitous payback: every feature that YouTube needed had to be implemented in a generic fashion. App-specific shortcuts were generally not allowed. We still develop every feature in open source first, which we would then import to make it work for YouTube.

Aside from our architectural and design philosophy, our collaboration with Kubernetes over the last two years means anyone can now run Vitess the way YouTube does: in a dynamically-scaled container cluster. We’ve had engineers dedicated to deployment and manageability on a public cloud, making the platform ready for general consumption.

**Percona**: Why move to a cloud-based storage solution anyway? What are the advantages and disadvantages?

**Sugu**: In general, a big advantage of cloud solutions is easy horizontal scalability – tuning capacity by simply dumping more commodity servers in the mix. For storage engines, the problem is that application complexity and operational overhead tend to scale up along with the number of database instances. A cloud-native storage solution like Vitess hides the complexity of horizontal scalability from both app developers and database operators. Thousands of servers can look like one to both dev and ops. With Kubernetes, Vitess even becomes agnostic to the underlying choice of cloud platform, providing cloud flexibility with no vendor lock-in.

**Percona**: What are the roadblocks cloud data becoming the default? What are the issues about cloud data storage that keep you up at night?

**Sugu**: Cloud technologies are beginning to coalesce around ideas like immutable
infrastructure and ephemeral, dynamically-scheduled workloads. Instead
of changing a server, you dynamically request a new one, and the old one
disappears. These ideas work great for stateless app servers but
represent unique challenges for storage engines. It turns out that many
of these challenges are ones we faced at YouTube as we moved Vitess from
private data centers into Google’s global container cluster. So we know
cloud-native data storage works at scale, but now we have to prove that
it works just as well on public cloud.

**Percona**: What are you most looking forward to at Percona Live Data Performance Conference 2016?

**Sugu**: I feel like I still don’t know MySQL well enough. I’m hoping to learn more
about its internals and new features. I’m also looking forward to
learning more about today’s data challenges that companies are facing,
and hear about the creative ways people are solving them.

Want to find out more about Sugu Sougoumarane, Vitess, and YouTube?
Subscribe to the [Vitess blog site](http://blog.vitess.io/), and check
out the [Vitess main page](http://vitess.io/).

To hear Sugu’s talk on [Vitess: The CompleteStory](https://www.percona.com/live/data-performance-conference-2016/sessions/vitess-complete-story), register for [Percona Live Data Performance Conference
2016](https://www.percona.com/live/data-performance-conference-2016/register).
Use the code “FeaturedTalk” and receive $100 off the current
registration price!

The [Percona Live Data Performance Conference](https://www.percona.com/live/data-performance-conference-2016/) is
the premier open source event for the data performance ecosystem. It is
the place to be for the open source community as well as businesses that
thrive in the MySQL, NoSQL, cloud, big data and Internet of Things (IoT)
marketplaces. Attendees include DBAs, sysadmins, developers, architects,
CTOs, CEOs, and vendors from around the world.

The Percona Live Data Performance Conference will be April 18-21 at the
Hyatt Regency Santa Clara & The Santa Clara Convention Center.
