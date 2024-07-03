---
title: VReplication FAQ
description: Common issues/questions while operating VReplication workflows.
weight: 400
---

{{< expand `What mysql permissions are needed by VReplication?`>}}
<pre>
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, RELOAD, PROCESS, FILE, 
  REFERENCES, INDEX, ALTER, SHOW DATABASES, CREATE TEMPORARY TABLES,
  LOCK TABLES, EXECUTE, REPLICATION SLAVE, REPLICATION CLIENT, CREATE VIEW,
  SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, CREATE USER, EVENT, TRIGGER
  ON *.* TO 'vt_filtered'@'localhost';
</pre>
{{< /expand >}}

{{< expand `Why am I seeing io.EOF errors in my workflow?`>}}
<p>
  <code>io.EOF</code> errors can be difficult to track down. These are usually caused by an issue at the mysql server layer. You will need to consult
  the source and target vttablet logs in order to know for sure in each case. Here are some possible reasons:
</p>

<ul>
  <li>GTID is not enabled on the server. VReplication requires <code>GTID=on</code>
  (<code>permissible</code> is <b>not</b> supported)</li>
  <li>Permissions are not setup correctly for the vreplication related mysql users (in particular the `vt_filtered` user by defualt).</li>
  <li>Row-based replication (RBR) <code>binlog_format=row</code> is not enabled. Statement-based replication (SBR) is <b>not</b> supported by VReplication</li>
  <li>The mysql server is down or not reachable</li>
</ul>
{{< /expand >}}

{{< expand `What GTID-related options do I need to set in my my.cnf?`>}}
<pre>
log_bin=1
binlog_format=ROW
binlog_row_image=full
</pre>
{{< /expand >}}

{{< expand `If I can't turn GTIDs on, can I run a VReplication workflow using --db_flavor=FilePos instead?`>}}
Yes, you can run VReplication workflows with the pre MySQL 5.6 file and position method but this should only be used as a last resort when it's not possible
to modify the configuration of the source. This is because the File and Position method is not fault tolerant and if any error or failure/failover is encountered
you will need to throw away the existing workflow and start another one anew.
{{< /expand >}}
