# Sampler Module [![Azure DevOps builds](https://img.shields.io/azure-devops/build/Synedgy/524b41a5-5330-4967-b2de-bed8fd44da08/1)](https://synedgy.visualstudio.com/Sampler/_build?definitionId=1&_a=summary)

[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/Sampler?label=Sampler%20Preview)](https://www.powershellgallery.com/packages/Sampler/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/Sampler?label=Sampler)](https://www.powershellgallery.com/packages/Sampler/)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/SynEdgy/Sampler/1)](https://synedgy.visualstudio.com/Sampler/_test/analytics?definitionId=1&contextType=build)
![Azure DevOps coverage](https://img.shields.io/azure-devops/coverage/Synedgy/Sampler/1)
![PowerShell Gallery](https://img.shields.io/powershellgallery/p/Sampler)

This project is a Module and template of a PowerShell module and DSC Resources (soon)
with its PowerShell Build Pipeline automation.

The Sampler module in itself serves several purposes:

- illustrate what a module source repository and its pipeline could look like
- Publish Sampler to PSGallery to provide `InvokeBuild` tasks that can be re-used by anyone
- Provide a Plaster template to create similar module easily and quickly

## Usage

When you clone this module locally, or if you create a module from its template,
the `build.ps1` is how you interact with the built-in pipeline automation, and
`build.yaml` how you configure and customize it.

### Bootstrapping repository and Resolve-Dependency

Quick Start:

```PowerShell
PS C:\src\Sampler> build.ps1 -ResolveDependency
# this will first bootstrap the environment by downloading dependencies required for the automation
# then run the '.' task workflow as defined in build.yaml (a list of Invoke-Build tasks)
```

The `build.ps1` is the _entry point_ to invoke any task or a list of build tasks (workflow),
leveraging the [`Invoke-Build`](https://www.powershellgallery.com/packages/InvokeBuild/) task runner.

But we don't assume your environment has the required PowerShell modules,
so the `bootstrap` is done by `build.ps1`, and can resolves the dependencies listed
in `RequiredModules.ps1` using `PSDepend`.

Invoking `build.ps1` with the `-ResolveDependency` parameter will prepare your environment like so:

1. Update your Environment variables ($Env:PSModulePath) to resolve built
& local (repository) module first (by prepending those paths)
1. Making sure you have a trustable version of PSGet &
PackageManagement (`version -gt 1.6`) or install it from *a* gallery
1. Download or install the `PowerShell-yaml` and `PSDepend` modules needed for
further dependency management
1. Read the `build.yaml` configuration
1. Invoke [PSDepend](https://github.com/RamblingCookieMonster/PSDepend) on
the RequiredModules.psd1
1. hand over the task executions to `Invoke-Build` to run the workflow

>By default, each repository should not rely on your environment,
>so that it's easier to repeat on any machine or build agent.
>Instead of installing required modules to your environment,
>it will Save them to the `output/RequiredModules` folder
>of your repository.
>
>By also prepending this path to your `$Env:PSModulePath`,
>the build process will make those dependencies available in your session for
>module discovery and auto-loading.

Once the `-ResolveDependency` has been called once, there should not be a need
to call it again until the `RequiredModules.psd1` is changed.

Although you can use `Invoke-Build` to call the tasks, ensuring you are
using `build.ps1` instead will make sure the right environment variables
are set in your session.

### Discoverability & noop

Quick Start:
```PowerShell
PS C:\src\Sampler> .\build.ps1 -Tasks ?
[pre-build] Starting Build Init
[build] Starting build with InvokeBuild.
[build] Parsing defined tasks
[build] Loading Configuration from C:\src\Sampler\build.yaml
Adding CopyPlaster
Adding build
Adding publish
Adding test
Adding .
[build] Executing requested workflow: ?

Name                                    Jobs
----                                    ----
Build_Module_ModuleBuilder              {}
Build_NestedModules_ModuleBuilder       {}
[...]

PS C:\src\Sampler> .\build.ps1 -Tasks noop
[pre-build] Starting Build Init
[build] Starting build with InvokeBuild.
[build] Parsing defined tasks
[build] Loading Configuration from C:\src\Sampler\build.yaml
Adding CopyPlaster
Adding build
Adding publish
Adding test
Adding .
[build] Executing requested workflow: noop
Build noop C:\src\Sampler\build.ps1
Redefined task '.'.

===============================================================
                        NOOP
Empty task, useful to test the bootstrap process
---------------------------------------------------------------
  /noop
  C:\src\Sampler\build.ps1:171

Done /noop 00:00:00.0240027
Build succeeded. 1 tasks, 0 errors, 0 warnings 00:00:04.4388686
```

Because the build tasks are `InvokeBuild` tasks, we can discover them
by using the `?` task (after we've resolved the dependencies):
`build.ps1 -Tasks ?`

If you only want to mak sure the environment is configured, or you only want to
resolve the dependency, you can call the built-in task `noop` which won't
do anything. The `requiredModules` should already be available to the session though.

- `build.ps1 -tasks noop` - This will just setup your missing environment variables
- `build.ps1 -tasks noop -ResolveDependency` - That one will bootstrap your environment & download required modules

## Sampler Build workflow

To better explain the features available, let's look at the `Sampler` module
and its configured workflow.

### Bootstrap and re-hydration process

This is the beginning of the build process so that anyone doing a git clone
can re-hydrate the project and start testing and producing the artefacts locally
with minimum environment dependency. You need `git`, `PowerShell` and
preferably `GitVersion` (but not mandatory).

This avoid the "it works on my machine" or removes the dependence on specific
tools (such as CI tool). It also ensures the build process can be run anywhere
the same way (whether behind a firewall, on a dev workstation or in a build agent)


- [x] Bootstrap (optional) the repository & resolve Dependencies (Module restore).
Handled by the `.build.ps1`'s **BEGIN** block, and `Resolve-Dependency.ps1`:

  - Assume nothing is set up, and you don't have Admin rights
  - pushd in `$PSScriptRoot`
  - Create `.\output` if not exist
  - Prepend `.\output` to your `$Env:PSModulePath`
  - If Nuget package provider not present, Install & Import nuget PackageProvider (Proxy enabled)
  - Update `$PSRepository`'s Installation Policy to Trusted for the duration of the build
  - Bootstrap PowerShellGet `if ($_.version -le '1.6.0')` to latest (Save-Module to `.\output\RequiredModules` or install to CurrentUser/AllUsers, Remove-Module -Force,  Import-Module -Force )
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

- [ ] Configure & Import the InvokeBuild tasks and workflow. Handled by the `.build.ps1`'s **PROCESS** block:

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

In our case, [the Build.psd1](build.yaml#L89) defines several workflows (., build, pack, hqrmtest,test, and publish) that can be called by using:
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
- **Pester_if_Code_Coverage_Under_Threshold**: This fails the build if the Pester Code Coverage is under the [configured](build.yaml#L69) threshold.

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
