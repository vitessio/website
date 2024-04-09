---
title: CreateIntermediateCA
series: vttlstest
commit: cb5464edf5d7075feae744f3580f8bc626d185aa
---
## vttlstest CreateIntermediateCA

Create intermediate certificate authority

### Synopsis

Create intermediate certificate authority

```
vttlstest CreateIntermediateCA [--root <dir>] [--parent <name>] [--serial <serial>] [--common-name <CN>] <CA name>
```

### Examples

```
CreateIntermediateCA --root /tmp --parent ca mail.mycoolsite.com
```

### Options

```
      --common-name string   Common name for the certificate. If empty, uses the name.
  -h, --help                 help for CreateIntermediateCA
      --parent string        Parent cert name to use. Use 'ca' for the toplevel CA. (default "ca")
      --serial string        Serial number for the certificate to create. Should be different for two certificates with the same parent. (default "01")
```

### Options inherited from parent commands

```
      --root string   root directory for all artifacts (default ".")
```

### SEE ALSO

* [vttlstest](../)	 - vttlstest is a tool for generating test certificates, keys, and related artifacts for TLS tests.

