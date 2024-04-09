---
title: RevokeCert
series: vttlstest
commit: cb5464edf5d7075feae744f3580f8bc626d185aa
---
## vttlstest RevokeCert

Revoke a certificate

### Synopsis

Revoke a certificate

```
vttlstest RevokeCert [--root <dir>] [--parent <name>] <cert name>
```

### Examples

```
RevokeCert --root /tmp --parent mail.mycoolsite.com postman1
```

### Options

```
  -h, --help            help for RevokeCert
      --parent string   Parent cert name to use. Use 'ca' for the toplevel CA. (default "ca")
```

### Options inherited from parent commands

```
      --root string   root directory for all artifacts (default ".")
```

### SEE ALSO

* [vttlstest](../)	 - vttlstest is a tool for generating test certificates, keys, and related artifacts for TLS tests.

