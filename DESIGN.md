# Design

Background and design principles of an Action that supports releases driven by [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## Motivation & requirements

There is a need for an easy to use Action that allows to

* generate new releases driven by Conventional Commits or
* opt in for manually triggered releases (tag pushes; without having to change the whole workflow when switching from one practice to the other) and to
* delegate the actual release build to the rest of the GitHub job in order to
* be able to use the same workflow/job definition for both pull request and release builds (to detect release problems early and because of DRY) and to
* validate commit messages also within pull requests implicitly and
* fail builds that leave uncommitted changes.

...basically everything release-related that is not worth maintaining in a Makefile.

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

Embracing open source and collaboration across the globe also increases the risk of supply chain attacks.
This is particularly true when developing automation that executes 3rd party code.
We have to take into account that a library or tool used within our CI build/test process may contain malicious code at some point and/or that an attacker tries to submit malicious code into our codebase and automation via a pull request.
We cannot protect ourselves from that 100% but we can mitigate risks and set up hurdles - security concepts are layered like an onion.
GitHub's default repository settings prevent our workflows from being run with code submitted by anybody's pull request, unless the repository owner grants the execution explicitly or trusts the author.
Hence, we can and should limit who can run our workflows.
Now we need to always pay full attention when reviewing the code unknown pull request authors are submitting before allowing them to run it.
However, we are humans and it is not always possible during the daily routine.
Due to this reason, pull request workflows should not have access to credentials with write access and fortunately that is the default configuration within GitHub.
However, there is still the good chance that malicious code ends up being executed within our workflow (after pr merge) and shipped to our users.
In that case we have to reduce the blast radius and at least have visibility within the git history what code is shipped exactly instead of letting an attacker inject malicious code into artifacts without any transparency within the git history.
For this reason, every workflow step should receive only the minimal permissions it needs and we have to be particularly cautious when granting write permissions to workflows.

To be able to push a git tag, the Action requires the GitHub token (`github.token`) to have write permissions (by declaring that within the calling workflow and explicitly passing the token to the Action via an input).
To reduce the attack surface, the GitHub token should not be exposed to (build/test) code/scripts that do not need it.
Though, since all regular workflow steps are run using the same user (UID 1001) and with access to the same shared directories, they can basically all access the GitHub token if it was passed to one of the steps within the same job (by either obtaining the token from the file system or inject malicious code into a script that a subsequently run step with privileges executes).
An Action has little means to protect its state from non-docker steps run within the same job:
To prevent build/test steps from injecting malicious code into the git credential helper in order to obtain the token, this Action writes the credential helper configuration within the post-build step, directly before using it.

Thus, it is up to the workflow author really to reduce security risks by applying the following practices:

* The actions/checkout Action must be configured not to persist credentials within the workspace.
* Prevent workflow steps that don't need to use credentials (build/test) from accessing them by e.g. not storing credentials within the home directory and workspace at all or by running those steps within a container (e.g. using `uses: docker://<image>` or as dockerized Action) since containerized steps don't get the same home directory mounted as the other workflow steps.
