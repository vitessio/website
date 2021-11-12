# The Vitess website

This repo houses the assets used to build the website at https://vitess.io.

## Running the site locally

To run the website locally, you need to have the "extended" version of the [Hugo](https://gohugo.io) static site generator installed (installation instructions [here](https://gohugo.io/getting-started/installing/)). Installing the Hugo version in [netlify.toml](./netlify.toml) is recommended.

Once Hugo is installed you will need to install `npm` or `yarn` and fetch the dependencies in the git directory:

```bash
cd website
npm install
```

or

```bash
cd website
yarn
```

You are now ready to startup the hugo server:

```bash
hugo server --buildDrafts --buildFuture
```

This starts Hugo in local mode. You can see access the site at http://localhost:1313.


## Adding a user logo

If you'd like to add your logo to the [Who uses Vitess](https://vitess.io/#who-uses) section of the website, add a PNG, JPEG, or SVG of your logo to the [`static/img/logos/users`](./static/img/logos/users) directory in this repo and submit a pull request with your change. Name the image file something that reflects your company (e.g., if your company is called Acme, name the image `acme.png`).

## Link checking

You can check the site's internal links by running `make check-internal-links` and all links—internal *and* external—by running `make check-all-links`.

## CSS/SASS

The Vitess website uses [Bulma](https://bulma.io/), a CSS (and SASS) framework that provides all kinds of variables, utilities, and components. 

**⚠ If you are running Hugo locally and your .sass file changes are not getting picked up:** make sure you have [installed the "extended" version](https://gohugo.io/getting-started/installing/) of the `hugo` binary. 
