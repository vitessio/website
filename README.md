# The Vitess website

[![Netlify Status](https://api.netlify.com/api/v1/badges/c27ea8e4-51d5-41b5-abfd-0597410506a3/deploy-status)](https://app.netlify.com/sites/vitess/deploys)


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

### Adding a new learning resources filter option

To add a new filter option, simply follow these steps:

1. Navigate to `resources.yaml` file to annotate: `cd data/resources.yaml`.
2. add your new filter option to all the data in the folder.

```
  - youtube: uRB-Qni_bCM
    title: "Vitess: Introduction, New Features and the Vinted User Story - Florent Poinsard, Deepthi Sigireddi, PlanetScale & Kazimieras Aliulis, Vinted"
    date: 2024
    type: video
    FILTER_NAME = "filter_value"
```

Replace FILTER_NAME with any desired name of your choice. Same applies to the value.

3. Navigate to the `index.searchindex.json` file to edit: `cd layouts/_default/index.searchindex.json`.
4. Open the file and go down to line 3. You will notice the format of the data represented in a key/value pair. Just before the closing parenthesis, append your new option like this: `"FILTER_NAME" $resources.FILTER_NAME`.

Replace FILTER_NAME with the same name represented in the frontmatter (see step 2 above for reference).

5. Head over to `config.toml` file. In the `params.lunr` section, you will see two arrays named `vars` and `params`. Add your new filter option's name to each of the arrays:

```toml
vars = ["title", "summary", "date", "publishdate", "expirydate", "permalink", "FILTER_NAME"]
```

6. Navigate to `javascript.html` and scroll down to where the logic for resource filter is declared. Within that scope, find where the `lunr()` function is being called. You will notice a callback function is being passed to the `lunr()` function. Within the callback function, you will also notice `this.field` being called with some values passed in. Append this block of code right after the last `this.field` function call:

```javascript
this.field("FILTER_NAME");
```

Replace FILTER_NAME with the same name represented in the frontmatter (see step 2 above for reference).

1. Navigate to `layouts/partials/learning-resources/filter-panel.html`. Locate the div with a class name of `filter`. Within the div, add this new block:

```html
<div class="mt-5">
      <h5>FILTER_NAME</h5>
      {{ $resources := $.Site.Data.resources.resources }}
      {{ $FILTER_NAMe := slice }}
      {{ range $resources }}
          {{ $FILTER_NAME = $years | append .FILTER_NAME }}
          {{ $FILTER_NAME = uniq $FILTER_NAME }}
      {{ end }}
      {{ range $FILTER_NAME }}
      {{ $filter := . }}
       <div>
          <input id="{{ . }}" type="checkbox" name="resource_filter" value="{{ . }}">
          <label for="{{ . }}">{{ . }}</label>
      </div>
      {{ end }}
  </div>
```

Replace FILTER_NAME with the same name represented in the frontmatter (see step 2 above for reference).

8. Save your changes and rebuild your frontend.

# Releasing a new version of the documentation

To release a new version of the documentation you can use one of the following two scripts:

- `./tools/rc_release.sh`: for RC release.
  - Takes one argument, the number of the next release.
  - Usage when releasing v16.0.0-rc1: `./tools/rc_release.sh "17"`


- `./tools/ga_release.sh`: when a version becomes GA.
  - Takes one argument too, the number of the version we are making GA.
  - Usage when releasing v16.0.0 GA: `./tools/ga_release.sh "16"`
