# Sampler Module [![Azure DevOps builds](https://img.shields.io/azure-devops/build/Synedgy/524b41a5-5330-4967-b2de-bed8fd44da08/1)](https://synedgy.visualstudio.com/Sampler/_build?definitionId=1&_a=summary)

[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/Sampler?label=Sampler%20Preview)](https://www.powershellgallery.com/packages/Sampler/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/Sampler?label=Sampler)](https://www.powershellgallery.com/packages/Sampler/)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/SynEdgy/Sampler/1)](https://synedgy.visualstudio.com/Sampler/_test/analytics?definitionId=1&contextType=build)
![Azure DevOps coverage](https://img.shields.io/azure-devops/coverage/Synedgy/Sampler/1)
![PowerShell Gallery](https://img.shields.io/powershellgallery/p/Sampler)

This project is a Module and template of a PowerShell module and DSC Resources with its
PowerShell Build Pipeline automation.

Check the video for a quick intro:  
[![Sampler demo video](https://img.youtube.com/vi/bbpFBsl8K9k/0.jpg)](https://www.youtube.com/watch?v=bbpFBsl8K9k&ab_channel=DSCCommunity)

The Sampler module in itself serves several purposes:

- Quickly scaffold a PowerShell module project that can build and enforce some good practices.
- Provide a minimum set of [InvokeBuild](https://github.com/nightroman/Invoke-Build)
tasks that help you build, test, pack and publish your module.
- Help building your module with adding dummy but elaborate elements to your module (Classes, DSC Resources, Class DSC Resource, Helper Module, Embedded helper module...).

## Preqrequisites

### __PowerShellGet__

Because we resolve dependencies from a nuget feed, whether the public PowerShellGallery or your private repository, a working version of PowerShellGallery is required.

We recommend the latest version of PowerShellv2.

### __Managing the Module versions__

Managing the versions of your module is tedious, and it's
hard to be consistent over time.
The usual tricks like checking what the latest version on the PSGallery is, or use the `BuildNumber` to increment a `0.0.x`
version works but aren't ideal, especially if we want to stick to [semver](https://semver.org/).

While you can manage the version by updating the psd1 or letting your CI tool to update the `ModuleVersion` environment variable, we thing the best is to rely on [`GitVersion`](https://gitversion.net/docs/).

GitVersion will generate the version for you, based on the git history.

As a rule of thumb, it will look at the latest version tag, and will look at the branches and their name, or the commit messages, to try to update the Major/Minor/Patch based on detected change (configurable in [`GitVersion.yml`](GitVersion.yml)).

What that means is that we recommend you to install
`GitVersion` on your dev environent, and your CI.

If you use choco:
```PowerShell
C:\> choco upgrade gitversion.portable
```
---

## Usage

As per the video above, you can create a new Module project with all files & and pipeline scripts,
the `build.ps1` is how you interact with the built-in pipeline automation, and
`build.yaml` how you configure and customize it.

### Bootstrapping repository and Resolve-Dependency

Quick Start:

```PowerShell
PS C:\src\Sampler> .\build.ps1
```

The `build.ps1` is the _entry point_ to invoke any task or a list of build tasks (workflow),
leveraging the [`Invoke-Build`](https://www.powershellgallery.com/packages/InvokeBuild/) task runner.

The script do not assume your environment has the required PowerShell modules,
so the `bootstrap` is done by `build.ps1`, and can resolves the dependencies listed
in [`RequiredModules.psd1`](RequiredModules.psd1) using `PSDepend`.

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
>it will save them to the `output/RequiredModules` folder
>of your repository.
>
>By also prepending this path to your `$Env:PSModulePath`,
>the build process will make those dependencies available in your session for
>module discovery and auto-loading.

Once the `-ResolveDependency` has been called once, there should not be a need
to call it again until the `RequiredModules.psd1` is changed.

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
`.\build.ps1 -Tasks ?`

If you only want to mak sure the environment is configured, or you only want to
resolve the dependency, you can call the built-in task `noop` which won't
do anything. The `requiredModules` should already be available to the session though.

- `.\build.ps1 -tasks noop` - This will just setup your missing environment variables
- `.\build.ps1 -tasks noop -ResolveDependency` - That one will bootstrap your environment & download required modules

## Task Variables

A task variable is used in a build task and it can be added as a script
parameter to build.ps1, set as as an environment variable, and can often
be used if defined in parent scope or read from the $BuildInfo properties
defined in the configuration file.

### `BuildModuleOutput`

The path where the module will be built. The path will for example
be used for the parameter `OutputDirectory` when calling the cmdlet
`Build-Module` of the PowerShell module _Invoke-Build_. Defaults to
the path for `OutputDirectory`, and concatenated with `BuiltModuleSubdirectory`
if it is set.

### `BuiltModuleSubdirectory`

An optional path that will suffix the `OutputDirectory` to build the
default path in variable `BuildModuleOutput`.

### `ModuleVersion`

The module version of the built module. Defaults to the property `NuGetVersionV2`
returned by the executable `gitversion`, or if the executable `gitversion`
is not available the the variable defaults to an empty string, and the
build module task will use the version found in the Module Manifest.

### `OutputDirectory`

The base directory of all output from the build tasks. This is the path
where artifacts will be built or saved such as the built module, required
modules downloaded at build time, test results, etc. This folder should
be ignored by git as its content is ephemeral. It defaults to the folder
'output', a path relative to the root of the repository (same as `Invoke-Build`'s
[`$BuildRoot`](https://github.com/nightroman/Invoke-Build/wiki/Special-Variables#buildroot)).
You can override this setting with an absolute path should you need to.

### `ProjectPath`

The root path to the project. Defaults to [`$BuildRoot`](https://github.com/nightroman/Invoke-Build/wiki/Special-Variables#buildroot).

### `ProjectName`

The project name. Defaults to the BaseName of the module manifest it finds
in either the folder 'source', 'src, or a folder with the same name as the
module.

### `ReleaseNotesPath`

THe path to the release notes markdown file. Defaults to the path for
`OutputDirectory` concatenated with `ReleaseNotes.md`.

### `SourcePath`

The path to the source folder. Defaults to the same path where the module
manifest is found in either the folder 'source', 'src', or a folder with
the same name as the module.

## Sampler Build workflow

To better explain the features available, let's look at the `Sampler` module
and its configured workflow.

### Bootstrap and re-hydration process

This is the beginning of the build process so that anyone doing a git clone
can 're-hydrate' the project and start testing and producing the artefacts locally
with minimum environment dependency. You need `git`, `PowerShell` and
preferably `GitVersion`.

This avoid the "it works on my machine" or removes the dependence on specific
tools (such as CI tool). It also ensures the build process can be run anywhere
the same way (whether behind a firewall, on a dev workstation or in a build agent)


- Bootstrap the repository & resolve Dependencies (Module restore).

  - Assume nothing is set up, and you don't have Admin rights
  - Prepend `.\output\RequiredModules` to your `$Env:PSModulePath`
  - Prepend `.\output\` to your `$Env:PSModulePath`
  - If Nuget package provider not present, Install & Import nuget PackageProvider (Proxy enabled)
  - Invoke PSDepend based on the dependency file [.\RequiredModules.psd1](RequiredModules.psd1)
  - Hand back over to InvokeBuild task, loaded as per the [`build.yml`](build.yaml)

  > Example:
  >
  > `C:\ > .\build.ps1 -ResolveDependency -Tasks noop`
  >
  > This should setup your project folder by re-hydrating all required dependencies to build and test your module, and invoke the (empty) task `noop`, so that it does not invoke the default workflow '.'
  >
  > The `-ResolveDependency` does not need to be invoked again to speed things up, unless a dependency file/version changes
  >
  > The Second run could be:
  >
  > `C:\ > .\build.ps1 -Tasks noop`


### Default Workflow Currently configured

As seen in the bootstrap process above, the different workflows can be configured by editing the `build.psd1`: new tasks can be loaded, and the sequence can be added under the `BuildWorkflow` key by listing the names.

In our case, [the Build.yaml](build.yaml) defines several workflows (`.`, `build`, `pack`, `hqrmtest`, `test`, and `publish`) that can be called by using:

```PowerShell
 .\build.ps1 -Tasks <Workflow_or_task_Name>
```

The detail of the **default workflow** is as follow (InvokeBuild defaults to the workflow named '.' when no tasks is specified):

```yml
BuildWorkflow:
  '.':
    - build
    - test
```

The tasks `build` and `tests` are meta-tasks or workflow calling other tasks:

```yml
  build:
    - Clean
    - Build_Module_ModuleBuilder
    - Build_NestedModules_ModuleBuilder
    - Create_changelog_release_output
  test:
    - Pester_Tests_Stop_On_Fail
    - Pester_if_Code_Coverage_Under_Threshold
    - hqrmtest
```

Those tasks are imported from a module, in this case from
the `.build/` folder, from this `Sampler` module,
but for another module you would use this line in your `build.yml` config:

```yaml
ModuleBuildTasks:
  Sampler:
    - '*.build.Sampler.ib.tasks' # this means: import (dot source) all aliases ending with .ib.tasks exported by 'Sampler' module
```

You can edit your `build.yml` to change the workflow, add a custom task,
create repository-specific task in a `.build/` folder named `*.build.ps1`.

```yml
  MyTask: {
    # do something with some PowerShellCode
    Write-Host "Doing something in a task"
  }

  build:
    - Clean
    - MyTask
    - call_another_task
```
