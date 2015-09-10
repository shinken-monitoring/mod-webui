# Contributing

## Report a bug

* First check if the problem is not yet referenced in the project issues (https://github.com/shinken-monitoring/mod-webui/issues)
* Create an issue with: 

   - an helpful title - use descriptive keywords in the title and body so others can find your bug (avoiding duplicates).
   - a precise description - steps to reproduce the problem, with actual vs. expected results
   - specify : WebUI Version, OS version, Web browser and version

> Screen shots are very helpful if you're seeing an error message or a UI display problem. (Just drag an image into the issue description field to include it).

## Contributing

Mainly inspired by this model: http://nvie.com/posts/a-successful-git-branching-model/

### Main development rules

We maintain two main branches with an infinite lifetime: 
- The `master` branch always reflects a production-ready state.
- The `develop` branch always reflects a state with the latest delivered development changes.

When the source code in the develop branch reaches a stable point and is ready to be released, all of the changes are merged back into master and tagged with a release number. 

### Working on a new feature

Feature branches are used to develop new features. When starting development of a feature, a new branch is created from the `develop` branch.

When the feature is tested and ready for delivery, the feature branch may be merged back into the develop branch to definitely add the feature to the upcoming release.


### Simple modifications

Very simple modifications such as typos, comments, ... may be committed directly in the develop branch. This should be strictly limited to modifications that do not impact application behaviour.


### Fixing an issue

Fixing an issue uses the same work-flow as developing a new feature. An issue branch is created and then merged back into develop, so that future releases also contain these bug fixes.


### Hot-fixes

When a critical bug in a production version must be resolved immediately, a hot-fix branch may be branched off from the corresponding tag on the master branch that marks the production version.

When finished, the hot-fix branch needs to be merged back into master, but also needs to be merged back into develop, in order to safeguard that the bug fix is included in the next release as well.


### Releasing a version

When we decide to release a version, the `develop` branch is tagged with a pre-release version number. When the version is considered stable enough to become a production version, the develop branch is merged into the master branch and tagged with a version number.

