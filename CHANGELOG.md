# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Pinned GitVersion to v5 in the pipeline since v6 is not yet supported, also
  updated templates to pin GitVersion v5. Workaround for issue [#477](https://github.com/gaelcolas/Sampler/issues/477).
- Fix issue template in repository and Plaster template ([issue #483](https://github.com/gaelcolas/Sampler/issues/483)).
- Moved large parts of the ReadMe to the Wiki to handle Include simple tutorials in the Wiki ([issue #487](https://github.com/gaelcolas/Sampler/issues/487))

## [0.118.1] - 2024-07-20

### Added

- Added extensions.json for vscode
- Automatic wiki documentation for public commands.

### Changed

- Update template for SECURITY.md and add it to Sampler repository as well.
- Built module is now built in a separate folder. This is to split the paths
  for the built module and all required modules, to avoid returning duplicate
  modules when using `Get-Module -ListAvailable`. The templates already has
  this configuration.
- Now PSResourceGet always default to the latest released version if no
  specific version is configured or passed as parameter.
- Templates was changed to use PSResourceGet as the default method
  of resolving dependencies. It is possible to change to the method
  PowerShellGet & PSDepend by changing the configuration. Also default to
  using PowerShellGet v3 which is a compatibility module that is a wrapper
  for the equivalent command in PSResourceGet.
- Switch to build worker `windows-latest` for the build phase of the pipeline
  due to a issue using `Publish-Module` on the latest updated build worker in
  Azure Pipelines.
- Public command documentation has been moved from README.md to the GitHub
  repository Wiki.
- Update order of deploy tasks for the Plaster templates to make it easier
  to re-run a deploy phase when a GitHub token has expired.

### Fixed

- Update template for module.tests.ps1. Fixes [#465](https://github.com/gaelcolas/Sampler/issues/465)
- Now the tasks work when using `Set-SamplerTaskVariable` with tasks that
  do not have the parameter `ChocolateyBuildOutput`.
- Remove duplicate SECURITY.md template files, and fix templates to
  point to the single version.
- Correct description of the parameter `GalleryApiToken` in the build task
  script release.module.build.ps1. Fixes [#442](https://github.com/gaelcolas/Sampler/issues/442)
- ModuleFast now supports resolving individual pre-release dependencies
  that is part of _RequiredModules.psd1_. It is also possible to specify
  [NuGet version ranges](https://learn.microsoft.com/en-us/nuget/concepts/package-versioning#version-ranges)
  in _RequiredModules.psd1_, although then the file is not compatible with
  PSResourceGet or PSDepend (so no fallback can happen).
- Now it won't import legacy PowerShellGet and PackageManagement when
  PSResourceGet or ModuleFast is used.
- Now it works saving PowerShellGet compatibility module when configured.
- Now if both ModuleFast and PowerShellGet compatibility module is configured
  PSResourceGet is automatically added as a dependency. This is for example
  needed for publishing built module to the gallery.
- Update pipeline so build not fail.

## [0.117.0] - 2023-09-29

### Added

- Integration tests to build and import a module created using the Plaster
  template _SimpleModule_.
- Support [ModuleFast](https://github.com/JustinGrote/ModuleFast) when
  restoring dependencies by adding the parameter `UseModuleFast` to the
  `build.ps1`, e.g. `./build.ps1 -Tasks noop -ResolveDependency -UseModuleFast`
  or by enabling it in the configuration file Resolve-Dependency.psd1.
  Using ModuleFast will resolve dependencies much faster, but requires
  PowerShell 7.2.
- Support for [PSResourceGet (beta release)](https://github.com/PowerShell/PSResourceGet).
  If the modules PSResourceGet can be bootstrapped they will be used. If
  PSResourceGet cannot be bootstrapped then it will revert to using
  PowerShellGet v2.2.5. If the user requests or configures to use ModuleFast
  then that will override both PSResourceGet and PowerShellGet. The method
  PSResourceGet can be enabled in the configuration file Resolve-Dependency.psd1.
  It is also possible to use PSResourceGet by adding the parameter `UsePSResourceGet`
  to the `build.ps1`, e.g. `./build.ps1 -Tasks noop -ResolveDependency -UsePSResourceGet`.
- When using PSResourceGet to resolve dependencies it also possible to
  use PowerShellGet v2.9.0 (previous _CompatPowerShellGet_). To use the
  compatibility module it can be enabled in the configuration file Resolve-Dependency.psd1.
  It is also possible to use it by adding the parameter `UsePowerShellGetCompatibilityModule`
  to the `build.ps1`, e.g. `./build.ps1 -Tasks noop -ResolveDependency -UsePSResourceGet -UsePowerShellGetCompatibilityModule`.
  _The 2.9.0-preview has since then been unlisted, the compatibility_
  _module will now be released as PowerShellGet v3.0.0._

### Changed

- Task `publish_nupkg_to_gallery`
  - Add support for publishing a NuGet package to a gallery using the .NET SDK in addition to using nuget.exe. Fixes [#433](https://github.com/gaelcolas/Sampler/issues/433)
- Split up unit tests and integration tests in separate pipeline jobs since
  integration tests could change state on a developers machine, and in the
  current PowerShell session. Integration tests no longer run when running
  `./build.ps1 -Tasks test`. To run integration tests pass the parameter
  `PesterPath`, e.g. `./build.ps1 -Tasks test -PesterPath 'tests/Integration'`.
- Added sample private function and public function samples to Plaster template
  _SimpleModule_ so that it is possible to run task `test` without it failing.
- Sample Private function tests updated to Pester 5.
- Sample Public function tests updated to Pester 5.
- Sampler's build.ps1 and the template build.ps1 was aligned.
- PowerShell Team will release the PSResourceGet compatibility module
  (previously known as CompatPowerShellGet) as PowerShellGet v2.9.0 (or
  higher). The resolve dependency script, when PowerShellGet is used, will
  use `MaximumVersion` set to `2.8.999` to make sure the expected
  PowerShellGet version is installed, today that it is v2.2.5.
  _The 2.9.0-preview has since then been unlisted, the compatibility_
  _module will now be released as PowerShellGet v3.0.0._

### Fixed

- Fix unit tests that was wrongly written and failed on Pester 5.5.
- There was different behavior on PowerShell and Windows PowerShell when
  creating the module manifest. So when the `modify` section that was meant
  to reuse the already present but commented `Prerelease` key it also ran
  the `modify` statement that adds a `Prerelease` key that is needed for
  a module manifest that is created under Windows PowerShell. This resulted
  in two `Prerelease` keys when creating a module under PowerShell 7.x.
  Now it will add a commented `Perelease` key and then next `modify` statement
  will remove the comment, making it work on all version of PowerShell.
  Fixes [#436](https://github.com/gaelcolas/Sampler/issues/436).
- The QA test template was updated so that it is possible to run the tests
  without the need to add a git remote (remote `origin`).

## [0.116.5] - 2023-04-19

### Fixed

- Fix Azure Pipeline bug to resolve errors and delays during the build process. Shallow fetch has been disabled to ensure complete repository cloning. Fixes [#424](https://github.com/gaelcolas/Sampler/issues/424)

## [0.116.4] - 2023-04-06

### Fixed

- Fix a bug that prevented downloading of dependent modules that has a
  dependency on the module _PowerShell-Yaml_. Fixes [#421](https://github.com/gaelcolas/Sampler/issues/421).

## [0.116.3] - 2023-04-01

### Changed

- Template `SimpleModule`
  - The template has been changed to create a module with the minimum scaffolding
    when using default values for the template questions. The minimum scaffolding
    enable the building and testing of the module, but default there is no pipeline
    so it possible to use any platform to run the pipeline.
  - Additional template parameters have been added which will add additional
    functionality to the module.
    - `UseGit` - This parameter enables project files that helps with the use
      of Git for the project. The template will ask if Git should be used, default
      is No.
    - `UseGitVersion` - This parameter adds project files that helps with
      the use of GitVersion for the project. GitVersion is dependent on Git
      being used for the project. The template will ask if GitVersion should
      be used if the use of Git was chosen, default is No.
    - `UseCodeCovIo` - This parameter adds project files that helps with
      the use of CodeCov.io for the project. CodeCov.io is dependent on Git
      being used for the project. The template will ask if CodeCov.io should
      be used if the use of Git was chosen, default is No.
    - `UseGitHub` - This parameter adds project files that helps with
      the use of GitHb.com for the project. GitHub.com is dependent on Git
      being used for the project. The template will ask if GitHub.com should
      be used if the use of Git was chosen, default is No.
    - `UseAzurePipelines` - This parameter adds project files that enables
      the project to run the pipeline in Azure Pipelines (in Azure DevOps).
      The template will ask if Azure Pipelines should be used, default is No.
    - `UseVSCode` - This parameter adds project files that helps when using
      Visual Studio Code as the project code editor. The template will ask
      if  Visual Studio Code should be used, default is No.
  - The file `build.yaml` will only contain tasks from `Sampler.GitHubTasks`
    if template parameter `UseGitHub` is set to true (the answer to the
    template question is Yes).
  - The file `RequiredModules.psd1` will only contain the module `Sampler.GitHubTasks`
    if template parameter `UseGitHub` is set to true (the answer to the
    template question is Yes).
  - If Git is not used (`UseGit` is false) the QA test that uses Git is
    removed for the generated file `module.tests.ps1`.
- Removed module Plaster from the template file `RequiredModules.psd1.template`
  since it is not direct requirement for any project. _It will still be saved_
  _to `output/RequiredModules` for a project as it is defined as a required_
  _module in Sampler's module manifest, and Sampler is still a required modul._
- Pipeline script for resolving dependencies improved.
  - Evaluating PowerShellGet version now supports parameter `AllowOldPowerShellGetModule`
    (still not recommended to use this parameter).
  - Now defaults to save the modules PowerShellGet and PackageManagement
    to the folder `output/RequiredModules` (same logic as for module PSDepend)
    to not make permanent changes to the contributors machine. If parameter
    `PSDependTarget` is either set to `CurrentUser` or `AllUsers` the modules
    are installed.

### Fixed

- Removed duplicate header in template file `README.md.template`.
- Fix typo in the file `about_ModuleName.help.template` and in `module.template`.
- Integration tests clean up the test drive after each test.
- Update generated module manifest to have recommended values for properties.
  Fixes [#326](https://github.com/gaelcolas/Sampler/issues/326).
- Now correctly uses the key `CodeCoverage` in the file `build.yaml.template`.
  Fixes [#359](https://github.com/gaelcolas/Sampler/issues/359).
- Pipeline script for resolving dependencies improved.
  - `Get-PackageProvider` no longer throws an exception when NuGet provider
    is missing (in Windows PowerShell in a clean Windows install).
  - `Install-PackageProvider` now defaults to installing in the current
    user scope to avoid requiring an elevated prompt. This is the only
    change that is permanent on the contributors machine. It is not possible
    to avoid this as long at the module PowerShellGet requires the NuGet
    package provider.
  - Remove duplicate code that set `AllowPrerelease` when installing package
    provider.
  - Fixed wrong splatting variable that prevented `Install-PackageProvider`
    to run.
  - Removing all existing PowerShellGet and PackageManagement module that
    is loaded into the session to load the newly saved or installed.
  - Handle parameter `AllowOldPowerShellGetModule` when loading PowerShellGet
    module version.
  - Fix message on `Write-Progress` statement.
  - Small style cleanups.
- Fixed aliases in `prefix.ps1` to support ModuleBuild v3.0.0. The fix
  makes ModuleBuilder not seeing the aliases (using AST) so that the module
  manifest is not changed during build, instead they are exported during
  module import. In the future we could add a separate public file that
  defines the aliases to export so the module manifest is updated during
  build.

## [0.116.2] - 2023-03-01

### Added

- Script `Set-SamplerTaskVariable.ps1`
  - Added debug output of PSModulePath

## [0.116.1] - 2023-01-09

### Fixed

- Task `Build_ModuleOutput_ModuleBuilder`
  - Fixed #402: Using parameter `Filter` instead of `Include` to get MOF files.
- `Get-MofSchemaName`
  - Permanently skipped a test that the build worker `ubuntu-latest` were
    unable to run due to missing shared library 'libmi'.
- Now the QA test that verifies that the Unreleased section header is present
  in the CHANGELOG.md correctly supports ChangelogManagement v3.0.1.
- Task `Convert_Pester_Coverage`
  - No longer throws an exception when there was just one missed command
    for a test suite. Fixes [#407](https://github.com/gaelcolas/Sampler/issues/407).

### Added

- Task `Build_ModuleOutput_ModuleBuilder`
  - Proper support for DSC composite resources (*.schema.psm1).
- Added task `Set_PSModulePath`.
  - Added function `Set-SamplerPSModulePath`.
  - Added tests for the task and function.
  - Added task `Set_PSModulePath` to `build.yml` Plaster template for project
    type `dsccommunity`.

### Changed

- The QA tests can now be debugged by `Invoke-Pester` directly, before it
  had to be started by the build script `build.ps1`. This will also help
  the Pester Tests VS Code extension to be able to run the tests.

## [0.116.0] - 2022-11-08

### Removed

- Removed the task `Set_Build_Environment_Variables` since it is not used,
  and build helpers are not in use anymore. Fixes [#376](https://github.com/gaelcolas/Sampler/issues/376).
- Removed MOF based DSC resources from the CompleteModule sample.

### Added

- Added more unit tests to raise code coverage.
  - Deprecated Pester 4 HQRM tests was removed from code coverage. The new
    Pester 5 HQRM test are in module DscResource.Test and is tested there.

### Changed

- Task `copy_paths_to_choco_staging`
  - Now handle property `Exclude` and `Force` correctly.
- `Merge-JaCoCoReport`
  - Improvements to be able to merge missing elements, like entire element
    `<class>`, `<sourcefile>`, `<method>`.

### Fixed

- `Get-MofSchemaName`
  - Correctly throws an error if the schema MOF cannot be parsed.
- Task `Convert_Pester_Coverage`
  - Removed one unused line of code.
  - Moved one line of code so that code coverage threshold value
    will output correctly in some circumstances.
- `Set-SamplerTaskVariable`
  - Reverted code that was removed in pull request #383. The code is
    necessary because how the commands `Get-BuiltModuleVersion`,
    `Get-SamplerBuiltModuleManifest`, `Get-SamplerBuiltModuleBase`, and
    `Get-SamplerModuleRootPath` are currently built. The code that was
    reverted handles resolving the wildcard (`*`) in the returned paths
    from the mentioned commands.
- `RequiredModules.psd1.template`
  - Fixes #397, `ModuleType` Plaster parameter.
- `Resolve-Dependency.ps1`
  - Fixes #394, `AllowPrerelease` is ignored for bootstrap.
- `module.tests.ps1.template`
  - Fixed code style according to this project's standard.

## [0.115.0] - 2022-06-09

### Added

- Supports using a private Nuget repository, e.g. a _Azure DevOps Server_
  _Pipelines_ feed that is using Windows integrated security, or a feed with
  no security.
- Now supports getting module version from `dotnet-gitversion` if it is available.
- Tests now run in Pester 5.
- Added task `Create_Release_Git_Tag` to create a Git tag for a preview release.
  Fixes [#351](https://github.com/gaelcolas/Sampler/issues/351)
- Added task `Create_Release_Branch` to push a branch containing the updated
  change log after release. Fixes [#351](https://github.com/gaelcolas/Sampler/issues/351)

### Changed

- The QA test that verifies that a change log entry has been added to CHANGELOG.md
  will no longer fail if the CHANGELOG.md has not been committed but is staged
  or unstaged. This makes it possible to get the QA tests to pass without having
  to first commit changes.

### Fixed

- Task `package_module_nupkg` now correctly adds the release notes to the
  Nuget package. Fixes [#373](https://github.com/gaelcolas/Sampler/issues/373)
- Task `publish_module_to_gallery` now correctly adds the release notes to
  the published module. Fixes [#373](https://github.com/gaelcolas/Sampler/issues/373)
- Fix a evaluation in the script `Set-SamplerTaskVariable` so it can be tested
  individually outside of the pipeline (using `Invoke-Pester`).
- Fix all source files to UTF8 to comply with the HQRM tests (_due to a bug_
  _in the HQRM tests that runs in Pester 4 this has not been detected until_
  _moving to Pester 5_).
- Remove HQRM rule suppression in source file for `New-SamplerJaCoCoDocument`
  since it no longer required.
- Fixed QA test that was breaking release.
- Fixed #384: It not tag is defined, `Create_Release_Git_Tag` throws an error.

## [0.114.0] - 2022-05-13

### Added

- New task `Pester_Run_Times` that outputs each test's run time. Only works
  for Pester 5. The task will be skipped if Pester 4 is used.

### Fixed

- Fixed a problem which occurred on certain machined when using Sampler in
  Windows PowerShell. Fixes [#350](https://github.com/gaelcolas/Sampler/issues/350)
- The module manifest is now correctly updated with release notes from the
  changelog. Fixes [#358](https://github.com/gaelcolas/Sampler/issues/358)

## [0.112.3] - 2022-03-31

### Fixed

- The task `Invoke_Pester_Tests_v5` generated a unexpected filename for the
  test results, compared to the Pester 4 task. Fixes [#355](https://github.com/gaelcolas/Sampler/issues/355)

## [0.112.2] - 2022-03-20

### Fixed

- Fixed GuestConfiguration build task on MOF file name equal to `localhost.mof`
- Fixed explicit parameter value in `build.ps1` while calling `.\Resolve-Dependency.ps1`
- When running test using Pester 5, and the build configuration (`build.yaml`)
  do not specify the location of tests in the key `Path`, the pipeline will
  no longer run the tests twice. Fixes [#337](https://github.com/gaelcolas/Sampler/issues/337)

### Changed

- Switch to installing GitVersion using `dotnet tool install`. Fixes [#348](https://github.com/gaelcolas/Sampler/issues/348)
- Updated pipeline to use the build worker image 'ubuntu-latest'.
- Updated pipeline to use the build worker image 'windows-latest'.
- Updated the Plaster templates
  - to use 'dotnet tool install' in the pipeline.
  - to use build image 'ubuntu-latest' in the pipeline.
  - to use build image 'windows-latest' in the pipeline.

## [0.112.1] - 2022-01-23

### Removed

- Template file `Build/RequiredModules.psd1` that was not used.

### Added

- Added Pipeline to build chocolatey packages.
- Added Sample to add Chocolatey Package source files.
- Added New-SamplerPipeline to create build, Sampler Module or Chocolatey pipeline.
- Extra configuration files for passing to Azure Policy Guest Configuration Package on creation.

### Fixed

- Fixed `Resolve-Dependency.ps1` to not fail when `PowerShell-yaml` module was specified but already loaded (handle on dll). Fixes [#335](https://github.com/gaelcolas/Sampler/issues/335)
- Fixed default source folder to source and not src.
- Fixed failed loading when there's no project name (when calling `Set-SamplerTaskVariable`). Fixes [#331](https://github.com/gaelcolas/Sampler/issues/331).
- Fixed `Get-SamplerAbsolutePath` returning the wrong path in PowerShell and ISE. Fixes [#341](https://github.com/gaelcolas/Sampler/issues/341).
- The templates was using the task `Create_ChangeLog_GitHub_PR` in the meta task
  publish that is also specifically run in a separate Azure Pipelines task. This
  made the task to run twice.
- Fixed missing full stop (`.`) in the CONTRIBUTING.md and the template file.
  Fixes [#333](https://github.com/gaelcolas/Sampler/issues/333).

### Changed

- Making sure the `Set-SamplerTaskVariable` does not fail when there's no
  Module manifest (i.e. when using Sampler for other reasons than building
  a module).
- Switched the pipeline to use Ubuntu 18.04 instead of Ubuntu 16.04 as the build
  worker for some tasks.
- Template `SimpleModule` have been modified to remove unnecessary configuration
  ([issue #277](https://github.com/gaelcolas/Sampler/issues/277)).
- Template files are updated.
  - Module script file no longer contain code that is irrelevant.
  - Now asks if GitVersion should be used.
  - Now asks if CodeCov.io should be used.
  - Now asks for the upstream GitHub organization or account name to be used
    in Azure Pipelines.
  - GitVersion.yml now uses the correct chosen default branch.
  - Codecov.yml now uses the correct chosen default branch.
- Fixed GuestConfiguration compilation to work with GuestConfiguration module version 4.0.0-preview0002.
- Set the default type to AuditAndSet, but supporting override by creating a '$GCPackageName.psd1' file along with the config. 

## [0.112.0] - 2021-09-23

### Removed

- Removed `PesterOutputFormat` parameter in `DeployAll.PSDeploy.build.ps1`
 fix ([issue #292](https://github.com/gaelcolas/Sampler/issues/292)).
- Removed the template `newDscCommunity` which is replaced by the template
  `dsccommunity`.

### Added

- Added -WhatIf parameter to `release.module.build.ps1`

### Changed

- Merged both templates `dsccommunity` and `newDscCommunity` into the
  template `dsccommunity`.
- All templates now defaults to using `main` as the default branch.
- Updated Sampler documentation in README.md.

### Fixed

- Fix azure-pipelines.yml where variables are not possible to use (triggers
  and deploy condition).

## [0.111.8] - 2021-08-08

### Changed

- Fixed GitHub templates for the Sampler repository.
- Fixed GitHub templates in the DSC Community Plaster template.

### Fixed

- Task `Pester_If_Code_Coverage_Under_Threshold`
  - Now the code code coverage threshold is correctly reported using decimals.

## [0.111.6] - 2021-07-03

### Added

- Added pester tests for `Set-SamplerVariableTask.ps1`.

### Changed

- Changed Plaster Template (`Sampler/Templates/Sampler/plasterManifest.xml`), so
  that all functions will be exported by default, which in turn correlates with
  the template code in `Sampler/Sampler.psm1`, which uses
  `Export-ModuleMember` to export all functions loaded from the
  `Public` (sub-)folder.

### Fixed

- Removed `$BuiltModuleSubdirectory` definition in the `begin` bloc of `build.ps1`
 template ([issue #299](https://github.com/gaelcolas/Sampler/issues/299)).
- Replaced `$ModudulePath` with `$BuiltModuleBase` for the `release.module.build.ps1` task file.

## [0.111.5] - 2021-06-25

### Added

- Added support of `BuiltSubDirectoryDirectory` in build configuration files
 ([issue #299](https://github.com/gaelcolas/Sampler/issues/299))

### Fixed

- The task `Invoke_Pester_Tests_v5` no longer fails when using Pester 
  v5.3.0-alpha5 ([issue #307](https://github.com/gaelcolas/Sampler/issues/307)).
- The task `Convert_Pester_Coverage` no longer fails when using a preview
  version of Pester ([issue #301](https://github.com/gaelcolas/Sampler/issues/301)).

## [0.111.4] - 2021-06-03

### Fixed

- Task `Invoke_Pester_Tests_v4`
  - It now once again works using a hashtable together with parameter
    `PesterScript` ([issue #303](https://github.com/gaelcolas/Sampler/issues/303)).

## [0.111.3] - 2021-05-21

### Fixed

- If the Pester build configuration key `ExcludeFromCodeCoverage` does
  not specify a value, the task `Invoke_Pester_Tests_v5` no longer fails.

## [0.111.2] - 2021-05-21

### Fixed

- Now the task `Pester_If_Code_Coverage_Under_Threshold` correctly honors
  the zero value (`0`) of the parameter `CodeCoverageThreshold` when using
  `build.ps1`, and honors the zero value (`0`) of the Pester advanced build
  configuration key `CoveragePercentTarget`. If the value is set to `0` the
  task will now be skipped since code coverage was disabled.

## [0.111.1] - 2021-05-15

### Fixed

- Now the task `Pester_If_Code_Coverage_Under_Threshold` report the code coverage
  and correctly fail if the code coverage is under the code coverage threshold.
- Task `Invoke_Pester_Tests_v5`
  - Now the Pester advanced configuration correctly handles `false` values
    in the build configuration files.
  - Now the Pester object, that is written to file by the pipeline, correctly
    holds all expected objects. `Export-CliXml` defaulted to two levels of
    depth, now it exports five levels.

## [0.111.0] - 2021-05-13

### Added

- Added new public command `New-SamplerJaCoCoDocument`.
- Added new public command `Out-SamplerXml`.
- Added new private function `New-SamplerXmlJaCoCoCounter`.
- Added new build task `Import_Pester` ([issue #223](https://github.com/gaelcolas/Sampler/issues/223)).
- Added new build task `Invoke_Pester_Tests_v5` ([issue #223](https://github.com/gaelcolas/Sampler/issues/223)).
  - Task `Invoke_Pester_Tests_v5` will not run if Pester 4 is used in the pipeline.
- Added unit test for public command `Get-BuildVersion`.

### Changed

- Renamed default branch to `main` ([issue #235](https://github.com/gaelcolas/Sampler/issues/235)).
- Added a public alias `Set-SamplerTaskVariable` that points to the script
  `Set-SamplerTaskVariable.ps1` in the tasks folder. This alias is used to
  dot-source task variables for re-use over multiple build tasks.
- Moved code from build task `Convert_Pester_Coverage` into a public function
  `New-SamplerJaCoCoDocument`.
- It is now possible to specify module's semantic version in the build.yml using
  the key `SemVer`, e.g. `SemVer: '99.0.0-preview1'`. This can be used if the
  preferred method of using GitVersion is not available, and it is not possible
  to set the session environment variable `$env:ModuleVersion`, nor setting the
  variable `$ModuleVersion` in the PowerShell session (parent scope) before
  running the task `build` ([issue #279](https://github.com/gaelcolas/Sampler/issues/279)).
- Templates
  - build.yaml
    - Comment Pester tag exclusion for all templates so that the default is
      to use all QA test.
    - Added comment task `Convert_Pester_Coverage` for the _test_ task.
    - Removed leftovers from key DscTest that was kept when using template
      'SimpleModule'.
    - Updated with entries to support several code coverage scenarios, some
      initially commented.
  - azure-pipelines_dsccommunity.yml
    - Updated with the latest code coverage scenarios, some initially
      commented.
  - azure-pipelines.yml
    - Updated with the latest code coverage merge scenario.
  - codecov_dsccommunity.yml
    - Removed and replaced with codecov.yml.template
  - codecov.yml.template
    - Codecov.yml is now added for several templates and features. Content
      is dependent on the template that is used.
  - Now the template 'dsccommunity' gets a `README.md` file.
- Task `Invoke_Pester_Test` was renamed to `Invoke_Pester_Tests_v4`.
  - Pester 5 support was removed from the task and replaced with `Invoke_Pester_Tests_v5`
  - Task `Invoke_Pester_Tests_v4` will not run if Pester 5 is used in the pipeline.
- Meta build task `Pester_Tests_Stop_On_Fail` was change to run `Import_Pester`,
  `Invoke_Pester_Tests_v4` (previously `Invoke_Pester_Test`), and `Invoke_Pester_Tests_v5`.
  - Task `Invoke_Pester_Tests_v4` will not run if Pester 5 is used in the pipeline.
  - Task `Invoke_Pester_Tests_v5` will not run if Pester 4 is used in the pipeline.
- The task _Convert\_Pester\_Coverage_ was changed to support converting
  Pester 5 code coverage.
- The function `Get-CodeCoverageThreshold` was changed to support Pester 5
  advanced build configuration.
- The function `Get-SamplerCodeCoverageOutputFile` was changed to support Pester 5
  advanced build configuration.

### Fixed

- Renamed task file from `Merge-CodeCoverageFiles.pester.build.ps1` to `JaCoCo.coverage.build.ps1`.
- Move task _Convert_Pester_Coverage_ to task file `JaCoCo.coverage.build.ps1`.
- Resolve-Dependency.ps1: fix MinimumPSDependVersion comparison.
- Resolve-Dependency.ps1: add -Force to all Save-Module.
- `New-SamplerJaCoCoDocument`
  - Fixed counters when a method only had either one hit line or one missed line.
- Now unit tests properly test the function in the built module, not the
  ones that the pipeline dot-sources into session to be able to dogfooding
  itself.
- Fix so that _Convert\_Pester\_Coverage_ correctly replaces build version
  with source folder in JaCoCo file.

## [0.110.1] - 2021-04-08

### Fixed

- Fix task _Convert_Pester_Coverage_ so it is skipped when `CodeCoverageThreshold`
  is `0`.

## [0.110.0] - 2021-04-08

### Fixed

- Resolve-Dependency.ps1 PSDependTarget param no longer includes period.
- Resolve-Dependency.ps1 Save-Module added -Force switch to create non-existent directory.

### Added

- Support for Generating MAML help files (all Locale/Culture) from PlatyPS Markdown Source.
- Support for Updating the PlatyPS Markdown source in your repo (this is a dev task to do before a commit).
- Support for Generating MAML file from Comment-based help (not recommended).
- Support for code coverage when using ModuleBuilder pattern for building module.
- `Update-JaCoCoStatistic`
  - Added unit test.
- Pipeline updated to support merging code coverage between operating
  system pipeline jobs.

### Fixed

- `Merge-JaCoCoReport`
  - Now correctly adds new packages to the original document.
  - Moves the `report` element's `counter` elements to the bottom of
    the `report` element to comply with the DTD.
- `Update-JaCoCoStatistic`
  - Fixed so that statistics are updated correctly for the 'CLASS' counter.
- Fixed codecov.yml to parse version number in paths correctly.
- Fix uploading to Azure Code Coverage.
- _Merge_CodeCoverage_Files_
  - Fixed so the file that is outputted is in UTF-8 (without BOM) to support 
    Codecov.io.
  - The task now only searches for the file pattern inside the `./output/testResults`
    folder.
  - The merge process is not attempted if `CodeCoverageThreshold` is set to 
    `0`.
  - Updated so that build.yaml now have a key `CodeCoverage` which have to
    settings `CodeCoverageMergedOutputFile` and `CodeCoverageFilePattern`.
- _Convert_Pester_Coverage_
  - The backup file now have the extension `.bak` (instead of `.bak.xml`)
    so that is not mistakenly used by a task _Merge_CodeCoverage_Files_.
  - Some code cleanup.

## [0.109.10] - 2021-03-24

### Fixed

- Fixed issue with uncommenting release notes in module manifest

## [0.109.9] - 2021-03-20

### Fixed

- Fix to use the correct path when determine class-based resources.

## [0.109.8] - 2021-03-20

### Fixed

- Fix issue when there is no root module.
- Fix to use the correct path when determine class-based resources.

## [0.109.7] - 2021-03-20

### Fixed

- Error when the Module has no RootModule script (manifest only with DSC resources).

## [0.109.6] - 2021-03-18

### Fixed

- Fixed #247 where Building submodule would fail on linux (but not WSL).
- Fixed #239 to re-add support for BuiltModuleSubdirectory more consistently.
- Fixed bug when using CopyOnly nested resources.

### Changed

- Made Convert-SamplerHashtableToString public function.
- Refactored a lot of Path resolution into Sampler public function for consitency and re-usability.
- Updated the Tasks to use those Sampler functions.
- Updated Get-BuiltModuleVersion to support $BuiltModuleSubdirectory as per #239.

### Added

- Added Get-SamplerAbsolutePath, Get-SamplerBuiltModuleBase, Get-SamplerModuleInfo,
  Get-SamplerBuiltModuleManifest, Get-SamplerModuleRootPath.

## [0.109.5] - 2021-03-10

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
