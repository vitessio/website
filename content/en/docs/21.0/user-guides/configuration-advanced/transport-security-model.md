---
title: Securing Vitess Using TLS
weight: 60
---

## Introduction

Vitess has a number of different components that, in most real-world configurations, connect to each other over the network. Many organizations require, for compliance or practical reasons, that these communications
be encrypted and/or authenticated. This guide will provide an overview of these client/server combinations between components, what the encryption and authentication options are, and a walkthrough on how to configure Vitess to use them. You can read more about our [transport security model](../../../reference/features/transport-security-model/) in our references. 

There are two paths a data path and a control path that could be secured. The focus in the guide will be to secure the data path. You can read more about the two paths [here](../../configuration-basic/ports/).

Note that the sensitive information mainly flows over the data path, and depending on your deployment model, you may not have to encrypt all of the the control or meta-data path.  We recommend that you evaluate your needs in the context of your compliance directives, threat model and risk management framework.

It should also be noted that while Vitess provides the mechanism for securing these communication channels, it does **not** manage the certificate management tasks like:
 
  * Securely generating private keys
  * Issuing server certificates
  * Issuing, if necessary, client certificates
  * Certificate rotation
  * Certificate audit

Indeed, the hardest part of deploying TLS with Vitess in a large organization may be to integrate with whatever certificate policies and procedures the organization mandates. It should be noted that the manual issuing and rotation of certificates in a Vitess environment of a non-trivial size is impractical, and some provisioning and configuration management automation will need to be built.

## Protocols Involved

Of all the data, meta-data and control paths enumerated above, they use one of three protocols:

  * MySQL binary protocol
  * gRPC (using HTTP/2 as transport)
  * HTTP

## Encryption

All three the protocol types above use TLS in one form or another to encrypt communications. Therefore the basics around encrypting a specific client to server communication is straightforward:

  * Server-side:
    * Generate a CA private key and cert as the root for your certificate
      hierarchy.
    * (optionally) Generate intermediate keys to serve as signing
      keys for your server certificates.  We will not cover this case in
      this document.
    * Generate a private key for the server component involved.
    * Generate a CSR using the private key.
    * Use the CA key material and the CSR to generate/sign the server
      certificate.
    * Install the server cert and private key using the appropriate Vitess
      options for the component in question.
    * If required, adjust other Vitess component options to enforce/require
      TLS-only communications.

## Server Authentication

In addition to encrypting the connection, you may want or need to configure client-side server authentication.  This is the process by which the client verifies that the server it is trying to establish a TLS connection to is who they claim to be, and not an imposter or man-in-the-middle.  We achieve this by:

  * Client-side:
    * Install the CA cert used by your certificate issuing process to sign the server component certificates.
    * Adjust the Vitess client component options to verify the server certificate using the installed CA cert.  This would typically involve specifying the CA cert, as well as the server or common name to expect from the server component, if it isn't the same as the DNS name (or has an IP SAN configured).

## Client Authentication

Client authentication in Vitess can take two forms, depending on the protocol in question:

  * TLS client certificate authentication (also known as mTLS)
  * Username/password authentication;  this is only an option for the connections involving the MySQL protocol.

## Walkthroughs

