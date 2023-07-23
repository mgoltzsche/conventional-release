# conventional-release ![main branch workflow](https://github.com/mgoltzsche/conventional-release/actions/workflows/workflow.yaml/badge.svg?branch=main)

A GitHub Action to automate releases based on [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) using [sv4git](https://github.com/bvieira/sv4git).

## Features

* Supports fully automated releases driven by Conventional Commits.
* Allows to disable automated versioning in favour of manually pushing tags (`auto-release: false`).
* Enforces [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) format within commit messages.
* Recovers from a failed release build automatically (when the next commit is pushed).
* Allows to use the same workflow/job definition for both pull request and release builds.
* Fails builds that leave uncommitted changes.

## Usage

To enable automated releases within your workflow, add this Action as a step after `actions/checkout` and before your actual build step(s).
For all supported Action inputs and outputs, see [`./action.yml`](./action.yml).

Please note that the releasing job needs to have write permissions for `contents` in order to push a git tag and create a GitHub release.
In case of pull request builds, the token still provides read-only access this way.
Correspondingly the `actions/checkout` Action should be configured with `persist-credentials: false`.

Please also note that the `actions/checkout` Action must be configured with `fetch-depth: 0` to work with the release Action.

To run subsequent steps conditionally depending on whether it is a release build, use the Action output `publish` as condition.
(In case of a release build, a git tag is pushed and a GitHub release created by the Action's post-entrypoint only after all steps within the job succeeded.)

Corresponding to its outputs, the Action exports the following environment variables to subsequent steps:

* `RELEASE_VERSION`: The semantic version (or manually pushed tag) of the release without leading `v`. During non-release builds this holds the next version with a `-dev-<SHA>` suffix.
* `RELEASE_PUBLISH`: Is `true` when release build, otherwise empty.

### Example workflow

A workflow that creates releases based on commits on the main branch automatically and that validates pull requests can look as follows:

```yaml
name: Build and release

on:
  push:
    branches:
    - main
  pull_request:
    branches:
    - main

concurrency: # Run release builds sequentially, cancel outdated PR builds
  group: ci-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}

permissions: # Grant write access to github.token within non-pull_request builds
  contents: write

jobs:
  build:
    name: Build
    runs-on: ubuntu-latest

    steps:
    - name: Check out code
      uses: actions/checkout@v3
      with:
        fetch-depth: 0
        persist-credentials: false

    - id: release
      name: Prepare release
      uses: mgoltzsche/conventional-release@v1
      with:
        token: ${{ github.token }}

    # ... Build artifact ...

    - name: Publish artifact
      if: steps.release.outputs.publish # To run only when release build
      run: |
        set -u
        echo Publishing $RELEASE_VERSION
        ...
```

The [workflow used to publish this Action](./.github/workflows/workflow.yaml) is another example that shows how to release a container image, add a release commit and force-push a major version tag.

## Design considerations

See [design considerations](./DESIGN.md).
