---
title: CreateCRL
series: vttlstest
commit: 408a2cc02162f308e589c4b3f7e0e1c746c36254
---
## vttlstest CreateCRL

Create certificate revocation list

### Synopsis

Create certificate revocation list

```
vttlstest CreateCRL [--root <dir>] <server>
```

### Examples

```
CreateCRL --root /tmp mail.mycoolsite.com
```

### Options

```
  -h, --help   help for CreateCRL
```

### Options inherited from parent commands

```
      --root string   root directory for all artifacts (default ".")
```

### SEE ALSO

* [vttlstest](../)	 - vttlstest is a tool for generating test certificates, keys, and related artifacts for TLS tests.

