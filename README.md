# Sampler Module [![Azure DevOps builds](https://img.shields.io/azure-devops/build/Synedgy/524b41a5-5330-4967-b2de-bed8fd44da08/1)](https://synedgy.visualstudio.com/Sampler/_build?definitionId=1&_a=summary)

[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/Sampler?label=Sampler%20Preview)](https://www.powershellgallery.com/packages/Sampler/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/Sampler?label=Sampler)](https://www.powershellgallery.com/packages/Sampler/)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/SynEdgy/Sampler/1)](https://synedgy.visualstudio.com/Sampler/_test/analytics?definitionId=1&contextType=build)
![Azure DevOps coverage](https://img.shields.io/azure-devops/coverage/Synedgy/Sampler/1)
![PowerShell Gallery](https://img.shields.io/powershellgallery/p/Sampler)

This project is used to scaffold a PowerShell module project complete with
PowerShell build and deploy pipeline automation.

The Sampler module in itself serves several purposes:

- Quickly scaffold a PowerShell module project that can build and enforce some good practices.
- Provide a minimum set of [InvokeBuild](https://github.com/nightroman/Invoke-Build)
tasks that help you build, test, pack and publish your module.
- Help building your module by adding elaborate sample elements like classes,
  MOF-based DSC resource, class-based DSC resource, helper module, embedded helper
  module, and more.
- Avoid the "it works on my machine" or removes the dependence on specific tools
  (such as a CI tool). 
- Ensures the build process can be run anywhere the same way (whether behind a
  firewall, on a developers workstation, or in a build agent).
- Assume nothing is set up, and you don't have Admin rights.
- Works cross-platform.

Check the video for a quick intro:

> _Note: The video was made when Sampler was young, and it has been a lot of_
> _iteration since then, so please also read the documentation below that_
> _reflects the improvements we made along the way._

[![Sampler demo video](https://img.youtube.com/vi/bbpFBsl8K9k/0.jpg)](https://www.youtube.com/watch?v=bbpFBsl8K9k&ab_channel=DSCCommunity)

## Prerequisites

### PowerShellGet

Because we resolve dependencies from a nuget feed, whether the public
PowerShellGallery or your private repository, a working version of
PowerShellGet is required. We recommend the latest version of PowerShellGet v2
(PowerShellGet v3 will be supported when it is released).

### Managing the Module versions (optional)

Managing the versions of your module is tedious, and it's hard to be consistent
over time. The usual tricks like checking what the latest version on the 
PSGallery is, or use the `BuildNumber` to increment a `0.0.x` version works but
aren't ideal, especially if we want to stick to [semver](https://semver.org/).

While you can manage the version by updating the module manifest manually or by
letting your CI tool update the `ModuleVersion` environment variable, we think
the best is to rely on the cross-platform tool [`GitVersion`](https://gitversion.net/docs/).

[`GitVersion`](https://gitversion.net/docs/) will generate the version based on
the git history. You control what version to deploy using [git tags](https://git-scm.com/book/en/v2/Git-Basics-Tagging).

As a rule of thumb, it will look at the latest version tag, and will look at
the branches and their name, or the commit messages, to try to update the
Major/Minor/Patch (semantic versioning) based on detected change (configurable
in the file [`GitVersion.yml`](https://gitversion.net/docs/reference/configuration)
that is part of your project).

What that means is that we recommend you to install `GitVersion` on your
development environment, and your CI.

See various way to [install GitVersion](https://gitversion.net/docs/usage/cli/installation)
on your development environment. If you use Chocolatey (install and upgrade):

```PowerShell
C:\> choco upgrade gitversion.portable
```

This describes how to [install GitVersion in your CI](https://gitversion.net/docs/usage/ci)
if you plan to use the deploy pipelines in the CI.

## Usage

### How to create a new project

To create a new project the command `New-SampleModule` should be used. Depending
on the template used with the command the content in project will contain
different sample content, some also add addition pipeline jobs. But all templates
(expect one) will have the basic tasks to have a working pipeline; build, test, deploy.

So below how to use each template. The templates are:

- `SimpleModule` - Creates a module with minimal structure and pipeline automation.
- `CompleteSample` - Creates a module with complete structure and example files.
- `SimpleModule_NoBuild` - Creates a simple module without the build automation.
- `dsccommunity` - Creates or replace the files needed for the conversion to the
  new release automation.
- `newDscCommunity` - Creates or replace the files needed for the conversion to
  the new release automation.
- `CustomModule` - Will prompt you for more details as to what you'd like to scaffold.

As per the video above, you can create a new module project with all files and
pipeline scripts. Once the project is created, the `build.ps1` inside the new
project is how you interact with the built-in pipeline automation, and the
file `build.yaml` is where you configure and customize it.

#### `SimpleModule`

Creates a module with minimal structure and pipeline automation.

```powershell
Install-Module -Name 'Sampler' -Scope 'CurrentUser'

$newSampleModuleParameters = @{
    DestinationPath   = 'C:\source\HelpUsers\johlju'
    ModuleType        = 'SimpleModule'
    ModuleName        = 'MySimpleModule'
    ModuleAuthor      = 'My Name'
    ModuleDescription = 'MySimpleModule Description'
}

New-SampleModule @newSampleModuleParameters
```

### How to download dependencies for project

To be able to build the project all the dependencies listed in the file
`RequiredModules.psd1` must first be available. This is the beginning of
the build process so that anyone doing a git clone can 're-hydrate' the
project and start testing and producing the artefact locally with minimum
environment dependency.

The following command will resolve dependencies:

```powershell
cd C:\source\MySimpleModule

./build.ps1 -ResolveDependency -Tasks noop
```

The dependencies will be downloaded (or updated) from the PSGallery (unless
changed to another repository) and saved in the project folder under
`./output/RequiredModules`.

> By default, each repository should not rely on your personal development
> environment, so that it's easier to repeat on any machine or build agent.

Normally this command only needs to be run once, but the command can be run
anytime to update to a newer version of a required module (if one is available),
or if the required modules have changed in the file `RequiredModules.psd1`.

> **Note:** If a required module is removed in the file `RequiredModules.psd1`
> that module will not be automatically removed from the folder
> `./output/RequiredModules`.

### How to build the project

The following command will build the project:

```powershell
cd C:\source\MySimpleModule

./build.ps1 -Tasks build
```

It is also possible to resolve dependencies and build the project
at the same time using the command:

```powershell
./build.ps1 -ResolveDependency -Tasks build
```

If there are any errors during build´it will be shown in the output and the
build will stop. If it is successful the output should end with:

```plaintext
Build succeeded. 7 tasks, 0 errors, 0 warnings 00:00:06.1049394
```

> **NOTE:** The number of tasks can differ depending on which template that
> was used to create the project.

### How to run tests

> **NOTE:** Which tests are run is determined by the paths configured
> by a key in the _Pester_ configuration in the file `build.yml`. The key
> differ depending on _Pester_ version used. The key is `Script` when using
> _Pester v4_, and `Path` when using _Pester v5_.

If running (or debugging) tests in Visual Studio Code you should first make sure
the session environment is set correctly. This is normally done when you build
the project. But if there is no need to rebuild the project it is faster to run
the following in the _PowerShell Integrated Console_:

```powershell
./build.ps1 -Tasks noop
```

This just runs the bootstrap, and then runs the built-in "no operation" (`noop`)
task which does nothing (there is no code that executes in that task).

### How to run the default workflow

It is possible to do all of the above (resolve dependencies, build, and run tests)
in just one line by running the following:

```powershell
./build -ResolveDependency
```

The parameter `Task` is not used which means this will run the default workflow
(`.`). The tasks for the default workflow is configured in the file `build.yml`.
Normally the default workflow builds the project and runs all the configured test.

This means by running this it will build and run all configured tests:

```powershell
./build.ps1
```

### How to list all available tasks

Because the build tasks are `InvokeBuild` tasks, we can discover them using
the `?` task. So to list the available tasks in a project, run the following 
command:

```powershell
./build.ps1 -Tasks ?
```

> **NOTE:** If it is not already done, first make sure to resolve dependencies.
> Dependencies can also hold tasks that is used in the pipeline.

## About the bootstrap process (`build.ps1`)

The `build.ps1` is the _entry point_ to invoke any task, or a list of build
tasks (workflow), leveraging the [`Invoke-Build`](https://www.powershellgallery.com/packages/InvokeBuild)
task runner.

The script do not assume your environment has the required PowerShell modules,
so the bootstrap is done by the project's script file `build.ps1`, and can
resolve the dependencies listed in the project's file `RequiredModules.psd1`
using [`PSDepend`](https://www.powershellgallery.com/packages/PSDepend).

Invoking `build.ps1` with the `-ResolveDependency` parameter will prepare your
environment like so:

1. Updates the session environment variable (`$env:PSModulePath`) to resolve
   the built module (`.\output`) and the modules in the folder `./output/RequiredModules`
   by prepending those paths to `$env:PSModulePath`. By prepending the paths
   to the session `$env:PSModulePath` the build process will make those
   dependencies available in your session for module discovery and auto-loading,
   and also possible to use one or more of those modules as part of your built
   module.
1. Making sure you have a trustable version of the module _PowerShellGet_ and
   _PackageManagement_ (`version -gt 1.6`), or it will install it from the
   configured repository.
1. Download or install the `PowerShell-yaml` and `PSDepend` modules needed
   for further dependency management.
1. Read the `build.yaml` configuration.
1. If Nuget package provider not present, install and import nuget PackageProvider
   (proxy enabled).
1. Invoke [PSDepend](https://www.powershellgallery.com/packages/PSDepend) on
   the file `RequiredModules.psd1`. It will not install required modules to
   your environment, it will save them to your project's folder `./output/RequiredModules`.
1. Hand over the task executions to `Invoke-Build` to run the configured
   workflow.

If you only want to make sure the environment is configured, or you only want
to resolve the dependencies, you can call the built-in task `noop` which won't
do anything. But for the built-in `noop` task to work, the dependencies
must first have been resolved.

## About Sampler build workflow

Let's look at the pipeline of the `Sampler` module itself to better explain
how the pipeline automation is configured for a project created using a
template from the Sampler module.

> **NOTE:** Depending on the Sampler template used when creating a new project
> there can be addition configuration options - but they can all be added
> manually those options are needed. The Sampler project itself is not using all
> features available (an example is DSC resources documentation generation).

### Default Workflow Currently configured

As seen in the bootstrap process above, the different workflows can be configured by editing the `build.psd1`: new tasks can be loaded, and the sequence can be added under the `BuildWorkflow` key by listing the names.

In our case, the [build.yaml](build.yaml) defines several workflows (`.`, `build`, `pack`, `hqrmtest`, `test`, and `publish`) that can be called by using:

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

It is also possible to set the session environment variable `$env:ModuleVersion`
in the PowerShell session, or setting the variable `$ModuleVersion` in the
PowerShell session (the parent scope to `Invoke-Build`) before running the
task `build`

This `ModuleVersion` task variable can be overridden by using the key `SemVer`
in the file `build.yml`, e.g. `SemVer: '99.0.0-preview1'`. This can be used
if the preferred method of using GitVersion is not available.

The order how the module version is detected is as follows:

1. the parameter `ModuleVersion` is set from the command line (passing parameter
   to build task)
1. if no parameter was passed it defaults to using the property from the
   environment variable `$env:ModuleVersion` or parent scope variable
   `$ModuleVersion`
1. if the `ModuleVersion` is still not found it will try to use `GitVersion`
   if it is available
1. if `GitVersion` is not available the module version is set from the module
   manifest in the source path using the properties `ModuleVersion` and
   `PrivateData.PSData.Prerelease`
1. if module version is set using key `SemVer` in `build.yml` it will
   override 1), 2), 3), and 4)
1. ~~if `SemVar` is set through parameter from the command line then it will~~
   ~~override 1), 2), 3), 4), and 5)~~ Not supported today.

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