We will now cover how to setup the various TLS component combinations. We will start with the data path, then move on to the control paths. We will handle [encryption](#encryption) and [server authentication](#server-authentication) together, and then handle [client authentication](#client-authentication) separately.

### Certificate Generation

As discussed above, large organizations will often have established tools to secure a TLS certificate hierarchy and issue certificates. For the purpose of these walkthroughs, we could use bare `openssl` commands to step through every detail. However, since we consider this an implementation detail that is likely to vary from user to user, we will leverage a shell-script-based tool called [easy-rsa](https://github.com/OpenVPN/easy-rsa) that uses `openssl` under the covers, and hides much of the complexity.

This tool has been around for many years as part of the OpenVPN project, and can perform all the steps to setup a CA, generate server certificates and also client certificates if desired. Since `easy-rsa` is just a set of shell scripts, if you require a closer understanding of how every step works, this is easy to discover as well.  Lastly, `easy-rsa` can be used in production, and can easily manage thousands of certificates, if desired.

We will use the newest `easy-rsa` release at the time of writing, version 3.0.8.

### Installing easy-rsa

Create a directory to install and run `easy-rsa` from, download and unpack the tool:

  ```bash
  $ echo $HOME
  /home/user
  $ mkdir ~/CA
  $ cd ~/CA/
  $ wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz
  .
  .
  2020-10-02 16:10:22 (604 KB/s) - ‘EasyRSA-3.0.8.tgz’ saved [48907/48907]
  $ tar zxf EasyRSA-3.0.8.tgz 
  $ mv EasyRSA-3.0.8/easyrsa .
  $ mv EasyRSA-3.0.8/openssl-easyrsa.cnf .
  $ mv EasyRSA-3.0.8/x509-types .
  $ mv EasyRSA-3.0.8/vars.example vars
  $ rm -rf EasyRSA-3.0.8
  ```

Edit the `vars` file appropriately for your setup. For the purposes of this walkthrough we will just append the following lines at the end of the file. Please adjust for your needs:

  ```
  set_var EASYRSA_DN             "org"
  set_var EASYRSA_REQ_COUNTRY    "US"
  set_var EASYRSA_REQ_PROVINCE   "California"
  set_var EASYRSA_REQ_CITY       "Mountain View"
  set_var EASYRSA_REQ_ORG        "PlanetScale Inc"
  set_var EASYRSA_REQ_EMAIL      "carequest@planetscale.com"
  set_var EASYRSA_REQ_OU         "Operations"
  set_var EASYRSA_KEY_SIZE       2048
  set_var EASYRSA_ALGO           rsa
  set_var EASYRSA_CA_EXPIRE      3650
  set_var EASYRSA_CERT_EXPIRE    1095
  ```

Bootstrap your CA. During the second step you will be prompted for a password. For the answers after the password prompt, you should be able to just hit enter multiple times as you have already configured it in the `vars` file above.

{{< warning >}}
Do not forget this password! You will not be able to recover it. 
{{< /warning >}}

```bash
  $ cd ~/CA/
  $ ./easyrsa init-pki

  Note: using Easy-RSA configuration from: /home/user/CA/vars

  init-pki complete; you may now create a CA or requests.
  Your newly created PKI dir is: /home/user/CA/pki

  $ ./easyrsa build-ca

  Note: using Easy-RSA configuration from: /home/user/CA/vars
  Using SSL: openssl OpenSSL 1.1.1g FIPS  21 Apr 2020

  Enter New CA Key Passphrase: 
  Re-Enter New CA Key Passphrase: 
  Generating RSA private key, 2048 bit long modulus (2 primes)
  ...............................................................................+++++
  e is 65537 (0x010001)
  You are about to be asked to enter information that will be incorporated
  into your certificate request.
  What you are about to enter is what is called a Distinguished Name or a DN.
  There are quite a few fields but you can leave some blank
  For some fields there will be a default value,
  If you enter '.', the field will be left blank.
  -----
  Country Name (2 letter code) [US]:
  State or Province Name (full name) [California]:
  Locality Name (eg, city) [Mountain View]:
  Organization Name (eg, company) [PlanetScale Inc]:
  Organizational Unit Name (eg, section) [Operations]:
  Common Name (eg: your user, host, or server name) [Easy-RSA CA]:
  Email Address [carequest@planetscale.com]:

  CA creation complete and you may now import and sign cert requests.
  Your new CA certificate file for publishing is at:
  /home/user/CA/pki/ca.crt
```

Your CA is now configured and you should be able to generate certs easily now.

### Application to vtgate

While applications can connect to vtgate using gRPC, the vast majority of Vitess users only use the MySQL protocol. When using the MySQL protocol, most users will use username/password for client authentication, although it is also possible to configure TLS client certificate authentication. We will assume the use of username/password authentication.

For each vtgate you should generate a server private key and certificate. We will do this in two steps:  

- First we generate a private key and certificate request.  
- We will then use the CA to sign that request to produce the server certificate.
  
For the the prompts during `gen-req`, you can just hit enter. You will be prompted to type `yes` and enter the CA password during the `sign-req` phase.

```bash
  $ cd ~/CA/
  $ ./easyrsa gen-req vtgate1 nopass

  Note: using Easy-RSA configuration from: /home/user/CA/vars
  Using SSL: openssl OpenSSL 1.1.1g FIPS  21 Apr 2020
  Generating a RSA private key
  ............................+++++
  writing new private key to '/home/user/CA/pki/easy-rsa-178308.W6uc3G/tmp.Iqlvgf'
  -----
  You are about to be asked to enter information that will be incorporated
  into your certificate request.
  What you are about to enter is what is called a Distinguished Name or a DN.
  There are quite a few fields but you can leave some blank
  For some fields there will be a default value,
  If you enter '.', the field will be left blank.
  -----
  Country Name (2 letter code) [US]:
  State or Province Name (full name) [California]:
  Locality Name (eg, city) [Mountain View]:
  Organization Name (eg, company) [PlanetScale Inc]:
  Organizational Unit Name (eg, section) [Operations]:
  Common Name (eg: your user, host, or server name) [vtgate1]:
  Email Address [carequest@planetscale.com]:

  Keypair and certificate request completed. Your files are:
  req: /home/user/CA/pki/reqs/vtgate1.req
  key: /home/user/CA/pki/private/vtgate1.key

  $ ./easyrsa sign-req server vtgate1

  Note: using Easy-RSA configuration from: /home/user/CA/vars
  Using SSL: openssl OpenSSL 1.1.1g FIPS  21 Apr 2020


  You are about to sign the following certificate.
  Please check over the details shown below for accuracy. Note that this request
  has not been cryptographically verified. Please be sure it came from a trusted
  source or that you have verified the request checksum with the sender.

  Request subject, to be signed as a server certificate for 1095 days:

  subject=
      countryName               = US
      stateOrProvinceName       = California
      localityName              = Mountain View
      organizationName          = PlanetScale Inc
      organizationalUnitName    = Operations
      commonName                = vtgate1
      emailAddress              = carequest@planetscale.com


  Type the word 'yes' to continue, or any other input to abort.
    Confirm request details: yes
  Using configuration from /home/user/CA/pki/easy-rsa-177552.IsttQK/tmp.NA5kv0
  Enter pass phrase for /home/user/CA/pki/private/ca.key:
  Check that the request matches the signature
  Signature ok
  The Subject's Distinguished Name is as follows
  countryName           :PRINTABLE:'US'
  stateOrProvinceName   :ASN.1 12:'California'
  localityName          :ASN.1 12:'Mountain View'
  organizationName      :ASN.1 12:'PlanetScale Inc'
  organizationalUnitName:ASN.1 12:'Operations'
  commonName            :ASN.1 12:'vtgate1'
  emailAddress          :IA5STRING:'carequest@planetscale.com'
  Certificate is to be certified until Oct  4 00:07:58 2023 GMT (1095 days)

  Write out database with 1 new entries
  Data Base Updated

  Certificate created at: /home/user/CA/pki/issued/vtgate1.crt
```

Our certificate has now been issued, and we can use the private key file  in `/home/user/CA/pki/private/vtgate1.key` along with the issued server certificate in `/home/user/CA/pki/issued/vtgate1.crt` to configure vtgate for using TLS with MySQL clients.  First we copy the private key and server certificate to the appropriate configuration directory, and then tighten up the file permissions and ownership.

This will differ in your environment:

```bash
  $ mkdir ~/config/
  $ cp /home/user/CA/pki/private/vtgate1.key ~/config/
  $ cp /home/user/CA/pki/issued/vtgate1.crt ~/config/
  $ chown vtgate:vtgate ~/config/vtgate1.*
  $ chmod 400 ~/config/vtgate1.*
```

Now, we can add the options to vtgate to use the above private key and server certificate.  Modify the vtgate commandline or startup script to add the following parameters:

```
  --mysql_server_ssl_key ~/config/vtgate1.key --mysql_server_ssl_cert ~/config/vtgate1.crt --mysql_server_require_secure_transport
```

{{< info >}}
You can now start/restart the vtgate instance. Any vtgate connections from now on will be required to use TLS, so you may have to reconfigure your applications/clients. In addition, to avoid man-in-the-middle attacks, you may want the clients to verify the server by validating the server certificate against the CA cert. 
{{< /info >}}

Here is an example using the MySQL CLI client.  Exact options will vary between MySQL versions, this is using MySQL (8.0.21) client:

```bash
  $ cp /home/user/CA/pki/ca.crt /var/tmp/ca.crt
  $ mysql -u mysql_user -p -h 127.0.0.1 -P 15306 --ssl-mode=VERIFY_CA --ssl-ca=/var/tmp/ca.crt
  Enter password: 
  Welcome to the MySQL monitor.  Commands end with ; or \g.
  Your MySQL connection id is 3
  Server version: 5.7.9-Vitess MySQL Community Server - GPL
  .
  .
  .
  mysql> \s
  --------------
  mysql  Ver 8.0.20-11 for Linux on x86_64 (Percona Server (GPL), Release 11, Revision 159f0eb)

  Connection id:          3
  Current database:
  Current user:           vt_app@localhost
  SSL:                    Cipher in use is ECDHE-RSA-AES128-GCM-SHA256
  Current pager:          stdout
  Using outfile:          ''
  Using delimiter:        ;
  Server version:         5.7.9-Vitess MySQL Community Server - GPL
  Protocol version:       10
  Connection:             127.0.0.1 via TCP/IP
  .
  .
```
  
The above MySQL CLI output shows that the connection is encrypted, and that the server (vtgate) was successfully validated using the CA certificate. If the server certificate could not be validated using the CA certificate, an error similar to this would have been seen:

```
  ERROR 2026 (HY000): SSL connection error: error:14090086:SSL routines:SSL3_GET_SERVER_CERTIFICATE:certificate verify failed
```

If TLS was not setup on the vtgate at all, an error like this could have resulted:

```
  ERROR 2026 (HY000): SSL connection error: SSL is required but the server doesn't support it
```

### vttablet to MySQL

A common Vitess deployment model is to co-locate vttablet and MySQL on the same host/VM/container. In a case like this, vttablet connectivity to MySQL will be via local unix socket or TCP connection on localhost. It is unnecessary to configure encryption between vttablet and MySQL in this case, since the traffic never leaves the local machine/VM. However, in some deployment models vttablet and MySQL are running on different hosts, and you may want vttablet to use TLS to speak to MySQL.

We will not cover configuring MySQL to use TLS certificates extensively here, just the minimum.  Please consult the MySQL documentation for further information. Again, we will also assume that vttablet will be using MySQL username/password client authentication.

Note that when you are configuring TLS and MySQL you will need to be aware of what TLS versions are supported. You may be using an [older version of MySQL that does not have TLS 1.2 support](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.SSLSupport). If you need to support pre 1.2 TLS [vtgate supports ](https://github.com/vitessio/vitess/blob/de7f133dbe2dd6a7910f13c682910a4f5c0ac0df/go/vt/vtgate/plugin_mysql_server.go#L67)that setting using `--mysql_server_tls_min_version` and vttablet supports that setting using `--db_tls_min_version=TLSv1.1`

Generate a server certificate for our MySQL instance using our CA:

```bash
  $ cd ~/CA/
  $ ./easyrsa gen-req mysql1 nopass
  .
  .
  .
  Keypair and certificate request completed. Your files are:
  req: /home/user/CA/pki/reqs/mysql1.req
  key: /home/user/CA/pki/private/mysql1.key

  $ ./easyrsa sign-req server mysql1
  .
  .
  .
  Write out database with 1 new entries
  Data Base Updated

  Certificate created at: /home/user/CA/pki/issued/mysql1.crt
```

Copy the files `/home/user/CA/pki/private/mysql1.key` and `/home/user/CA/pki/issued/mysql1.crt` to the MySQL server in the appropriate locations, securing their ownership and permissions appropriately.

Configure the MySQL server options `ssl-key` and `ssl-cert` appropriately to point to where you placed the private key and certificate above. You can read more about it [here](https://dev.mysql.com/doc/mysql-security-excerpt/8.0/en/using-encrypted-connections.html)

Note that these options do not require clients to use TLS, but is optional. If you need to require all TCP/IP clients to use TLS, you can use the MySQL server option `require_secure_transport`, or you can enforce it on a per MySQL user basis by using the `REQUIRE SSL` option when creating or altering a MySQL-level user. See the MySQL documentation for details.

Restart your MySQL server to make these MySQL server option configuration changes active.

Now, configure vttablet to connect to MySQL using the necessary parameters, verifying the CA certificate:

```bash
  $ cp /home/user/CA/pki/ca.crt ~/config/
```

Add the vttablet parameters:

```
  --db_ssl_ca /home/user/config/ca.crt --db_flags 1073743872 --db_server_name mysql1
```
  
Restart the vttablet. Note that the `db_server_name` parameter value will differ depending on your issued certificate common name; and is unnecessary if the certificate common name matches the DNS name vttablet is using to connect to the MySQL server.

The `1073743872` is a combination of the MySQL `CLIENT_SSL` (2048) and `CLIENT_SSL_VERIFY_SERVER_CERT` flags (1073741824);  which means "encrypt the connection to MySQL *and* verify the SSL cert presented by the server".

If you just wish to encrypt the vttablet -> MySQL server communication and you do not care about server certificate validation, you can just use this vttablet flag instead:

```
  --db_flags 2048
```

Note that using the above `db_flags` will also result in the MySQL to MySQL communication for replication between the replica/rdonly instances of a Vitess shard and its primary to be encrypted, as long as the upstream MySQL instance the replica is connecting to has been configured correctly to support TLS MySQL protocol connections (see above).

## vttablet Data and Control Paths

In Vitess, communication between vtgate and vttablet instances are via gRPC. gRPC uses HTTP/2 as a transport protocol, but by default this is not encrypted in Vitess.  To secure this data path you need to, at a minimum, configure TLS for gRPC on the server (vttablet) side.

Other components, as detailed above, also connect to vttablet via gRPC. After configuring vttablet gRPC for TLS, you will need to configure all these components (vtgate, other vttablets, vtctld) explicitly to connect using TLS to vttablet via gRPC, or you will have a partially or wholly non-functional system.

#### vtgate to vttablet

First, generate a certificate for use by vttablet:

```bash
  $ cd ~/CA/
  $ ./easyrsa gen-req vttablet1 nopass

  Note: using Easy-RSA configuration from: /home/user/CA/vars
  Using SSL: openssl OpenSSL 1.1.1g FIPS  21 Apr 2020
  Generating a RSA private key
  ..................................+++++
  .....+++++
  writing new private key to '/home/user/CA/pki/easy-rsa-209692.tdDNNt/tmp.hwhw8x'
  -----
  You are about to be asked to enter information that will be incorporated
  into your certificate request.
  What you are about to enter is what is called a Distinguished Name or a DN.
  There are quite a few fields but you can leave some blank
  For some fields there will be a default value,
  If you enter '.', the field will be left blank.
  -----
  Country Name (2 letter code) [US]:
  State or Province Name (full name) [California]:
  Locality Name (eg, city) [Mountain View]:
  Organization Name (eg, company) [PlanetScale Inc]:
  Organizational Unit Name (eg, section) [Operations]:
  Common Name (eg: your user, host, or server name) [vttablet1]:
  Email Address [carequest@planetscale.com]:

  Keypair and certificate request completed. Your files are:
  req: /home/user/CA/pki/reqs/vttablet1.req
  key: /home/user/CA/pki/private/vttablet1.key

  $ ./easyrsa sign-req server vttablet1

  Note: using Easy-RSA configuration from: /home/user/CA/vars
  Using SSL: openssl OpenSSL 1.1.1g FIPS  21 Apr 2020


  You are about to sign the following certificate.
  Please check over the details shown below for accuracy. Note that this request
  has not been cryptographically verified. Please be sure it came from a trusted
  source or that you have verified the request checksum with the sender.

  Request subject, to be signed as a server certificate for 1095 days:

  subject=
      countryName               = US
      stateOrProvinceName       = California
      localityName              = Mountain View
      organizationName          = PlanetScale Inc
      organizationalUnitName    = Operations
      commonName                = vttablet1
      emailAddress              = carequest@planetscale.com


  Type the word 'yes' to continue, or any other input to abort.
    Confirm request details: yes
  Using configuration from /home/user/CA/pki/easy-rsa-209844.f9wDrk/tmp.3rww6R
  Enter pass phrase for /home/user/CA/pki/private/ca.key:
  Check that the request matches the signature
  Signature ok
  The Subject's Distinguished Name is as follows
  countryName           :PRINTABLE:'US'
  stateOrProvinceName   :ASN.1 12:'California'
  localityName          :ASN.1 12:'Mountain View'
  organizationName      :ASN.1 12:'PlanetScale Inc'
  organizationalUnitName:ASN.1 12:'Operations'
  commonName            :ASN.1 12:'vttablet1'
  emailAddress          :IA5STRING:'carequest@planetscale.com'
  Certificate is to be certified until Oct  4 20:23:48 2023 GMT (1095 days)

  Write out database with 1 new entries
  Data Base Updated

  Certificate created at: /home/user/CA/pki/issued/vttablet1.crt

  $ cp /home/user/CA/pki/private/vttablet1.key ~/config/
  $ cp /home/user/CA/pki/issued/vttablet1.crt ~/config/
  $ chmod 400 ~/config/vttablet1.*
```

To configure vttablet to use a server certificate for its gRPC server, add the below to the vttablet parameters:

```
  --grpc_cert /home/user/config/vttablet1.crt --grpc_key /home/user/config/vttablet1.key 
```

Note that adding these options **enforces** TLS only gRPC connections to this vttablet instace from that point onwards.

This means that you will need to add the following option to your vtgate instances to successfully connect to this vttablet instance from this point forward:

```
  --tablet_grpc_server_name vttablet1 --tablet_grpc_ca /home/user/config/ca.crt 
```

Adding this option to a vtgate instance will require all vttablet instances this vtgate connects to to be configured for TLS as well. This is unfortunately an all-or-nothing proposition, there is no incremental migration to using TLS in this case.

If you have vtgate instances accessing your vttablet instance after you have configured TLS on the vttablet side, you may see errors like this in the vttablet logs:

```
  W1004 13:34:16.352458  212354 server.go:650] grpc: Server.Serve failed to complete security handshake from "[::1]:51492": tls: first record does not look like a TLS handshake
```

Conversely, if you have configured the TLS parameters on the vtgate side and the vtgate instance is still trying to connect to vttablet instances that are not configured with the correct TLS options, you might see errors like this in the vtgate logs:

```
  W1004 14:38:29.383672  214179 tablet_health_check.go:323] tablet cell:"zone1" uid:101  healthcheck stream error: Code: UNAVAILABLE
  vttablet: rpc error: code = Unavailable desc = all SubConns are in TransientFailure, latest connection error: connection error: desc = "transport: authentication handshake failed: tls: first record does not look like a TLS handshake"
```

In case of VTOrc, you will need to add following to VTOrc instance to successfully connect to this vttablet instance

```
  --tablet_manager_grpc_server_name vttablet1 --tablet_manager_grpc_ca /home/user/config/ca.crt
```

#### vttablet to vtablet:  vreplication within or Across Shards

For vreplication to work between vttablet instances once the gRPC server TLS options above are activated, you will need to add the following additional vttablet options:

```
  --tablet_grpc_server_name vttablet1 --tablet_grpc_ca /home/user/config/ca.crt 
```

Since each vttablet instance may need to talk to more than one other vttablet instances for vreplication streams, the implication is that each vttablet instances needs to either:

  * Use the same vttablet server key material and server certificate common name for each vttablet instance. This is obviously the easiest option, but might not conform to your compliance requirements.
  * or, ensure each vttablet server certificate common name or IP SAN matches the DNS name or IP it it accessed via. In this case, you can omit the use of the `--tablet_grpc_server_name` above for vttablet, and also for vtgate.
  
#### vtctld to vttablet

Once your vttablet(s) are configured with gRPC server TLS options as above,
you will need to also add TLS client options to vtctld, or vtctld will be
unable to connect to your vttablet(s).

* To achieve this, add the following options to the vtctld commandline:

```
  --tablet_grpc_server_name vttablet1 --tablet_grpc_ca /home/user/config/ca.crt --tablet_manager_grpc_server_name vttablet1 --tablet_manager_grpc_ca /home/user/config/ca.crt
```

### vtctldclient to vtctld

The communication from vtctldclient to vtctld is also via gRPC, so the method for securing it is similar to vtctld to vttablet above.

Generate a server certificate for vtctld:

```bash
  $ cd ~/CA/
  $ ./easyrsa gen-req vtctld1 nopass

  Note: using Easy-RSA configuration from: /home/user/CA/vars
  Using SSL: openssl OpenSSL 1.1.1g FIPS  21 Apr 2020
  Generating a RSA private key
  ..................................................+++++
  ....................................................+++++
  writing new private key to '/home/user/CA/pki/easy-rsa-234817.QW1l8f/tmp.REK9r3'
  -----
  You are about to be asked to enter information that will be incorporated
  into your certificate request.
  What you are about to enter is what is called a Distinguished Name or a DN.
  There are quite a few fields but you can leave some blank
  For some fields there will be a default value,
  If you enter '.', the field will be left blank.
  -----
  Country Name (2 letter code) [US]:
  State or Province Name (full name) [California]:
  Locality Name (eg, city) [Mountain View]:
  Organization Name (eg, company) [PlanetScale Inc]:
  Organizational Unit Name (eg, section) [Operations]:
  Common Name (eg: your user, host, or server name) [vtctld1]:
  Email Address [carequest@planetscale.com]:

  Keypair and certificate request completed. Your files are:
  req: /home/user/CA/pki/reqs/vtctld1.req
  key: /home/user/CA/pki/private/vtctld1.key

  $ ./easyrsa sign-req server vtctld1

  Note: using Easy-RSA configuration from: /home/user/CA/vars
  Using SSL: openssl OpenSSL 1.1.1g FIPS  21 Apr 2020


  You are about to sign the following certificate.
  Please check over the details shown below for accuracy. Note that this request
  has not been cryptographically verified. Please be sure it came from a trusted
  source or that you have verified the request checksum with the sender.

  Request subject, to be signed as a server certificate for 1095 days:

  subject=
      countryName               = US
      stateOrProvinceName       = California
      localityName              = Mountain View
      organizationName          = PlanetScale Inc
      organizationalUnitName    = Operations
      commonName                = vtctld1
      emailAddress              = carequest@planetscale.com


  Type the word 'yes' to continue, or any other input to abort.
    Confirm request details: yes
  Using configuration from /home/user/CA/pki/easy-rsa-234873.8zKYwl/tmp.zDGxDd
  Enter pass phrase for /home/user/CA/pki/private/ca.key:
  Check that the request matches the signature
  Signature ok
  The Subject's Distinguished Name is as follows
  countryName           :PRINTABLE:'US'
  stateOrProvinceName   :ASN.1 12:'California'
  localityName          :ASN.1 12:'Mountain View'
  organizationName      :ASN.1 12:'PlanetScale Inc'
  organizationalUnitName:ASN.1 12:'Operations'
  commonName            :ASN.1 12:'vtctld1'
  emailAddress          :IA5STRING:'carequest@planetscale.com'
  Certificate is to be certified until Oct  5 02:30:05 2023 GMT (1095 days)

  Write out database with 1 new entries
  Data Base Updated

  Certificate created at: /home/user/CA/pki/issued/vtctld1.crt

  $ cp /home/user/CA/pki/issued/vtctld1.crt ~/config/
  $ cp /home/user/CA/pki/private/vtctld1.key ~/config/
```

Add TLS gRPC server options to vtctld commandline and restart vtctld:

```
  --grpc_cert /home/user/config/vtctld1.crt --grpc_key /home/user/config/vtctld1.key
```

At this point, all vtctldclient connections to vtctld will need the appropriate additional TLS gRPC options, or they will fail.  Add these options:

```
  --vtctld_grpc_ca /home/user/config/ca.crt --vtctld_grpc_server_name vtctld1
```

## Topology Server Data Paths

Vitess supports several topology server implementations, with the major ones being `etcd` and `ZooKeeper`. Since each of these use their own protocols, securing communications between Vitess components (like vtgate, vttablet and vtctld) and the topology server is specific to the topology server implementation.  We we will cover `etcd` first, then `ZooKeeper`.

It should be noted that regardless of the implementation, no sensitive data is stored in the Vitess topology server, i.e.:

 * No data (queries/results) is stored in, or flows through, the topology server.
 * No secrets (keys, certificates, passwords) are stored in the toplogy server
   data store.
 * Only metadata (VSchema, keyspace and shard information) is stored in the
   topology server data store.

### Configuring etcd for Secure Connections

We will not cover setting up `etcd` with certificates in this guide. You can consult the `etcd` documenation [here](https://etcd.io/docs/v3.5/op-guide/security/). Note that you can use `easy-rsa` as above to generate your server private key and certificate pairs. If you do not require client authentication, that is sufficient, and you then just have to distribute your CA certificate (`/home/user/CA/pki/ca.crt` in the examples above) to your clients, and proceed as in the next section.

### Configuring Secure Connectivity between vtgate/vttablet/vtctld and etcd

The Vitess servers (vtgate/vttablet/vtctld) share the same set of parameters to connect via TLS to `etcd`:

 * `--topo_etcd_tls_ca` : Path to the PEM certificate used to authenticate the TLS CA certificate presented by the `etcd` server.  Enables TLS to `etcd` if present.
 * `--topo_etcd_tls_cert` : Path to a PEM client certificate (mTLS) used to authenticate this client to the `etcd` server. Only necessary if your `etcd` server requires client authentication.
 * `--topo_etcd_tls_key` : Path to a PEM private key used for signing the client certificate (mTLS) exchange with the `etcd` server. Only necessary if your `etcd` server requires client authentication.

As is necessary for your design/architecture, add one or more of the above options to your vtgate, vttablet and vtctld instances.

### Configuring etcd for Secure Connections

We will just mention the basic flags here for getting `etcd` to accept encrypted client connections.  We will not cover the flags to make sure that communication between `etcd` cluster members (peers) are encrypted.

Flags:

  * `--listen-client-urls`: specify an `https://` host and port prefix
  * `--advertise-client-urls`: specify an `https://` host and port prefix
  * `--cert-file`:  Point to to a server cert PEM file
  * `--key-file`:  Point to to a server key PEM file
  * (optional) `--cipher-suites`:  Can be used to limit the cipher suites the etc server will negotiate (e.g. `TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384` is a popular combination).  
  
Note that the Vitess client components will negotiate any of the standard golang TLS client cipher suites (which can vary somewhat depending on which golang version Vitess was compiled with, and what libraries are available on the platform).  It is not possible to limit the cipher suites from the etcd client (i.e. Vitess) components.

It is also possible to configure `etcd` to require/verify client certificates from the clients; for that use the `--trusted-ca-file` option to point to the PEM CA cert that the client certs are signed with.

### Configuring ZooKeeper for Secure Connections

We will not cover setting up `Zookeeper` with certificates in this guide. You can consult the `Zookeeper` documenation [here](https://cwiki.apache.org/confluence/display/ZOOKEEPER/ZooKeeper+SSL+User+Guide), specifically the `Server` section. Note that you can use `easy-rsa` as above to generate your server private key and certificate pairs. If you do not require client authentication, that is sufficient, and you then just have to distribute your CA certificate (`/home/user/CA/pki/ca.crt` in the examples above) to your clients, and proceed as in the next section.

### Configuring Secure Connectivity between vtgate/vttablet/vtctld and ZooKeeper

The Vitess servers (vtgate/vttablet/vtctld) share the same set of parameters to connect via TLS to `Zookeeper`:

 * `--topo_zk_tls_ca` : Path to the PEM certificate used to authenticate the TLS CA certificate presented by the `Zookeeper` server.  Enables TLS to `etcd` if present.
 * `--topo_zk_tls_cert` : Path to a PEM client certificate (mTLS) used to authenticate this client to the `Zookeeper` server. Only necessary if your `Zookeeper` server requires client authentication.
 * `--topo_zk_tls_key` : Path to a PEM private key used for signing the client certificate (mTLS) exchange with the `Zookeeper` server. Only necessary if your `Zookeeper` server requires client certificate authentication.
 * `--topo_zk_auth_file` : Unlike `etcd`, `Zookeeper` also supports username/password authentication from clients. This option is used to pass the combination of authentication schema, username and password to the client to connect with to the server, e.g. with a value like `digest:username:password`.

As is necessary for your design/architecture, add one or more of the above options to your vtgate, vttablet and vtctld instances.

## Generating client Certificates with easy-rsa

`easy-rsa` can also be used to generate client certificates (i.e for mTLS or mutual TLS).  Mutual TLS needs at least two additional parameters on the client side, and one additional parameter on the server side:

  * Client side:
    * Private key to sign the client certificate exchange with server.
    * Client certificate itself.
  * Server side:
    * CA certificate that signed the client certificate(s) that the client(s) are presenting.

To generate the client-side private and client certificate using `easy-rsa`:

```bash
  $ cd ~/CA/
  $ ./easyrsa gen-req client1 nopass 
  Note: using Easy-RSA configuration from: /home/user/CA/vars
  Using SSL: openssl OpenSSL 1.1.1g FIPS  21 Apr 2020
  Generating a RSA private key
  ..........+++++
  .........+++++
  writing new private key to '/home/user/CA/pki/easy-rsa-144133.y9mHHP/tmp.LSLIhv'
  -----
  You are about to be asked to enter information that will be incorporated
  into your certificate request.
  What you are about to enter is what is called a Distinguished Name or a DN.
  There are quite a few fields but you can leave some blank
  For some fields there will be a default value,
  If you enter '.', the field will be left blank.
  -----
  Country Name (2 letter code) [US]:
  State or Province Name (full name) [California]:
  Locality Name (eg, city) [Mountain View]:
  Organization Name (eg, company) [PlanetScale Inc]:
  Organizational Unit Name (eg, section) [Operations]:
  Common Name (eg: your user, host, or server name) [client1]:
  Email Address [carequest@planetscale.com]:

  Keypair and certificate request completed. Your files are:
  req: /home/user/CA/pki/reqs/client1.req
  key: /home/user/CA/pki/private/client1.key

  $ ./easyrsa sign-req client client1
  Note: using Easy-RSA configuration from: /home/user/CA/vars
  Using SSL: openssl OpenSSL 1.1.1g FIPS  21 Apr 2020


  You are about to sign the following certificate.
  Please check over the details shown below for accuracy. Note that this request
  has not been cryptographically verified. Please be sure it came from a trusted
  source or that you have verified the request checksum with the sender.

  Request subject, to be signed as a client certificate for 1095 days:

  subject=
      countryName               = US
      stateOrProvinceName       = California
      localityName              = Mountain View
      organizationName          = PlanetScale Inc
      organizationalUnitName    = Operations
      commonName                = client1
      emailAddress              = carequest@planetscale.com


  Type the word 'yes' to continue, or any other input to abort.
    Confirm request details: yes
  Using configuration from /home/user/CA/pki/easy-rsa-144332.6AjhHm/tmp.KWRj4O
  Enter pass phrase for /home/user/CA/pki/private/ca.key:
  Check that the request matches the signature
  Signature ok
  The Subject's Distinguished Name is as follows
  countryName           :PRINTABLE:'US'
  stateOrProvinceName   :ASN.1 12:'California'
  localityName          :ASN.1 12:'Mountain View'
  organizationName      :ASN.1 12:'PlanetScale Inc'
  organizationalUnitName:ASN.1 12:'Operations'
  commonName            :ASN.1 12:'client1'
  emailAddress          :IA5STRING:'carequest@planetscale.com'
  Certificate is to be certified until Oct 14 04:10:28 2023 GMT (1095 days)

  Write out database with 1 new entries
  Data Base Updated

  Certificate created at: /home/user/CA/pki/issued/client1.crt
```

Our client certificate and key has now been issued, and we can use the files `/home/user/CA/pki/issued/client1.crt` and `/home/user/CA/pki/private/client1.key` on our client for client certificate (mTLS) authentication.
