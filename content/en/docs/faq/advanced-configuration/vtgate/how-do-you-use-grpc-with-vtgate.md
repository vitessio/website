---
title: "How do you use gRPC with VTGate?"
shorten_nav_links: true
notoc: true
weight: 2
---

To do this you will need to use the Vitess MySQL Go client. We have a [Golang compatible gRPC driver](https://pkg.go.dev/vitess.io/vitess/go/vt/vitessdriver) and a [Java driver](https://github.com/vitessio/vitess/tree/master/java).

Once you have the appropriate driver you will need to add the `--service_map grpc-vtgateservice` VTGate flag and set the port `--grpc_port`.

This runs on a standard gRPC interface, so if you want to directly use it you can follow the example below:

```sh
#!/usr/bin/env node
import Debug from "debug";
import * as grpc from "grpc";
import {CallerID} from './proto/vitess/vtrpc_pb';
import {BoundQuery} from './proto/vitess/query_pb';
import {Session,ExecuteRequest,ExecuteResponse} from './proto/vitess/vtgate_pb';
import {VitessClient} from  './proto/vitess/vtgateservice_grpc_pb';
const log = Debug("VtgateClient");
const client = new VitessClient("139.178.90.99:15306",grpc.credentials.createInsecure());
const SingleQuery = async () => {
   return new Promise((resolve,reject) => {
       const caller = new CallerID();
       caller.setPrincipal("nodejs");
       const session = new Session();
       session.setTargetString("main");
       const query = new BoundQuery();
       query.setSql("SELECT * from main.sbtest1 where id=10");
       const request = new ExecuteRequest()
       request.setSession(session);
       request.setQuery(query);
       request.setCallerId(caller);
       client.execute(request, (err: grpc.ServiceError | null, response: ExecuteResponse ) => {
           if( err != null ){
               console.log(`[SingleQuery] Error: ${err.message}`)
               reject(err); return;
           }
           console.log(`[SingleQuery] Response: ${JSON.stringify(response.toObject())}`)
           resolve(response);
       });
   });
}
async function main() {
   client.
   console.log(`[main] Starting`);
   await SingleQuery();
}
main().then((_) => _);
```
