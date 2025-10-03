---
title: Get Started
description: Quick Setup - Install, configure, and try Vitess
weight: 2
aliases: ['/docs/tutorials/']
---

Vitess is a database clustering system for MySQL. It provides horizontal scaling, resilience, and query routing while preserving MySQL semantics. See: [Overview](../overview/whatisvitess)

This page outlines a beginner friendly quick guide to **evaluate** Vitess. It describes how to install a small test environment. So you can explore Vitess’s core features and get comfortable with its architecture or start building against it.

## Who this is for

* **Evaluators** who want a low‑effort try‑out system.
* **Administrators** who prefer to learn the basics before planning a production install.
* **Developers** who need a disposable test environment to build against.

---

## Install for testing

Pick one of the lightweight test options:

* **Local Install (Linux)** — precompiled binaries and local example scripts  
  [./local/](./local/)
* **Local Install via source for macOS** — build from source, then run the local examples  
  [./local-mac/](./local-mac/)
* **Vttestserver Docker Image** — single‑container test instance (fastest path & **recommended**)  
  [./vttestserver-docker-image/](./vttestserver-docker-image/)

**Advanced (closer to production):** If you want to exercise more components or practice ops tasks, use the **Vitess Operator for Kubernetes** in a local or dev cluster. It’s more involved and mirrors production patterns.  
[./operator/](./operator/)

> We recommend that to read the overview Docs first like Architecture Overview to understand the components you are installing: [../overview/architecture/](../overview/architecture/)

### Schema & VSchema (use the demo)

To explore schemas and VSchema quickly, use the **VSchema demo**. It runs a single‑process **vtcombo** instance that behaves like a full cluster for learning.

* **Run the demo**, see: [../user-guides/vschema-guide/overview/#demo](../user-guides/vschema-guide/overview/#demo)

  * `go run demo.go`
  * Open **[http://localhost:8000](http://localhost:8000)** to view tables, run queries, and see effects.
  * Or connect with a MySQL client: `mysql -h 127.0.0.1 -P 12348`.
  * The demo focuses on VSchema concepts similar to Getting Started, but with more detail.
    See: *VSchema Overview → Demo*.

* **Iterate on the schema**

  * Start with the demo’s baseline schema/VSchema.
  * Empty the files under `schema/product` and `schema/customer`, then add definitions step by step to mirror the guide’s examples.
  * Use VSchema DDL where applicable, or apply JSON directly if you prefer. (Knowing the JSON format helps with troubleshooting.)

> Tip: The demo is great for trying sharded vs. unsharded keyspaces and understanding how VTGate routes queries based on VSchema.

### Alternative: your chosen test setup

If you used **Local Install**, **Local (macOS source)**, or **vttestserver**, apply your schema and VSchema in that environment and connect your app through **VTGate** using your normal MySQL driver.

Use the examples provided in the respective test guide to apply schema and VSchema.

## Test

* Connect to **VTGate** and run simple reads/writes to verify connectivity.
* In the **VSchema demo**, use the web UI at `http://localhost:8000` to inspect tables and issue queries; observe how VSchema affects routing.
* (Optional) Try safe demo operations in a test setup (e.g., MoveTables, tiny reshard, planned failover) only if your chosen guide includes them.

---

## What’s next: roadmap to move to production

After you’ve completed the quick start, follow this linear roadmap to build and operate a production Vitess cluster:

1. Plan production installation — capacity, topology, cells, prerequisites  
   [Planning](../user-guides/configuration-basic/planning/)

2. Install & wire up the cluster — (Kubernetes is recommended; use the [Vitess Operator](./operator/) or your automation)  
   * [Create a cell](../user-guides/configuration-basic/create-cell/)
   * [Keyspaces & shards](../user-guides/configuration-basic/keyspaces-shards/)
   * [VTGate](../user-guides/configuration-basic/vtgate/)

3. Configure the production environment — durability, backups, monitoring  
   * [Backups & restores](../user-guides/configuration-basic/backups-restores/)
   * [Monitoring](../user-guides/configuration-basic/monitoring/)
   * [Troubleshooting](../user-guides/configuration-basic/troubleshooting/)

4. Populate databases — migrate existing MySQL data with VReplication or dump/restore  
   [Migrating data](../user-guides/migration/migrate-data/)

5. Run queries & evolve schemas — connect apps, manage changes safely  
   * [VSchema overview](../user-guides/vschema-guide/overview/)
   * [Managed, Online Schema Changes](../user-guides/schema-changes/managed-online-schema-changes/)

6. Operate & scale — shard and maintain your cluster over time  
   * [Reshard (VReplication)](../reference/vreplication/reshard/)
   * [Reparenting](../user-guides/configuration-advanced/reparenting/)
   * [VTOrc](../reference/programs/vtorc/)

> Role hints: **Developers** start with VSchema & Query Serving (step 5). **DBAs/Operators** prioritize backups/monitoring (step 3). **SREs** focus on VTOrc and reparenting (step 6).
