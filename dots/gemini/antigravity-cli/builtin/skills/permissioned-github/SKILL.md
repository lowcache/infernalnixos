---
name: permissioned-github
description: Guidelines for interacting with GitHub and request permissions from the user when commands fail due to restrictions in the agent environment.
---

# GitHub Skill

This skill describes how to interact with GitHub and request the permissions to perform actions that are not authorized by default in the agent environment.
This skill is authoritative for the usage of the **gh** CLI and **git** command.

By default, the agent is restricted to performing only a subset of actions on GitHub.


## How to Interact with GitHub

To perform actions on GitHub:

* Use the **gh** CLI. Always set the `-R ORG/REPO` argument.
* Do not use other commmands like curl. 
* Do not write scripts to interact with the GitHub API servers directly.

To perform branch operations (e.g., push):

* Use the **git** command.

## Asking for Permissions

## Permission Format

The permission format is as follows: 

```shell
gh.<action>(<resource_json>)
```

resource_json has the following fields:

- org: Mandatory GitHub organization. Use '*' to indicate all organizations.
- repo: Mandatory GitHub repository. Use '*' to indicate all repositories.
- pr: Optional pull request number. Use '*' to indicate all pull requests.
  Supported actions:
    - read
    - create
    - update: to comment, review, edit, close, reopen, etc.
    - approve
    - merge
- issue: Optional issue number. Use '*' to indicate all issues.
  Supported actions:
    - read
    - create
    - update: to comment, review, edit, close, reopen, etc.

**Other resources are not supported and the corresponding permission will not be granted.**

## Examples

### Example 1: Creating an Issue

Command: `gh issue create --title "Bug report" --body "Description" -R myorg/myrepo`
Permission: `gh.create({"org": "myorg", "repo": "myrepo", "issue": "*"})`

*Note: keep the permission lean and don't populate empty fields*

### Example 2: Commenting on a PR

Command: `gh pr comment 123 --body "Looks good" -R myorg/myrepo`
Permission: `gh.update({"org": "myorg", "repo": "myrepo", "pr": "123"})`

*Note: keep the permission lean and don't populate empty fields*

### Example 3: Closing an Issue

Command: `gh issue close 123 --comment "closing issue" -R myorg/myrepo`
Permission: `gh.update({"org": "myorg", "repo": "myrepo", "issue": "123"})`

*Note: keep the permission lean and don't populate empty fields*

### Example 4: Approving a PR

Command: `gh pr review 123 --approve --body "Looks good" -R myorg/myrepo`
Permission: `gh.approve({"org": "myorg", "repo": "myrepo", "pr": "123"})`

*Note: keep the permission lean and don't populate empty fields*


## How and When to Ask for Permissions

**You should only ask for permissions if the command failed. Each time you ask for a permission, it will prompt the user. Be mindful to only ask when you know the command fails to provide a good user experience.**

When you have determined that you need permisison:

1. Constuct the permission string <permission-string> as per previous section.
2. Call the tool `ask_permission`:
  - Set Action="custom", Target=<permission-string>
  - Do not set BypassSandbox.
3. Run the original command that was denied.

**Never try to pipe or redirect output of the gh command, it will not work in your environment**
