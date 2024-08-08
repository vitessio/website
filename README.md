# The Vitess website

[![Netlify Status](https://api.netlify.com/api/v1/badges/c27ea8e4-51d5-41b5-abfd-0597410506a3/deploy-status)](https://app.netlify.com/sites/vitess/deploys)


[![Slack](https://img.shields.io/badge/Slack-4A154B?style=for-the-badge&logo=slack&logoColor=white)](https://vitess.slack.com/ssb/redirect)
[![X](https://img.shields.io/badge/X-000000?style=for-the-badge&logo=x&logoColor=white)](https://x.com/vitessio)
[![Stack Overflow](https://img.shields.io/badge/Stack_Overflow-FE7A16?style=for-the-badge&logo=stack-overflow&logoColor=white)](https://stackoverflow.com/search?q=vitess)


This repo houses the assets used to build the website at https://vitess.io.

## Running the site locally

First install `npm`, then fetch dependencies, including
[Hugo](https://gohugo.io) by running these commands:

```bash
cd website
npm install
```

To build a development version of the site, run the following command:

```bash
make build
```

To serve the site locally, run:

```bash
make serve
```

View the locally served site at http://localhost:1313.

## Adding a user logo

If you'd like to add your logo to the [Who uses Vitess](https://vitess.io/#who-uses) section of the website, add a PNG, JPEG, or SVG of your logo to the [`static/img/logos/users`](./static/img/logos/users) directory in this repo and submit a pull request with your change. Name the image file something that reflects your company (e.g., if your company is called Acme, name the image `acme.png`).

## Link checking

You can check the site's internal links by running `make check-internal-links` and all links—internal *and* external—by running `make check-all-links`.

## CSS/SASS

The Vitess website uses [Bulma](https://bulma.io/), a CSS (and SASS) framework that provides all kinds of variables, utilities, and components.

# Releasing a new version of the documentation

To release a new version of the documentation you can use one of the following two scripts:

- `./tools/rc_release.sh`: for RC release.
  - Takes one argument, the number of the next release.
  - Usage when releasing v16.0.0-rc1: `./tools/rc_release.sh "17"`


- `./tools/ga_release.sh`: when a version becomes GA.
  - Takes one argument too, the number of the version we are making GA.
  - Usage when releasing v16.0.0 GA: `./tools/ga_release.sh "16"`
