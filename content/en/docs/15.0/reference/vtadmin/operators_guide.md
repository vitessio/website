---
title: Operator's Guide
description: How to configure and run VTAdmin
---

{{< info >}}
If you run into issues or have questions, we recommend posting in our [#feat-vtadmin Slack channel](https://vitess.slack.com/archives/C01H307F68J). Click the Slack icon in the top right to join. This is a very active community forum and a great place to interact with other users.
{{< /info >}}

## Get Started

This guide describes how to configure and build the VTAdmin API server (`vtadmin`) and front-end (`vtadmin-web`).

If you intend to use the Vitess operator to deploy VTAdmin please refer to [Running with Vitess Operator](../running_with_vtop).

The simplest VTAdmin deployment involves a single Vitess cluster. You can look
at the [local example][local_example] for a
minimal invocation of the `vtadmin` and `vtadmin-web` binaries.

## Prerequisites

- Building `vtadmin-web` requires [node](https://nodejs.org/en/) at the version given in the [package.json file](https://github.com/vitessio/vitess/blob/main/web/vtadmin/package.json).

## 1. Define the cluster configuration

VTAdmin is mapped to one or more Vitess clusters two ways:

- Add a `clusters.yaml` file and pass its path to `vtadmin` with the `--cluster-config` build flag
- Set the `--cluster` and/or `--cluster-defaults` flags when running `vtadmin`, described in the next section.

When both command-line cluster configs and a config file are provided, any options for a given cluster on the command-line take precedence over options for that cluster in the config file. 

For a well-commented example enumerating the cluster configuration options, see [clusters.example.yaml](https://github.com/vitessio/vitess/blob/main/doc/vtadmin/clusters.yaml).


## 2. Configure `vtadmin`

Configure the flags for the `vtadmin` process. The full list of flags is given in the [`vtadmin` reference documentation][vtadmin_flag_ref].

The following is from the [local example][local_example] showing a minimal set of flags. Here, we define the cluster configuration with the `--cluster` flag and use static (file-based) discovery configured in the [local example's `discovery.json` file][discovery_json]. 

```
vtadmin \
  --addr ":14200" \
  --http-origin "https://vtadmin.example.com:14201" \
  --http-tablet-url-tmpl "http://{{ .Tablet.Hostname }}:15{{ .Tablet.Alias.Uid }}" \
  --tracer "opentracing-jaeger" \
  --grpc-tracing \
  --http-tracing \
  --logtostderr \
  --alsologtostderr \
  --no-rbac \
  --cluster "id=local,name=local,discovery=staticfile,discovery-staticfile-path=./vtadmin/discovery.json,tablet-fqdn-tmpl={{ .Tablet.Hostname }}:15{{ .Tablet.Alias.Uid }}" 
```

To optionally configure role-based access control (RBAC), refer to the [RBAC documentation][rbac_docs].

## 3. Configure and build `vtadmin-web`

Environment variables can be defined in a `.env` file or passed inline to the `npm run build` command. The full list of flags is given in the [`vtadmin-web` reference documentation][vtadmin_web_env_ref].

The following is from the [local example][local_example] showing a minimal set of environment variables. `$web_dir`, in this case, refers to the [`vtadmin-web` source directory][vtadmin_web_src] but could equally apply to the `web/vtadmin/` directory copied into a Docker container, for example. `REACT_APP_VTADMIN_API_ADDRESS` uses the same hostname as the `--addr` flag passed to `vtadmin` in the previous step. 

```
npm --prefix $web_dir --silent install

REACT_APP_VTADMIN_API_ADDRESS="https://vtadmin-api.example.com:14200" \
  REACT_APP_ENABLE_EXPERIMENTAL_TABLET_DEBUG_VARS="true" \
  npm run --prefix $web_dir build
```

If you want to overwrite or set environment variables after the build you can use the `$web_dir/build/config/config.js` file. 
For example:

```javascript
window.env = {
    'REACT_APP_VTADMIN_API_ADDRESS': "https://vtadmin-api.example.com:14200",
    'REACT_APP_FETCH_CREDENTIALS': "omit",
    'REACT_APP_ENABLE_EXPERIMENTAL_TABLET_DEBUG_VARS': true,
    'REACT_APP_BUGSNAG_API_KEY': "",
    'REACT_APP_DOCUMENT_TITLE': "",
    'REACT_APP_READONLY_MODE': false,
};
```

After running `build` command, the production build of the front-end assets will be in the `$web_dir/build` directory. They can be served as any other static content; for example, [Go's embed package][go_embed] or npm's [serve package][npm_serve]. Each filename inside of `$web_dir/build/static` will contain a unique hash of the file contents. This hash in the file name enables [long term caching techniques][web_caching].

[discovery_json]: https://github.com/vitessio/vitess/blob/main/examples/local/vtadmin/discovery.json
[go_embed]:https://pkg.go.dev/embed
[local_example]: https://github.com/vitessio/vitess/blob/main/examples/local/scripts/vtadmin-up.sh
[npm_serve]: https://www.npmjs.com/package/serve
[rbac_docs]: ../role-based-access-control
[vtadmin_flag_ref]: ../../programs/vtadmin
[vtadmin_web_env_ref]: ../../programs/vtadmin-web
[vtadmin_web_src]: https://github.com/vitessio/vitess/tree/main/web/vtadmin
[web_caching]: https://create-react-app.dev/docs/production-build/#static-file-caching
