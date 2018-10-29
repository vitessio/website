+++
author = "Sugu Sougoumarane"
published = 2017-04-25T15:59:00.002000-07:00
slug = "2017-04-25-vitess-releases-version-2-1"
tags = []
title = "Vitess releases version 2.1"
+++
<span style="font-family: arial, helvetica, sans-serif;">The Vitess
project is proud to announce the release of version 2.1. This version
comes packed with new features that improve usability, availability and
resilience of the overall system.</span>

<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">  
</span><span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">The
release coincides with the [Percona Live 2017
Conference](https://www.percona.com/live/17/), where project co-founder
Sugu Sougoumarane will give the talk "[Vitess beyond
YouTube](https://www.percona.com/live/17/sessions/vitess-beyond-youtube)".
He is joined by Robert Navarro from Stitch Labs  who is going to
describe how Stitch Labs uses Vitess in production..</span>  
<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">  
</span><span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">Version
2.0 introduced a sharding agnostic API to the world. This allowed
clients to connect to Vitess and send queries as if it was a single
database engine. However, questions remained about the atomicity of
transactions that spanned multiple shards or keyspaces. With 2.1, you
can now request such transactions go through the Two-Phase Commit (2PC)
protocol that gives you all-or-none cross-database commits.</span>  
<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">  
</span><span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">Another
noteworthy new feature is the support for the native MySQL protocol.
This allows users to trivially repoint their application to a Vitess
instance without any code modifications. Over the next few months, this
protocol will be solidified and made a first class citizen of the Vitess
API.</span>  
<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">  
</span><span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">We
would like to thank our community for their contributions. Several
companies have adopted Vitess, provided extensive feedback and submitted
major code changes. For example, Hubspot extended the SQL parser and
BetterCloud added TLS support in the JDBC driver.</span>  
<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">  
</span><span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">The
full list of new features in 2.1 and upgrade instructions can be found
in the [release
notes](https://github.com/youtube/vitess/releases/tag/v2.1.0).</span>  

#### <span style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">About Vitess</span>

<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">Vitess
strives to be be the best performing, scalable and most available NewSQL
storage solution in the Cloud based on MySQL. It has been
battle-hardened by serving YouTube’s video metadata traffic for over six
years now. Since its inception it was developed as an open-source
project, and has a growing community of users and contributors.</span>  

#### <span style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">About Percona Live</span>

<span
style="font-family: &quot;arial&quot; , &quot;helvetica&quot; , sans-serif;">The
Percona Live Open Source Database Conference 2017 is the premier event
for the diverse and active open source database community, as well as
businesses that develop and use open source database software. The
conferences have a technical focus with an emphasis on the core topics
of MySQL, MongoDB, PostgreSQL and other open source databases. Tackling
subjects such as analytics, architecture and design, security,
operations, scalability and performance, Percona Live provides in-depth
discussions for your high-availability, IoT, cloud, big data and other
changing business needs.</span>
