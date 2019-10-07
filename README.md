# Sample Module

`TODO: Add build badge`

This project is a Module and template for PowerShell module and DSC Resources with a PowerShell Build Pipeline.

## Goal

The goal is to use my learnings from (and since) the [`gaelcolas/SampleModule`](https://github.com/gaelcolas/SampleModule/) experiment, and bring that up in a production-ready module and Plaster template, including DSC Resources, and implementing Build definition.

## Workflow and reasoning

### Bootstrap and re-hydration process

This is the beginning of the build process so that anyone doing a git clone can re-hydrate the project and start testing and producing the artefacts locally with minimum environment dependency.

- [x] Bootstrap (optional) the repository & resolve Dependencies (Module restore). Handled by the `.build.ps1`'s **BEGIN** block, and `Resolve-Dependency.ps1`:

  - Assume nothing is set up, and you don't have Admin rights
  - pushd in `$PSScriptRoot`
  - Create `.\output` if not exist
  - Prepend `.\output` to your `$Env:PSModulePath`
  - If Nuget package provider not present, Install & Import nuget PackageProvider (Proxy enabled)
  - Update `$PSRepository`'s Installation Policy to Trusted for the duration of the build
  - Bootstrap PowerShellGet `if($_.version -le '1.6.0')` to latest (Save-Module to `.\output\RequiredModules` or install to CurrentUser/AllUsers, Remove-Module -Force,  Import-Module -Force )
  - Import-Module PSDepend or install/save it, then import
  - [optional] Bootstrap `powershell-yaml` if we need to read further config from Yaml files instead of PSD1 (not sure about that one yet)
  - Invoke PSDepend based on the dependency file [.\RequiredModules.psd1](RequiredModules.psd1) <-- this could be made to support Yaml
  - Hand back over to InvokeBuild task (as per the invoked task/workflow)

  > Example:
  >
  > `C:\ > .build.ps1 -ResolveDependency -Tasks noop`
  >
  > This should setup your repository by re-hydrating all required dependencies to build and test your module, and invoke the (empty) task `noop`, so that it does not invoke the default workflow '.'
  >
  > The `-ResolveDependency` does not need to be invoked again to speed things up, unless a dependency file/version changes
  >
  > The Second run could be:
  >
  > `C:\ > .build.ps1 -Tasks noop`

- [X] Configure & Import the InvokeBuild tasks and workflow. Handled by the `.build.ps1`'s **PROCESS** block:

  - Only execute the PROCESS block through InvokeBuild task runner
  - Load Build Configuration Data from `.\build.psd1`
  - Set Build tasks header & footer to give more verbosity and structure to build logs
  - Import all Build tasks from the `.Build` folder (enable custom tasks defined in the repo, great for development as well)
  - [ ] Import Build tasks from the RequiredModules we decide (TODO: Defined in PSData or by $ModuleBase + relative directory )
  - Define basic/default tasks
    1. noop, so we can call the build script just to resolve dependency, or without doing anything
    2. The "." default meta-task (workflow). Currently doing Clean, Set build variables, build module with module builder and test
  - Load other workflows (or override the ones above) from the Build configuration file (a workflow is a list of task name that we imported earlier.)
  - InvokeBuild will then execute the task or workflow requested, and using "." if not specified

### Default Workflow Currently configured

As seen in the bootstrap process above, the different workflows can be configured by editing the `build.psd1`: new tasks can be loaded, and the sequence can be added under the `BuildWorkflow` key by listing the names.

In our case, [the Build.psd1](Build.psd1#L5) defines 2 workflows (. and test) that can be called by using:
```PowerShell
 .build.ps1 -Tasks Workflow_or_task_Name
```

The detail of the **default workflow** is as follow (InvokeBuild defaults to the workflow named '.' when no tasks is specified):

- [X] **Clean** the built artefacts & test results (clean everything under output), except Required modules (for performance, and because any loaded module with DLL will have an Handle, like Pester)
- **Set_Build_Environment_Variables**: Uses `BuildHelpers` from Warren Frame to abstract CI Tools' specific Environment variable under same name (not sure still needed/worth it).
- **Build_Module_ModuleBuilder**: Uses [`PoShCode/ModuleBuilder`](https://github.com/PoshCode/ModuleBuilder/)'s `Build-Module` command to [merge](.build/tasks/Build-Module.ModuleBuilder.build.ps1) public/private functions, classes, enums into a single PSM1 under a versioned directory in the `output` folder. Then update Module manifest's Module version (based on [GitVersion](GitVersion.yml)), and the Exported functions. Need to add update to DscResources exported, DSC Composite Resources version (same as Module version).
- **Pester_Tests_Stop_On_Fail**: This is actually a meta task of:
- **Invoke_pester_tests**: run `Invoke-Pester -Script $TestFolder` and other arguments
- **Upload_Test_Results_To_AppVeyor**: push the Test results XML to AppVeyor [if running in AppVeyor](.build/tasks/Invoke-Pester.pester.build.ps1#L139)
- **Fail_Build_if_Pester_Tests_failed**: Fails the build if any test failed
- **Pester_if_Code_Coverage_Under_Threshold**: This fails the build if the Pester Code Coverage is under the [configured](.build.ps1#L21) threshold.

### What needs to be added next

- [ ] Run Quality tests
  - [ ] Ensure each function/class file has an associated test file
  - [ ] Ensure PSSA is clean for the built module
  - [ ] Ensure each function as minimum help
  - [ ] Enable DSC Resource linting & Unit testing (need to make a module or several out of [DscResource.Tests](https://github.com/PowerShell/DscResource.Tests), and I intend to use this template to do so)
  - [ ] Module Integration Testing with Test-Kitchen

- [ ] Prepare Module for export
  - [ ] Update Metadata with DscResources to export
  - [ ] Update Metadata for Composite Resources
  - [ ] Update Import-DscResource pinned version when needed
  - [ ] Update RequiredModules with what it has been tested with
  - [ ] Sign module

- [ ] Deploy artefacts tasks
  - [ ] PSDeploy MAML?
  - [ ] Push test results to Azure DevOps
  - [ ] PSDeploy Module to Appveyor/Azure DevOps Gallery
  - [ ] Promote corresponding preview on git tag (pull preview, unpack, make non-preview, test, deploy)

---------------

- Build Tasks:
  - [ ] Move Sampler build tasks from \.build\ folder into compiled module so it can be used from module instead of in-repo (to benefit from version)
  - [ ] make those tasks discoverable (i.e. Extension metadata, similar to Plaster Templates)

- Tests
  - [ ] Create Test function to run tests based on folder, so that tasks don't duplicate code (Unit,Integration,QA)
  - [ ] Allow Module Quality by Managing Quality level i.e. `Invoke-pester -ExcludeTag HelpQuality`
  - ~~[ ] Allow tests to be run either in current session or in New PSSession with no-profile (to have no Class / Assemblies loaded)~~ <-- Less important within CI

- Build & CI tools
  - [ ] Extend the project to DSC Builds
  - [ ] add Azure DevOps Pipeline builds for different platforms

## Usage (intended)

`.build.ps1` is fairly generic, but this is where parameters can be added in a given repository to change the input on all tasks using that parameter.
Most of the Build customization is done for the project can be done in `build.psd1`. This is where the default task `.` is composed by importing required tasks exposed by different modules or added to the current repository when specific.

```PowerShell
Param (
    [String]
    #Override the Parameter of every tasks using $BuildOutput (i.e. [QualityTests](.build/Pester/QualityTests.pester.build.ps1))
    $BuildOutput = "$PSScriptRoot\BuildOutput"
)

#Import custom tasks
Get-ChildItem -Path "$PSScriptRoot/.build/" -Recurse -Include *.ps1 -Verbose |
    Foreach-Object {
        "Importing file $($_.BaseName)"
        . $_.FullName
    }

```
