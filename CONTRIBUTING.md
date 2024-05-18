# Contributing to Vitess

We're thrilled that you want to contribute! 😊 Vitess is built by the community, and we warmly welcome your help. There are many ways you can contribute, and every contribution is appreciated. Check out the information below to learn more about how you can get involved. 🚀

- [Before You Get Started](#before-you-get-started)
- [How to Contribute](#how-to-contribute)
  - [Prerequisites](#prerequisites)
  - [Set Up Your Local Development Environment](#set-up-your-local-development-environment)


## Before You Get Started

### For Newcomers


To get you started with contributing to Vitess projects, check out the Vitess Newcomers Guide. It's designed to make it easier for newcomers like you to contribute. You'll find resources and tutorials there to help you get started on your contributions.

### Issues

#### Creating an Issue

Before creating a new issue for features, bugs, documentation or improvements please follow these steps:


1. **Look for Existing Issues:** Check if the issue you're thinking of is already there.
2. **Start a New Issue:** If it's not there, create a new one. Give lots of details and pick the right type (like a bug, document, feature, or improvement).
3. **Show Interest in Fixing the Issue:** If you want to work on it once it's checked, mention that in your issue description.

These steps help vitess project organized and efficient.

#### Working on an Issue

Before you start working on an issue, please follow these steps:

1. **Ask to be Assigned**: Comment on the issue to request that it be assigned to you.
2. **Get Ready**:
   - Read the CONTRIBUTING.md file.
   - Make sure you can build and run the project on your computer.
   - Explain in your comment how you plan to solve the issue.
3. **Wait for Assignment**: Only start working on the issue after it has been assigned to you. This helps avoid confusion and duplicate work.
4. **Reference the Issue**: In your Pull Request (PR), mention the issue (e.g., "This PR fixes #1234") to automatically close it when your PR is merged.

Following these steps helps keep everything organized and running smoothly.

## How to Contribute

### Prerequisites

- Ensure you have `npm` installed.
- Familiarize yourself with the project's structure and guidelines by reading the CONTRIBUTING.md file.



### Set up your Local Development Environment for Vitess

**1.** Fork [this](https://github.com/vitessio/website) repository.

**2.** Clone your forked copy of the project.

```
git clone  https://github.com/<your-username>/vitess.git
```

**3.** Navigate to the project directory.

```
cd website
```

**4.** Add a reference(remote) to the original repository.

```
git remote add upstream   https://github.com/vitessio/website
```

**5.** Check the remotes for this repository.

```
git remote -v
```

**6.** Regularly pull updates from the upstream repository to your master branch to ensure it stays synchronized with the main project's latest changes.




```
git pull upstream master
```

**7.** Create a new branch.

```
git checkout -b <your_branch_name>
```

**8.** Install the dependencies for running the site.

```
make setup
```

**9.** Make the desired changes.

**10.** Run the site locally to preview changes.

```
make site
```


**11.** Track your changes.

```
git add .
```

**12.** Commit your changes. 

```
git commit -m "<commit subject>"
```



**13.** While you are working on your branch, other developers may update the `prod` branch with their branch. This action means your branch is now out of date with the `prod` branch and missing content. So to fetch the new changes, follow along:

```
git checkout master
git fetch origin master
git merge upstream/master
git push origin
```

Now you need to merge the `prod` branch into your branch. This can be done in the following way:

```
git checkout <your_branch_name>
git merge master
```

**14.** Push the committed changes in your feature branch to your remote repo.

```
git push -u origin <your_branch_name>

```
**15.** After committing and pushing your changes to GitHub, navigate to your forked repository's page and choose your development branch. Click on the "Pull Request" button. Make sure you're comparing your feature branch correctly with the target branch in the repository you're targeting for the pull request. If adjustments are needed, simply push the updates to GitHub. Your pull request will automatically sync with changes in your development branch.  