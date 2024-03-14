---
title: vtadmin-web
---

## Environment Variables

These environment variables configure VTAdmin, most commonly when creating a `vtadmin-web` production build as described in the [VTAdmin Operator's Guide][operators_guide]. These environment variables also enumerated in [web/vtadmin/src/react-app-env.d.ts][vtadmin_env_ref].

Under the hood, `vtadmin-web` uses [create-react-app][cra], which requires all environment variables to be prefixed with `REACT_APP` to avoid accidentally including secrets in the static build. For more on custom environment variables with create-react-app, see ["Adding Custom Environment Variables"][cra_env_ref].

These environment variables can be passed inline to the `npm run build` command or [added to a .env file][cra_env_file_ref].


| Name | Required | Type | Default | Definition |
| -------- | --------- | --------- | --------- |--------- |
| `REACT_APP_VTADMIN_API_ADDRESS` | **Required** | string | - | The full address of vtadmin-api's HTTP(S) interface. Example: "https://vtadmin.example.com:12345" | 
| `REACT_APP_BUGSNAG_API_KEY` | Optional | string | - | An API key for https://bugsnag.com. If defined, the @bugsnag/js client will be initialized. Your Bugsnag API key can be found in your Bugsnag Project Settings. | 
| `REACT_APP_BUILD_BRANCH` | Optional | string | - | The branch vtadmin-web was built with. Used only for debugging; will appear on the (secret) /settings route in the UI. |
| `REACT_APP_BUILD_SHA` | Optional | string | - | The SHA vtadmin-web was built with. Used only for debugging; will appear on the (secret) /settings route in the UI. |
| `REACT_APP_DOCUMENT_TITLE` | Optional | string | "VTAdmin" | Used for the document.title property. Overriding this can be useful to differentiate between multiple VTAdmin deployments, e.g., "VTAdmin (staging)". |
| `REACT_APP_ENABLE_EXPERIMENTAL_TABLET_DEBUG_VARS` | Optional | string | - | Optional, but recommended. When `"true"`, enables front-end components that query vtadmin-api's /api/experimental/tablet/{tablet}/debug/vars endpoint. | 
| `REACT_APP_FETCH_CREDENTIALS` | Optional | string | - | Configures the `credentials` property for fetch requests  made against vtadmin-api. If unspecified, uses fetch defaults. See https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch#sending_a_request_with_credentials_included |
| `REACT_APP_READONLY_MODE` | Optional | string | "false" | If "true", UI controls that correspond to write actions (PUT, POST, DELETE) will be hidden. Note that this *only* affects the UI. If write actions are a concern, Vitess operators are encouraged to also [configure vtadmin-api for role-based access control (RBAC)][rbac] if needed. | 

[cra]: https://create-react-app.dev/
[cra_env_ref]: https://create-react-app.dev/docs/adding-custom-environment-variables/
[cra_env_file_ref]: https://create-react-app.dev/docs/adding-custom-environment-variables/#adding-development-environment-variables-in-env
[operators_guide]: ../../vtadmin/operators_guide
[rbac]: ../../vtadmin/role-based-access-control
[vtadmin_env_ref]: https://github.com/vitessio/vitess/blob/main/web/vtadmin/src/react-app-env.d.ts

These environment variables are automatically [filled in by create-react-app](https://create-react-app.dev/docs/adding-custom-environment-variables/#:~:text=By%20default%20you%20will%20have,by%20inspecting%20your%20app's%20files.) and you do not have to provide them. They are available in the `process.env` object at run time, and listed here for full coverage of environment variables:

| Name | Type | Default | Definition |
| -------- | --------- | --------- | --------- |
| `NODE_ENV` | string | "production", "staging", or "test" | The current node environment set by create-react-app | 
| `PUBLIC_URL` | string | - | The path to the `public` folder within the build files |
