# Welcome to maktoobgar contributing guide

Thank you for investing your time in contributing to our project! :sparkles:. 

Read our [Code of Conduct](/CODE_OF_CONDUCT.md) to keep our community approachable and respectable.

In this guide you will get an overview of the contribution workflow from opening an issue, creating a PR, reviewing, and merging the PR.

Use the table of contents icon <img src="./images/table-of-contents.png" width="25" height="25" /> on the top left corner of this document to get to a specific section of this guide quickly.

## New contributor guide

To get an overview of the project, read the [README](/README.md).

## Contributor setup

Install requirements for contributing:
1. Please install python3 on your system. (It is needed for scripts to format your commit messages and handle [CHANGELOG.rst](/CHANGELOG.rst) file)
2. Install venv module for python (linux users only):
   - `sudo apt-get install python3-venv`
3. Run this command in your terminal when you are in project directory:
   - `python3 -m venv env`
4. Run `install.py` script:
   - `./.githooks/install.py`

### Issues

#### Create a new issue

1. **Bug**: If you spot a problem with a certain release or a problem in develop branch, search if the [issue already exists](https://github.com/maktoobgar/scene_manager/issues). If a related issue doesn't exist, you can open a new issue using **Bug Report** form in [issue form](https://github.com/maktoobgar/scene_manager/issues/new/choose) section.
2. **Feature**: If you want to add a new functionality to the project (which you can find new functionalities that we still don't support, in [lodash documentation](https://lodash.com/docs/latest)), or you have a feature idea of your own, first look up in [issues](https://github.com/maktoobgar/scene_manager/issues) and if a duplicate issue does not already exist, that means possibly (Take a look at [Picking An Issue](#picking-an-issue)) no one is working on it and you can create a **Feature Issue** from [issue form](https://github.com/maktoobgar/scene_manager/issues/new/choose) section.

#### Picking an issue

If you just created an issue and you want to work on it by yourself, just mention it in the issue form that you handle it yourself or say it in comments.

If there is an issue in [issues](https://github.com/maktoobgar/scene_manager/issues) section that interests you, look up in issue description or comments if any one got the job and if not, you can write in the comments which you are working on it and that issue is yours for about a week after that.

After a week if you didn't create a pull request, anyone else can pick it up and that issue is not your's anymore.

### Make changes

**Note**: This workflow is designed based on git flow but please read till the end before doing anything.
1. [Pick or create a **feature** or **bug** issue](#issues).
2. Fork the repository.
3. Then you should create a branch:
   - If you found a bug on a **release** branch, create a new branch based on that **release** branch with a name like:
     - `bugfix/<issue number>`
   - If you found a bug on **main** branch, create a new branch based on **main** branch with a name like:
     - `hotfix/<issue number>`
   - If you want to contribute a new feature into the project, create a new branch based on **develop** branch with a name like:
     - `feature/<issue number>`
4. Make your changes locally.
5. Test and debug your changes.
   - **Important**: If you contributed a **feature**, make sure to write a **test case** and a **benchmark** for that new feature function.
   - If you don't provide **test case** and **benchmark** functions for your new provided feature, we sadly can't accept your contribution.
6. Add documentation for your new functions, interfaces and etc new things you added.
7.  If you are sure of your code, commit and push your changes (there are rules for commits in [Commit message guidelines](#commit-message-guidelines) section, have a look)
8.  Create a pull request and **mention** your issue number inside the pull request.
9.  Wait for the review:
   1.  We may ask you in review to add or change your code for a reason or mention you forgot to do something, If you provide the changes we asked, comeback and inform us about the changes and thanks for your contribution, we appreciate it. ✨
   2.  If the review passed and pull request happened, thank you. we are happy to have you and between us. ✨
   3.  If the review rejected, we will inform you about the reason for sure.

So in summary:
1. Pick or create a feature or bug issue.
2. Fork the repository.
3. Create a new branch by what just said in number 3 of top list.
4. Do the changes. (if you added new feature, don't forget to add test case and benchmark for that)
5. Debug and be sure about the changes.
6. Add documentation for new functions and variables and any other new things you provided.
7. Commit and push your changes. (see [commit message guidelines](#commit-message-guidelines))
8. Create a pull request and **mention** your issue number inside the pull request.

### Changelog

**Never** touch or change the file and let the script handle it.

### Commit message guidelines

There is a template for how to commit:

- **\<type>(\<scope>): \<subject>**

Samples:

```
docs(changelog): update changelog to beta.5
```

#### Type (Essential)

* docs: Documentation only changes
* feat: A new feature
* fix: A bug fix
* perf: A code change that improves performance
* refactor: A code change that neither fixes a bug nor adds a feature
* style: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
* test: Adding missing tests or correcting existing tests

#### Scope (Optional)

This section can be written in two formats:
1. (\<package>-\<function>)
2. (\<file,description...>)

**Note**: If you don't specify this part, remove parenthesis too.

#### Subject (Essential)

A brief description about what just happened.

## Versioning (Extra Section)

This is just a reminder for us to know what versioning system we are using.

Versioning in this project is based on semantic versioning:

v**Major**.**Minor**.**Patch**-**PreReleaseIdentifier**

Example:
- v1.4.0-beta.1

### Major Version

Signals backward-incompatible changes in a module’s public API. This release carries no guarantee that it will be backward compatible with preceding major versions.

### Minor Version

Signals backward-compatible changes to the module’s public API. This release guarantees backward compatibility and stability.

### Patch Version

Signals changes that don’t affect the module’s public API or its dependencies. This release guarantees backward compatibility and stability.

### Pre-release Version

Signals that this is a pre-release milestone, such as an alpha or beta. This release carries no stability guarantees.

### More information

For more information about versioning, read [this](https://go.dev/doc/modules/version-numbers).