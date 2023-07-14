# Design

Background and design principles of an Action that supports releases driven by [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## Motivation & requirements

There is a need for an easy to use, security-hardened Action that allows to

* generate new releases driven by Conventional Commits or
* opt in for manually triggered releases (tag pushes; without having to change the whole workflow when switching from one practice to the other) and to
* delegate the actual release build to the rest of the GitHub job in order to
* be able to use the same workflow/job definition for both pull request and release builds (to detect release problems early and because of DRY) and to
* validate commits within pull requests implicitly


## Prior work

This section lists several existing tools designed to solve this problem.

### semantic-release

[semantic-release](https://github.com/semantic-release/semantic-release) is a full-featured version generator and conditional releaser that can be enhanced with plugins written in JavaScript.
There are plugins to execute a build process depending on whether it is a release run, to create and push a git commit and tag as well as to create a GitHub release.
It is also shipped as [GitHub Action](https://github.com/cycjimmy/semantic-release-action).

This tool allows to implement a release workflow that is close to the ideal but

* it requires the workflow to be implemented differently for the release than for the pull request,
* it doesn't allow to use subsequent workflow/job steps to contribute to the release build before publishing the new version and
* a release build failure requires manual intervention by removing the tag of the failed release.

### go-semantic-release

[go-semantic-release](https://github.com/go-semantic-release/semantic-release) is a semantic-release reimplementation in Go.

### get-next-version

[get-next-version](https://github.com/thenativeweb/get-next-version) is a simple CLI to derive the next release version from Conventional Commits.

However, it does not support commit message validation and changelog generation.

### sv4git

[sv4git](https://github.com/bvieira/sv4git) (`git-sv`) is a CLI (and git plugin) to generate a release version and changelog as well as for validating commit messages.

This tool provides the building blocks for an Action.


## Security considerations

To reduce the attack surface, the git credentials/token should not be exposed to (build and test) code/scripts that do not need it.

To achieve this, the following requirements must be met:

* The actions/checkout Action must be configured not to persist credentials (needs to be done by the user within her workflow).
* Prevent build/test steps from injecting malicious code via git credential helper by configuring it within the post-build step.
* Scripts within the home directory such as `~/.bashrc` cannot be manipulated by previous container steps since GHA mounts a separate home directory into the Action that differs from the directory available to regular workflow steps. (To be 100% sure a binary could be built to push the git tag without running a shell.)
