# Sampler Module [![Azure DevOps builds](https://img.shields.io/azure-devops/build/Synedgy/524b41a5-5330-4967-b2de-bed8fd44da08/1)](https://synedgy.visualstudio.com/Sampler/_build?definitionId=1&_a=summary)

[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/Sampler?label=Sampler%20Preview)](https://www.powershellgallery.com/packages/Sampler/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/Sampler?label=Sampler)](https://www.powershellgallery.com/packages/Sampler/)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/SynEdgy/Sampler/1)](https://synedgy.visualstudio.com/Sampler/_test/analytics?definitionId=1&contextType=build)
![Azure DevOps coverage](https://img.shields.io/azure-devops/coverage/Synedgy/Sampler/1)
![PowerShell Gallery](https://img.shields.io/powershellgallery/p/Sampler)

## 1. Description

This project is used to scaffold a PowerShell module project, complete with
PowerShell build, test and deploy pipeline automation.

The `Sampler` module in itself serves several purposes:

- Quickly scaffold a PowerShell module project that can build and enforce some good practices.
- Provide a minimum set of [InvokeBuild](https://github.com/nightroman/Invoke-Build)
tasks that help you build, test, pack and publish your module.
- Help building your module by adding elaborate sample elements like classes,
  MOF-based DSC resources, class-based DSC resources, helper modules, embedded helper
  modules, and more.
- Avoid the "it works on my machine" and remove the dependence on specific tools
  (such as a CI tool).
- Ensures the build process can be run anywhere the same way (whether behind a
  firewall, on a developers workstation, or in a build agent).
- Assume nothing is set up, and you don't have local administrator rights.
- Works on Windows, Linux and MacOS.

Check the video for a quick intro:

[![Modern PowerShell module Development](https://img.youtube.com/vi/_Hr6CeTKbLc/0.jpg)](https://www.youtube.com/watch?v=_Hr6CeTKbLc)

> _Note:_ The video only shows a tiny part of the `Sampler` usage.  
> Make sure to read the additional documentation in the configuration files and the
> Getting started section in the [Sampler - Wiki][1].

## 2. Prerequisites

- PowerShell 5.x or PowerShell 7.x

The `build.ps1` script will download all other specified modules required into the `RequiredModules` folder of your module project for you.

## 3. Usage

### How to create a new project

To create a new project, the command `New-SampleModule` should be used. Depending
on the template used with the command the content in project will contain
different sample content while some also adds additional pipeline jobs. But all
templates (except one) will have the basic tasks to have a working pipeline including
build, test and deploy stages.

The templates are:

- `SimpleModule` - Creates a module with minimal structure and pipeline automation.
- `SimpleModule_NoBuild` - Creates a simple module without the build automation.
- `CompleteSample` - Creates a module with complete structure and example files.
- `dsccommunity` - Creates a DSC module according to the DSC Community baseline
   with a pipeline for build, test, and release automation.
- `CustomModule` - Will prompt you for more details as to what you'd like to scaffold.
- `GCPackage` - Creates a module that can be deployed to be used with _Azure Policy_
  _Guest Configuration_.

As per the video above, you can create a new module project with all files and
pipeline scripts. Once the project is created, the `build.ps1` inside the new
project folder is how you interact with the built-in pipeline automation, and
the file `build.yaml` is where you configure and customize it.

The section below shows only how to create a new module using the `SimpleModule` template.  
For the complete `Getting Started` instructions, **please see** the [Sampler - Wiki][1].

#### SimpleModule

Creates a module with minimal structure and pipeline automation.

```powershell
Install-Module -Name 'Sampler' -Scope 'CurrentUser'

$NewSampleModuleParameters = @{
    DestinationPath   = 'C:\source'
    ModuleType        = 'SimpleModule'
    ModuleName        = 'MySimpleModule'
    ModuleAuthor      = 'My Name'
    ModuleDescription = 'MySimpleModule Description'
}

New-SampleModule @NewSampleModuleParameters
```

See the [Sampler - Wiki][1] for additional examples.

## 4. References and links

* [Sampler - Wiki][1]

## 5. Change log

A full list of changes in each version can be found in the [change log][2].

[1]: https://github.com/gaelcolas/Sampler/wiki
[2]: https://github.com/gaelcolas/Sampler/blob/main/CHANGELOG.md
