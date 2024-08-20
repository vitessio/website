---
title: CreateCRL
series: vttlstest
commit: 6cd09cce61fa79a1b7aacb36886b7dc44ae82a94
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

### Options Inherited from Parent Commands

```
      --root string   root directory for all artifacts (default ".")
```

### See Also

* [vttlstest](../)	 - vttlstest is a tool for generating test certificates, keys, and related artifacts for TLS tests.

