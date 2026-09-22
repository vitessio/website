---
title: vtctld
---

**vtctld** is the Vitess cluster-management server. It serves `vtctldclient` connections through the `VtctldServer` gRPC API. VTAdmin reaches vtctld over the same API.

[VTAdmin](../vtadmin) replaced the vtctld web UI. Use it to browse the [Topology Service](../topology-service) or get a high-level overview of the servers and their current states.

vtctld also exposes the `/debug/health` and `/debug/status` HTTP endpoints.
