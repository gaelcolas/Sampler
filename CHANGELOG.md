# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.105.0] - 2020-04-21

### Added

- Add new build task `Generate_Wiki_Content` for the DSC Community module type.

### Changed

- Update the repository to always use the latest version of the module
  `ModuleBuilder`.
  
### Fixed

- Now the prerelease is cleaned so that it does not contain any dashes by
  removing any suffix after a dash, for example `pr054-0012' will be changed
  to just `pr054' as the prerelease string. This is due to a bug in the
  cmdlet `Publish-Module` together with a newer version of the module
  `ModuleBuilder`.

## [0.104.0] - 2020-04-18

### Removed

- It no longer updates the module manifest release notes in the task
  `publish_module_to_gallery`, because that is already done in the task
  `create_changelog_release_output` that is run in the build step. The
  task `publish_module_to_gallery` was still dependent on the task
  `create_changelog_release_output` was run for it to be able to update
  the release notes in the module manifest, so `publish_module_to_gallery`
  could never have been run independent of task `create_changelog_release_output`.

### Changed

- The regular expression for `minor-version-bump-message` in the file
  `GitVersion.yml` was changed to only raise minor version when the
  commit message contain the word `add`, `adds`, `minor`, `feature`,
  or `features`.

### Fixed

- Correctly evaluate the module version in task `publish_module_to_gallery`.

## [0.103.0] - 2020-04-17

### Fixed

- Now the module manifest release notes is only updated with the latest release.
  This fixes the issue with the limitation for the release notes in the module
  manifest when releasing a module to PowerShell Gallery. If all the change log
  entries for the latest release still exceed the max hard limit then the release
  notes will be truncated to the max hard limit.
- The CI pipeline was updated with working build images.

## [0.102.1] - 2020-02-21

### Changed

- Changed build tasks to use the helper function `Get-ModuleVersion` to
  reduce code duplication.
- Changed each build task so that the default value of the parameter
  `ModuleVersion` always returns the sematic version (x.y.z-prerelease),
  and not the informational version ([issue #130](https://github.com/gaelcolas/Sampler/issues/130)).

## [0.102.0] - 2020-02-14

### Added

- Added the functionality to merge multiple JaCoCo code coverage files into one file.

## [0.101.0] - 2020-02-10

### Changed

- Added warning messages to all build task if the task couldn't be imported
  because of an invalid PSD1 file.
- `build.ps1` will now dynamically determine the build configuration if
  not specified via the `-BuildConfig` parameter.
- Updated the PesterScript parameter to allow the specification of hastables,
  to enable specifying parameters to Pester.
  
### Added

- Add conceptual build step for DSC resources [issue #122](https://github.com/gaelcolas/Sampler/issues/122).

## [0.100.0] - 2020-02-01

### Added

- Added the option to specify `CodeCoverageOutputFile` and `CodeCoverageOutputFileEncoding`
  in the file `build.yml`. For example if a code coverage provider need the
  file to be named in a certain way.

### Changed

- Added new common functions for build tasks to reduce code duplication.

## [0.99.4] - 2020-01-22

### Changed

- Removed Azure-Pipelines.yml on simple module type.
- Ensuring Pester version above 4.0 is used and loaded.
- build.yaml, RequiredModules.psd1 and Resolve-Dependency.psd1 are now templated
assets with conditional content.
- HQRM tests to run only when using the dsccommunity module type.
- Updated simple module to not contain sample scripts & tests.
- supports setting CustomRepo to pull dependencies from a private gallery
 other than PSGallery.
- Update the plaster template to replace 'synedgy' with 'dsccommunity' if
  the module type is 'dsccommunity'.
  
## [0.99.3] - 2020-01-21

### Changed

- The deploy step is no longer run if the Azure DevOps organization URL
  does not contain 'synedgy'.
  
## [0.99.2] - 2020-01-16

### Added

- VSCode template setting `pipelineIndentationStyle`.

## [0.99.1] - 2020-01-16

### Fixed

- Update GitVersion.yml with the correct regular expression.
- Fix casing in key names in `azure-pipelines.yml`.

### Changed

- Set a display name on all the jobs and tasks in the CI pipeline.
- Azure Pipelines will no longer trigger on changes to just the CHANGELOG.md.

## [0.99.0] - 2020-01-01

### Changed

- Updated `build.ps1` to add DscTestTag, DscTestExcludeTag parameters.
- Updated module manifest to support PS 5.0.
- updated Contributing.md to redirect to dsccommunity.org
- Set `testRunTitle` for PublishTestResults steps in `azure-pipelines.yml`
  so that a helpful name is displayed in Azure DevOps for each test run.
- Removed unnecessary comments from `azure-pipelines.yml`.

## [0.98.1] - 2019-12-24

### Fixed

- Fixing the codecoverage threshold issues reported by Daniel (As param set to 0 should not bypass).

### Removed

- Removing QA tests from dsccommunity template.

## [0.98.0] - 2019-12-22

### Added

- Added Module manifest in build.psd1 template to fix issue resolving Project on linux.
- Added DSC Resources & Supporting modules (including one from PSGallery, one from source).
- Added PesterScript parameter in Build.ps1 so that it can be overridden at runtime (in azure-pipelines.yml).
- Added `Modules` commented out to the `build.yml`
- Added CodeCoverageThreshold parameter to fail when under threshold
  (configurable in `build.yaml`). Will skip all code coverage when set to 0
  (build.ps1 parameter override build.yml config).
- Added Tasks.json with build and test tasks.
  (VSCode bug when you click on Problems, Integrated terminal crashes).

### Changed

- Made Code Coverage threshold to load from config file, and be skipped completely if set to 0 or absent.
- Updating Code of Conduct to the DSC Community one.

### Fixed

- Made build.ps1 & Resolve-Dependency.ps1 compliant with DSC Style guidelines
- removed unnecessary file from Plaster template

## [0.96.0] - 2019-11-01

### Fixed

- Fixed when the SourcePath is not enough for finding ModuleManifest (ModuleBuilder bug)

## [0.95.1] - 2019-11-01

### Changed

- Updating QA tests function discovery to look within loaded module

## [0.95.0] - 2019-11-01

### Added

- Support for Pester parameter in Config File
- Making Plaster Template Discoverable by Get-PlasterTemplate -IncludeInstalledModules

## [0.93.2] - 2019-10-30

### Fixed

- Template not including RootModule anymore
- Uncomment ReleaseNotes from module manifest before updating
- Skip Changelog test when not in a git repo

## [0.93.1] - 2019-10-29

### Added

- Shields badge on the readme page
- Release notes to module manifest

### Changed

- Changelog compiled to release notes
- use release notes for publishing to GH

### Fixed

- fixed template
- fixed the publishing to also pack Nupkg
- Added hidden files as template assets
- fixed git test to skip test on new module scaffolding
- fixed default DscResources from copy-item in build yaml

### Removed

- old file reference with wrong case
- remove kitchen yaml from template

## [v0.92.2] - 2019-10-15

### Fixed

- Add condition to trigger deployment stage when building a tag (not master)

## [v0.92.0] - 2019-10-15

### Fixed

- Fixing GitHub config for creating Changelog PR

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
