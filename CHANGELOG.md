# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Fixing GitHub config for creating Changelog PR.

### Changed

- Changed the Tags trigger to include "v*" but still exclude "*-*"

## [v0.91.6] - 2019-10-11

### Added

- Packaging module to nupkg
- Adding Auto-creation of GitHub PR for Changelog update on release

### Changed

- for changes in existing functionality.
- changed continuous deployment to continuous delivery in gitversion
- extracted GitHub functions into separate file

### Deprecated

- for soon-to-be removed features.

### Security

- in case of vulnerabilities.

### Fixed

- Fixing Create ChangeLog PR Get-Variable
- fixing versioning by reverting to gitversions' continuousDeployment mode
- fixed #22: marking github releases as pre-release when there's a PreReleaseTag
- fix call to add assets to GH release.
- for any bug fixes.

### Removed

- for now removed features.

## [v0.0.1] - 2019-10-04

### Added

- dummy release for example
