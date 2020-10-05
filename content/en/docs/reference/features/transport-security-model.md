---
title: Transport Security Model
aliases: ['/docs/user-guides/transport-security-model/','/docs/reference/transport-security-model/']
---

Vitess exposes a few gRPC services, and internally also uses RPCs. These RPCs
may optionally use secure transport options to use TLS over the gRPC HTTP/2
transport protocol. This document explains how to use these features. Finally,
we briefly cover how to secure the MySQL protocol transport to VTGate as well.

## Overview

The following diagram represents all the RPCs we use in a Vitess cluster via
gRPC:

![Vitess Transport Security Model Diagram](../../img/vitesstransportsecuritymodel.svg)

There are two main categories:

* Internal RPCs: they are used to connect Vitess components.
* Externally visible RPCs: they are use by the app to talk to Vitess. Note that
  not all Vitess users would use this gRPC interface, and rather use the MySQL
  protocol to VTGate, which we do not cover in this document.

A few features in the Vitess ecosystem depend on authentication, like Caller ID
and table ACLs. We'll explore the Caller ID feature first.

## Caller ID

Caller ID is a feature provided by the Vitess stack to identify the source
of queries. There are two different Caller IDs:

* Immediate Caller ID: It represents the secure client identity when it
  enters the Vitess side:
  - It is a single string, represents the user connecting to Vitess (vtgate).
  - It is authenticated by the transport layer used.
  - It is can be used by the Vitess TableACL feature.
* Effective Caller ID: It provides detailed information on who the individual
  caller process is:
  - It contains more information about the caller: principal, component,
    sub-component.
  - It is provided by the application layer.
  - It is not authenticated.
  - It is exposed in query logs to be able to debug the source of a slow query,
    for instance.

## gRPC Transport

### gRPC Encrypted Transport

When using gRPC transport, Vitess can use the usual TLS security features
(familiarity with TLS is necessary here):

* Any Vitess server can be configured to use TLS with the following command line parameters:
  - `grpc_cert`, `grpc_key`: server cert and key to use.
  - `grpc_ca` (optional): client cert chains to trust. If specified, the client
    must then use a certificate signed by one of the CA certs in the provided
    file.
* A Vitess go client can be configured with symmetrical parameters to enable
  TLS:
  - `xxxx_grpc_ca`: list of server cert signers to trust, i.e. the client will
    only connect to servers presenting a cert signed by one of the CAs in this
    file.
  - `xxxx_grpc_server_name`: common name of the server cert to trust, instead
    of the hostname used to connect, or IP SAN if using an IP to connect.
  - `xxxx_grpc_cert`, `xxxx_grpc_key`: client side cert and key to use (when
    the server requires client authentication)
* Other clients can take similar parameters, in various ways, see each client's
  parameters for more information.

With these options, it is possible to use TLS-secured connections for all parts
of the gRPC system. This enables the server side to authenticate the client,
and/or the client to authenticate the server.

Note this is not enabled by default, as usually the different Vitess servers
will run on a private network (in a Cloud environment, usually all local
traffic is already secured over between VMs, for instance).

### Certificates and Caller ID

Additionally, if a client uses a certificate to connect to Vitess (vtgate)
via gRPC, the common name of that certificate is passed to vttablet as the
Immediate Caller ID. It can then be used by table ACLs, to grant read, write
or admin access to individual tables. This should be used if different clients
should have different access to Vitess tables.

### Caller ID Override

In a private network, where TLS security is not required, it might still be
desirable to use table ACLs as a safety mechanism to prevent a user from
accessing sensitive data. The gRPC connector provides the `grpc_use_effective_callerid`
flag for this purpose: if specified when running vtgate, the Effective Caller
ID's principal is copied into the Immediate Caller ID, and then used throughout
the Vitess stack.

**Important**: this is not secure. Any user code can provide any value for
the Effective Caller ID's principal, and therefore access any data. This
is intended as a safety feature to make sure some applications do not
misbehave. Therefore, this flag is not enabled by default.

### Example
For a concrete example, see
[encrypted_transport_test.go](https://github.com/vitessio/vitess/blob/master/go/test/endtoend/encryption/encryptedtransport/encrypted_transport_test.go)
in the source tree. It first sets up all the certificates, and some table ACLs,
then uses the golang client to connect with TLS. It also exercises the
`grpc_use_effective_callerid` flag, by connecting without TLS.

## MySQL Transport to VTGate

To get VTGate to support TLS use the `-mysql_server_ssl_cert` and
`-mysql_server_ssl_key` VTGate options. To require client certificates,
you can set `-mysql_server_ssl_ca`, containing the CA certificate
you expect the client TLS certificates to be verify against.

Finally, if you want to require all VTGate clients to only be able to connect
using TLS, you can use the `-mysql_server_require_secure_transport` flag.
