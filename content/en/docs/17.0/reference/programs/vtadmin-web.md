---
title: vtadmin-web
---

## Environment Variables

These environment variables configure VTAdmin, most commonly when creating a `vtadmin-web` production build as described in the [VTAdmin Operator's Guide][operators_guide]. These environment variables also enumerated in [web/vtadmin/vite-env.d.ts][vtadmin_env_ref].

Under the hood, `vtadmin-web` uses [vite][vite], which requires all environment variables to be prefixed with `VITE` to avoid accidentally including secrets in the static build. For more on custom environment variables with vite, see ["Env Variables and Modes"][vite_env_ref].

These environment variables can be passed inline to the `npm run build` command or [added to a .env file][vite_env_file_ref].


| Name | Required | Type | Default | Definition |
| -------- | --------- | --------- | --------- |--------- |
| `VITE_VTADMIN_API_ADDRESS` | **Required** | string | - | The full address of vtadmin-api's HTTP(S) interface. Example: "https://vtadmin.example.com:12345" | 
| `VITE_BUGSNAG_API_KEY` | Optional | string | - | An API key for https://bugsnag.com. If defined, the @bugsnag/js client will be initialized. Your Bugsnag API key can be found in your Bugsnag Project Settings. | 
| `VITE_BUILD_BRANCH` | Optional | string | - | The branch vtadmin-web was built with. Used only for debugging; will appear on the (secret) /settings route in the UI. |
| `VITE_BUILD_SHA` | Optional | string | - | The SHA vtadmin-web was built with. Used only for debugging; will appear on the (secret) /settings route in the UI. |
| `VITE_DOCUMENT_TITLE` | Optional | string | "VTAdmin" | Used for the document.title property. Overriding this can be useful to differentiate between multiple VTAdmin deployments, e.g., "VTAdmin (staging)". |
| `VITE_ENABLE_EXPERIMENTAL_TABLET_DEBUG_VARS` | Optional | string | - | Optional, but recommended. When `"true"`, enables front-end components that query vtadmin-api's /api/experimental/tablet/{tablet}/debug/vars endpoint. | 
| `VITE_FETCH_CREDENTIALS` | Optional | string | - | Configures the `credentials` property for fetch requests  made against vtadmin-api. If unspecified, uses fetch defaults. See https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch#sending_a_request_with_credentials_included |
| `VITE_READONLY_MODE` | Optional | string | "false" | If "true", UI controls that correspond to write actions (PUT, POST, DELETE) will be hidden. Note that this *only* affects the UI. If write actions are a concern, Vitess operators are encouraged to also [configure vtadmin-api for role-based access control (RBAC)][rbac] if needed. | 

[vite]: https://vitejs.dev/
[vite_env_ref]: https://vitejs.dev/guide/env-and-mode.html
[vite_env_file_ref]: https://vitejs.dev/guide/env-and-mode.html#env-files#adding-development-environment-variables-in-env
[operators_guide]: ../../vtadmin/operators_guide
[rbac]: ../../vtadmin/role-based-access-control
[vtadmin_env_ref]: https://github.com/vitessio/vitess/blob/main/web/vtadmin/vite-env.d.ts

These environment variables are automatically [filled in by vite](https://vitejs.dev/guide/env-and-mode.html#env-variables) and you do not have to provide them. They are available in the `import.meta.env` object at run time, and listed here for full coverage of environment variables:

| Name | Type | Default | Definition |
| -------- | --------- | --------- | --------- |
| `MODE` | string | "production", "staging", or "development" | The current mode in which vite is running | 
