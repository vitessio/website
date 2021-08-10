---
title: Common Operational Issues
description: Frequently asked questions and commonly occurring problems while operating VReplication workflows.
weight: 400
---
{{< expand
`What mysql permissions are needed by VReplication`
"fas fa-angle-double-right" "fas fa-angle-double-up" >}}
<pre>
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, RELOAD, PROCESS, FILE, REFERENCES, INDEX, ALTER, SHOW DATABASES, CREATE TEMPORARY TABLES,
  LOCK TABLES, EXECUTE, REPLICATION SLAVE, REPLICATION CLIENT, CREATE VIEW,
  SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, CREATE USER, EVENT, TRIGGER
  ON *.* TO 'vt_filtered'@'localhost';
</pre>

{{< /expand >}}

{{< expand
`Why am I seeing io.EOF errors in my workflow`
"fas fa-angle-double-right" "fas fa-angle-double-up" >}}
<code>io.EOF</code> errors can be difficult to track down. These are usually caused by an issue at the mysql server. Here are some possible reasons
<ul>
<li>GTID is not enabled on the server. VReplication requires <code>GTID=on</code>
(<code>permissible</code> is <b>not</b> supported)</li>
<li>Permissions are not setup correctly for the vreplication mysql user</li>
<li>Row-based replication (RBR) <code>binlog_format=row</code> is not enabled. Statement-based replication (SBR) is <b>not</b> supported by VReplication</li>
<li>The mysql server is down or not reachable</li>
</ul>
{{< /expand >}}

{{< expand
`If I can't turn GTID on, can I run a VReplication workflow using FilePos instead?`
"fas fa-angle-double-right" "fas fa-angle-double-up" >}}
TBD
{{< /expand >}}
