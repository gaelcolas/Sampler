# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- New DSC Community template (`New-SampleModule -ModuleType newDscCommunity`).

### Fixed

- Fixes #222: Adding *.dll binary to gitattributes.
- Fixes eol for file types .sh .svg .sh .mof
- Fixes #225 by asking the question or assuming the default is `main` in most cases.
- Readded the `Create_ChangeLog_GitHub_PR` task to the publish workflow and template.
- Fixes newDscCommunity template missing the psm1 and the Required modules.

### Changed

- Extracted the Common functions to be within the main Sampler module to enable re-usability.
- Updated this project's `build.ps1` to load the Private/Public *.ps1 so it can build itselves without impacting Sampler templates.
- Added empty functions' Unit test files (for subsequent PR when writing moving to Pester 5).
- Added Comment-based help for the extracted functions.
- Dropped the CodeCoverage Threshold of the project to reflect the newly discovered code (`Common.Functions.psm1` wasn't counted for code coverage).

### Removed

- Removed the GitHub functions to publish them in the `Sampler.GitHubTasks` module.

## [0.109.4] - 2021-03-06
### Added

- Added the build_guestconfiguration_packages task to create GuestConfig packages using the GuestConfiguration module.
- Added GCPackage template so that you can use `Add-Sample -Sample GCPackage` to add a GC Package to your Sampler project.
- Added the gcpack meta task to call clean, build, and build_guestconfiguration_packages for you.

## [0.109.3] - 2021-02-16

### Fixed

- Fixed bug when using `PesterScript` with the build task `Invoke_Pester_Tests`
  when running Pester 5.

### Deprecated

- Update `build.ps1` with an alias `PesterPath` for the parameter `PesterScript`
  so that repositories that move over to Pester 5 can future-proof the file
  `azure-pipelines.yml` (for example when splitting tests over several jobs).
  The parameter `PesterScript` is deprecated and will be removed when
  Pester 4 support is removed some time in the future. Change scripts to 
  `PesterPath` when migrating to Pester 5 tests.

## [0.109.2] - 2021-01-13

### Changed

- The Deploy tasks `publish_nupkg_to_gallery` and `publish_module_to_gallery`
  are now made mutually exclusive. For each deploy pipeline you must choose
  to use either one. 
  - `publish_nupkg_to_gallery` is using `nuget` to publish to the gallery.
  - `publish_module_to_gallery` is using the cmdlet `Publish-Module` to
    publish to the gallery.

### Fixed

- Fix issue in DscResourcesToExport task to properly process DscResource schema ([issue #230](https://github.com/gaelcolas/Sampler/issues/230)).
- Fix uploading of code coverage when using the DSC Community template.

## [0.109.1] - 2021-01-06

### Fixed

- Update the Readme.md to fix a few typos.
- Fix wrong resource name is added in module manifest property DscResourcesToExport
([issue #220](https://github.com/gaelcolas/Sampler/issues/220))

## [0.109.0] - 2020-11-24

### Changed

- Updating all azure-pipeline.yaml to change Build Artifacts to Pipeline Artifacts ([issue #159](https://github.com/gaelcolas/Sampler/issues/159)).
- Update plasterManifest.xml call by New-SampleModule :
  - Add section modify to replace "FunctionsToExport = '*'" by "FunctionsToExport = ''" in new module manifest ([issue #67](https://github.com/gaelcolas/Sampler/issues/67)).
  - Add section modify to add "Prerelease = ''" in "PSData" block  in new module manifest ([issue #69](https://github.com/gaelcolas/Sampler/issues/69)). 
- Changing ClassResource.
  - Add generic content in the class.
  - Add pester tests.
  - Add localizeddata.
  - Update plasterManifest.xml.
  - Add private functions.
  - Add pester tests.
  - Update Sampler integration tests.
- Changing the Reasons property in the classes based resource template. It's now NotConfigurable.
- Renamed Build_Module_ModuleBuilder task to Build_ModuleOutPut_ModuleBuilder.
  Build_Module_ModuleBuilder is now a metatask that calls
  Build_ModuleOutPut_ModuleBuilder and Build_DscResourcesToExport_ModuleBuilder tasks.

### Added

- Added new template ClassFolderResource
- Added new function Get-ClassBasedResourceName on Common.Functions.psm1 module.
  It's used to find the class-based resource defined in psm1 file.
- Added new task Build_DscResourcesToExport_ModuleBuilder.
  On build, it adds DscResources (class or Mof) in DscResourcesToExport manifest key.

### Fixed

- Fixed Test-ModuleManifest ([issue #208](https://github.com/gaelcolas/Sampler/issues/208)) 
  in tasks.

## [0.108.0] - 2020-09-14

### Added

- Added GitHub config element template.
- Added vscode config element template.
- Added a new template file for azure-pipelines.yml when using the
  module type `'dsccommunity'`.
- Added a new template and configuration for Codecov.io when using
  module type `'dsccommunity'`.

### Changed

- Renamed the moduleType 'CompleteModule' to CompleteSample.
- Updated changelog (removed folder creation on simple modules).
- Updated doc.
- Updated code style to match the DSC Community style guideline.
- Updated logic that handles the installation on PSDepend in the bootstrap
  file `Resolve-Dependency.ps1`.
- Updated year in LICENSE.
- Updated the template GitVersion.yml to use specific words to bump
  major version (previously it bumped if the word was found anywhere in
  the commit message even if it was part of for example a code variable).
- Updated the template file build.yaml to make it more clean when using
  the module type `'dsccommunity'`.
- Updated so that the module type `'dsccommunity'` will add a CHANGELOG.md.
- Updated so that the module type `'dsccommunity'` will add the GitHub templates.

### Fixed

- Fixed missing 'PSGallery' in build files when the Plaster parameter
  `CustomRepo` is not assigned a value.
- Fixed a whitespace issue in the template file Resolve-Dependency.psd1.
- Rephrased comments in the template file build.yaml.

### Removed

- Removed the CompletModule_noBuild template as it's unecessary and add complexity to the template.

## [0.107.3] - 2020-09-10

### Fixed

- Fixed the Build of template with DSC Resource by adding required modules, config & helper modules tests.
- Fixed the issue with the Publish module task (always use Publish-Module unless you want to UseNugetPush).

## [0.107.2] - 2020-09-08

### Fixed

- Fixed build error when the "Update changelog" PR is created (and no changes exists).
- Fixed when creating a Module from template and the Build.yml does not copyPaths: DscResources.

## [0.107.1] - 2020-09-08

### Fixed

- Fixed #192 where the `Build-Module` command from module builder returns a rooted path (sometimes). 

## [0.107.0] - 2020-09-07

### Added

- Added New-SampleModule command to invoke the template.
- Added Add-Sample command to invoke component templates

### Fixed

- Fixed pack action & nuget push.

## [0.106.1] - 2020-08-30

### Fixed

- Fixed `New-Release.GitHub.build.ps1` task `Create_ChangeLog_GitHub_PR` so that
  it respects `MainGitBranch` if passed.

## [0.106.0] - 2020-08-30

### Added

- Added Templates for:
    - DSC Composite
    - Class-based DSC Resource with reasons
    - MOF based DSC Resource and tests
    - Private Function and tests
    - Public Function and tests
    - Public function calling a Private function and tests
    - Classes and tests
    - Enum
- Added integration tests for the Plaster templates.
- Added support to use an alternate name for the trunk branch in
  `New-Release.GitHub.build.ps1` ([issue #182](https://github.com/gaelcolas/Sampler/issues/182)).
- Added additional log output to `New-Release.GitHub.build.ps1`.
- Corrected markdown format in CHANGELOG.md to remove linting messages.

### Fixed

- Removing main module's BOM from built PSM1 when built in Windows PowerShell.
- Resolve-Dependency when running in vscode and PS7 is installed.
- Fixed `module.tests.ps1` to be able to run locally.

### Removed

- Duplicate integration test for template.

## [0.105.6] - 2020-06-01

- Added fix to support Pester 4 parameters.

## [0.105.5] - 2020-05-29

### Fixed

- Fix for Pester 5.0.1 making sure only to use the `Simple` ParameterSet.
- Fix typo in `DscResource.Test` task.
- Updated style in `generateHelp.PlatyPS` task.

## [0.105.4] - 2020-05-29

### Fixed

- Added Pester 5 support in the CI pipeline `test` and `hqrmtest` task.
- Pinned the module Pester to v4.10.1 in the file `RequiredModule.psd1`
  until this repo is converted to Pester 5.
- Update build task to pass the full path to the module manifest to
  `Build-Module` to be able to build without a build manifest.
- Remove the build manifest from Sampler and Plaster template.
- Change the build.yaml to use `CopyPaths` instead of `CopyDirectories`.

## [0.105.3] - 2020-05-09

### Removed

- Removed not needed attempt to use ModuleBuilder's build manifest (build.psd1)
  from the build task. It was trying to determine the source path by using
  the `SourcePath` property from the build manifest. But since the build
  manifest is in the source path the source path must already be known
  to be able to import the build manifest. Catch 22. The code also wrongly
  assumed that the `SourcePath` needed to include the module manifest file
  which it should not since that is determined by ModuleBuilder using
  the source path as base path.

## [0.105.2] - 2020-05-01

### Fixed

- Updated README.md with a section `Task Variables` and described each of
  the build task `Build-Module.ModuleBuilder`'s task variables.
- When there are multiple module manifest found in the repository the build
  now fails with a a better error error message ([issue #155](https://github.com/gaelcolas/Sampler/issues/155)).
- Now the the module does not export the helper function modules as tasks
  aliases ([issue #161](https://github.com/gaelcolas/Sampler/issues/161)).
- Fixed so module version can be detected using GitVersion on macOS and
  Linux.

### Changed

- Update tasks to reduce code duplication ([issue #125](https://github.com/gaelcolas/Sampler/issues/125)).
- Task 'Merge_CodeCoverage_Files' did not use the parameter `ProjectName`
  to that parameter was removed.
- Tasks that are not setting the version in the module manifest or otherwise
  need to evaluate the module version are now using the the module version
  from the built module's module manifest ([issue #160](https://github.com/gaelcolas/Sampler/issues/160)).
- The helper function `Get-ModuleVersion` was split into two cmdlets. A
  new helper function `Get-BuildVersion` that evaluates and returns the
  next module version, and `Get-BuiltModuleVersion` that always returns the
  module's version from the built module manifest.

## [0.105.1] - 2020-04-24

### Fixed

- The task build will no longer fail if GitVersion is not installed and
  there are no output folder.

## [0.105.0] - 2020-04-21

### Added

- Add new build task `Generate_Wiki_Content` for the DSC Community module type.

### Changed

- Update the repository to always use the latest version of the module
  `ModuleBuilder`.
  
### Fixed

- Now the prerelease is cleaned so that it does not contain any dashes by
  removing any suffix after a dash, for example `pr054-0012` will be changed
  to just `pr054` as the prerelease string. This is due to a bug in the
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
