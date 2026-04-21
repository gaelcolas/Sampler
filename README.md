
# Sampler Module [![Azure DevOps builds](https://img.shields.io/azure-devops/build/Synedgy/524b41a5-5330-4967-b2de-bed8fd44da08/1)](https://synedgy.visualstudio.com/Sampler/_build?definitionId=1&_a=summary) <img align="right" width="110" height="110" src="Sampler/assets/sampler.png">  

[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/v/Sampler?label=Sampler%20Preview&include_prereleases)](https://www.powershellgallery.com/packages/Sampler/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/Sampler?label=Sampler)](https://www.powershellgallery.com/packages/Sampler/)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/SynEdgy/Sampler/1)](https://synedgy.visualstudio.com/Sampler/_test/analytics?definitionId=1&contextType=build)
![Azure DevOps coverage](https://img.shields.io/azure-devops/coverage/Synedgy/Sampler/1)
![PowerShell Gallery](https://img.shields.io/powershellgallery/p/Sampler)

Sampler is an opinionated scaffolding and build-automation framework for
PowerShell module projects. It gives you a production-ready project
structure, a reproducible build pipeline powered by
[InvokeBuild](https://github.com/nightroman/Invoke-Build), and a library
of reusable tasks — so you can focus on writing your module instead of
maintaining infrastructure.

## Why Sampler?

- **Scaffold in seconds**: Generate a new module project with built-in
  CI/CD support, code-quality checks, and best-practice conventions.
- **Build, test, pack & publish**: A curated set of InvokeBuild tasks
  covers the full lifecycle from source to the PowerShell Gallery.
- **Rich templates**: Add classes, MOF-based DSC resources, class-based
  DSC resources, helper modules, composite resources, and more with a
  single command.
- **Reproducible everywhere**: The same build runs on a developer
  workstation, behind a corporate firewall, or in a CI agent — no
  local-admin rights or pre-installed tooling required.
- **Cross-platform**: Works on Windows, Linux, and macOS.

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
>[!NOTE]
>Change the `DestinationPath` to the location where the module should be created depending on you platform and workflow.

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
Calls git to set user name in the git config.

### `New-SampleModule`

This command helps you scaffold your PowerShell module project by creating
the folder structure of your module, and optionally add the pipeline files
to help with compiling the module, publishing to a repository like
_PowerShell Gallery_ and GitHub, and testing quality and style such as
per the DSC Community guidelines.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
New-SampleModule -DestinationPath <String> [-ModuleType <String>] [-ModuleAuthor <String>]
  -ModuleName <String> [-ModuleDescription <String>] [-CustomRepo <String>]
  [-ModuleVersion <String>] [-LicenseType <String>] [-SourceDirectory <String>]
  [<CommonParameters>]

New-SampleModule -DestinationPath <String> [-ModuleAuthor <String>] -ModuleName <String>
  [-ModuleDescription <String>] [-CustomRepo <String>] [-ModuleVersion <String>]
  [-LicenseType <String>] [-SourceDirectory <String>] [-Features <String[]>]
  [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

None.

#### Example

See section [Usage](#usage).

## Commands for Build Tasks

These commands are primarily meant to be used in tasks that exist either
in Sampler or in third-party modules.

Refer to the comment-based help for more information about these commands.

### `Convert-SamplerHashtableToString`

Convert a Hashtable to a string representation. For instance, calling the
function with this hashtable:

```powershell
@{a=1;b=2; c=3; d=@{dd='abcd'}}
```

will return:

```plaintext
a=1; b=2; c=3; d={dd=abcd}
```

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Convert-SamplerHashtableToString [[-Hashtable] <Hashtable>] [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

`[System.String]`

#### Example

```powershell
Convert-SamplerhashtableToString -Hashtable @{a=1;b=2; c=3; d=@{dd='abcd'}}
```

This example will return the string representation of the provided hashtable.

### `Get-BuiltModuleVersion`

Will read the properties `ModuleVersion` and `PrivateData.PSData.Prerelease` tag
of the module manifest for a module that has been built by Sampler. The command
looks into the **OutputDirectory** where the project's module should have been
built.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Get-BuiltModuleVersion [-OutputDirectory] <String> [[-BuiltModuleSubdirectory] <String>]
  [-ModuleName] <String> [-VersionedOutputDirectory] [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

`[System.String]`

#### Example

```powershell
Get-BuiltModuleVersion -OutputDirectory 'output' -ProjectName 'MyModuleName'
```

This example will return the module version of the built module 'MyModuleName'.

### `Get-ClassBasedResourceName`

This command returns all the class-based DSC resource names in a script file.
The script file is parsed for classes with the `[DscResource()]` attribute.

> **Note:** For MOF-based DSC resources, look at the command
>[`Get-MofSchemaName`](#get-mofschemaname).

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Get-ClassBasedResourceName [-Path] <String> [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

`[System.String]`

#### Example

```powershell
Get-ClassBasedResourceName -Path 'source/Classes/MyDscResource.ps1'
```

This example will return the class-based DSC resource names in the script
file **MyDscResource.ps1**.

<!-- markdownlint-disable MD013 - Line length -->
```powershell
Import-Module -Name 'MyResourceModule'

$module = Get-Module -Name 'MyResourceModule'

Get-ClassBasedResourceName -Path (Join-Path -Path $module.ModuleBase -ChildPath $module.RootModule)
```
<!-- markdownlint-enable MD013 - Line length -->

This example will return the class-based DSC resource names in built module
script file for the module named 'MyResourceModule'.

### `Get-CodeCoverageThreshold`

This command returns the **CodeCoverageThreshold** from the build configuration
(or overridden if the parameter `RuntimeCodeCoverageThreshold` is passed).

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Get-CodeCoverageThreshold [[-RuntimeCodeCoverageThreshold] <String>]
  [[-BuildInfo] <PSObject>] [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

`[System.Int]`

#### Example

```powershell
Get-CodeCoverageThreshold -RuntimeCodeCoverageThreshold 0
```

This example will override the code coverage threshold in the build
configuration and return the value pass in the parameter **RuntimeCodeCoverageThreshold**.

### `Get-MofSchemaName`

This command looks within a DSC resource's .MOF schema file to find the name
and friendly name of the class.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Get-MofSchemaName [-Path] <String> [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

`[System.Collections.Hashtable]`

| Property Name | Type              | Description                    |
| ------------- | ----------------- | ------------------------------ |
| Name          | `[System.String]` | The name of class              |
| FriendlyName  | `[System.String]` | The friendly name of the class |

#### Example

```powershell
Get-MofSchemaName -Path Source/DSCResources/MyResource/MyResource.schema.mof
```

This example will return a hashtable containing the name and friendly name
of the MOF-based resource **MyResource**.

### `Get-OperatingSystemShortName`

This command tells what the platform is; `Windows`, `Linux`, or `MacOS`.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Get-OperatingSystemShortName [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

`[System.String]`

#### Example

```powershell
Get-OperatingSystemShortName
```

This example will return what platform it is run on.

### `Get-PesterOutputFileFileName`

This command creates a file name to be used as Pester output XML file name.
The file name will be composed in the format:
`${ProjectName}_v${ModuleVersion}.${OsShortName}.${PowerShellVersion}.xml`

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Get-OperatingSystemShortName [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

`[System.String]`

#### Example

<!-- markdownlint-disable MD013 - Line length -->
```powershell
Get-PesterOutputFileFileName -ProjectName 'Sampler' -ModuleVersion '0.110.4-preview001' -OsShortName 'Windows' -PowerShellVersion '5.1'
```
<!-- markdownlint-enable MD013 - Line length -->

This example will return the string `Sampler_v0.110.4-preview001.Windows.5.1.xml`.

### `Get-SamplerAbsolutePath`

This command will resolve the absolute value of a path, whether it's
potentially relative to another path, relative to the current working
directory, or it's provided with an absolute path.

The path does not need to exist, but the command will use the right
`[System.Io.Path]::DirectorySeparatorChar` for the OS, and adjust the
`..` and `.` of a path by removing parts of a path when needed.

> **Note:**  When the root drive is omitted on Windows, the path is not
> considered absolute.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Get-SamplerAbsolutePath [[-Path] <String>] [[-RelativeTo] <String>] [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

`[System.String]`

#### Example

```powershell
Get-SamplerAbsolutePath -Path '/src' -RelativeTo 'C:\Windows'
```

This example will return the string `C:\src` on Windows.

```powershell
Get-SamplerAbsolutePath -Path 'MySubFolder' -RelativeTo '/src'
```

This example will return the string `C:\src\MySubFolder` on Windows.

### `Get-SamplerBuiltModuleBase`

This command returns the module base of the built module.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Get-SamplerBuiltModuleBase [-OutputDirectory] <String> [[-BuiltModuleSubdirectory] <String>]
  [-ModuleName] <String> [-VersionedOutputDirectory] [[-ModuleVersion] <String>]
  [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

`[System.String]`

#### Example

<!-- markdownlint-disable MD013 - Line length -->
```powershell
Get-SamplerBuiltModuleBase -OutputDirectory 'C:\src\output' -BuiltModuleSubdirectory 'Module' -ModuleName 'stuff' -ModuleVersion '3.1.2-preview001'
```
<!-- markdownlint-enable MD013 - Line length -->

This example will return the string `C:\src\output\Module\stuff\3.1.2`.

### `Get-SamplerBuiltModuleManifest`

This command returns the path to the built module's manifest.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Get-SamplerBuiltModuleManifest [-OutputDirectory] <String> [[-BuiltModuleSubdirectory] <String>]
  [-ModuleName] <String> [-VersionedOutputDirectory] [[-ModuleVersion] <String>] [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

`[System.String]`

#### Example

<!-- markdownlint-disable MD013 - Line length -->
```powershell
Get-SamplerBuiltModuleManifest -OutputDirectory 'C:\src\output' -BuiltModuleSubdirectory 'Module' -ModuleName 'stuff' -ModuleVersion '3.1.2-preview001'
```
<!-- markdownlint-enable MD013 - Line length -->

This example will return the string `C:\src\output\Module\stuff\3.1.2\stuff.psd1`.

### `Get-SamplerCodeCoverageOutputFile`

This command resolves the code coverage output file path from the project's
build configuration.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Get-SamplerCodeCoverageOutputFile [-BuildInfo] <PSObject> [-PesterOutputFolder] <String>
  [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

`[System.String]`

#### Example

<!-- markdownlint-disable MD013 - Line length -->
```powershell
Get-SamplerCodeCoverageOutputFile -BuildInfo $buildInfo -PesterOutputFolder 'C:\src\MyModule\Output\testResults'
```
<!-- markdownlint-enable MD013 - Line length -->

This example will return the code coverage output file path.

### `Get-SamplerCodeCoverageOutputFileEncoding`

This command resolves the code coverage output file encoding from the project's
build configuration.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Get-SamplerCodeCoverageOutputFileEncoding [-BuildInfo] <PSObject> [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

`[System.String]`

#### Example

<!-- markdownlint-disable MD013 - Line length -->
```powershell
Get-SamplerCodeCoverageOutputFileEncoding -BuildInfo $buildInfo
```
<!-- markdownlint-enable MD013 - Line length -->

This example will return the code coverage output file encoding.

### `Get-SamplerModuleInfo`

This command loads a module manifest and returns the hashtable.
This implementation works around the issue where Windows PowerShell has
issues with the pwsh `$env:PSModulePath` such as in _VS Code_ with the _VS Code_
_PowerShell extension_.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Get-SamplerModuleInfo [-ModuleManifestPath] <String> [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

`[System.Collections.Hashtable]`

#### Example

<!-- markdownlint-disable MD013 - Line length -->
```powershell
Get-SamplerModuleInfo -ModuleManifestPath 'C:\src\MyProject\output\MyProject\MyProject.psd1'
```
<!-- markdownlint-enable MD013 - Line length -->

This example will return the module manifest's hashtable.

### `Get-SamplerModuleRootPath`

This command reads the module manifest (.psd1) and if the `ModuleRoot` property
is defined it will resolve its absolute path based on the module manifest's
path. If there is no `ModuleRoot` property defined, then this function will
return `$null`.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Get-SamplerModuleRootPath [-ModuleManifestPath] <String> [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

`[System.String]`

#### Example

<!-- markdownlint-disable MD013 - Line length -->
```powershell
Get-SamplerModuleRootPath -ModuleManifestPath C:\src\MyModule\output\MyModule\2.3.4\MyModule.psd1
```
<!-- markdownlint-enable MD013 - Line length -->

This example will return the path to module script file, e.g. `C:\src\MyModule\output\MyModule\2.3.4\MyModule.psm1`.

### `Get-SamplerProjectName`

This command returns the project name based on the module manifest, if no
module manifest is available it will return `$null`.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Get-SamplerProjectName [-BuildRoot] <String> [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

`[System.String]`

#### Example

```powershell
Get-SamplerProjectName -BuildRoot 'C:\src\MyModule'
```

This example will return the project name of the module in the path `C:\src\MyModule`.

### `Get-SamplerSourcePath`

This command returns the project's source path based on the module manifest,
if no module manifest is available it will return `$null`.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Get-SamplerSourcePath [-BuildRoot] <String> [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

`[System.String]`

#### Example

```powershell
Get-SamplerSourcePath -BuildRoot 'C:\src\MyModule'
```

This example will return the project's source path of the module in the
path `C:\src\MyModule`.

### `Merge-JaCoCoReport`

This command merges two JaCoCo reports and return the resulting merged JaCoCo
report.

> **Note:** Also see the command [Update-JaCoCoStatistic](#ppdate-jacocostatistic).

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Merge-JaCoCoReport [-OriginalDocument] <XmlDocument> [-MergeDocument] <XmlDocument>
  [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

`[System.Xml.XmlDocument]`

#### Example

<!-- markdownlint-disable MD013 - Line length -->
```powershell
Merge-JaCoCoReport -OriginalDocument 'C:\src\MyModule\Output\JaCoCoRun_linux.xml' -MergeDocument 'C:\src\MyModule\Output\JaCoCoRun_windows.xml'
```
<!-- markdownlint-enable MD013 - Line length -->

This example will merge the JaCoCo report `JaCoCoRun_windows.xml` into the
JaCoCo report `JaCoCoRun_linux.xml` and then return the resulting JaCoCo report.

### `New-SamplerJaCoCoDocument`

This command creates a new JaCoCo XML document based on the provided missed
and hit lines. This command is usually used together with the output object
from Pester that also have been passed through ModuleBuilder's command
`Convert-LineNumber`.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
New-SamplerJaCoCoDocument [-MissedCommands] <Object[]> [-HitCommands] <Object[]>
  [-PackageName] <String> [[-PackageDisplayName] <String>] [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

`[System.Xml.XmlDocument]`

#### Example

<!-- markdownlint-disable MD013 - Line length -->
```powershell
# Assuming Pester 4, for Pester 5 change the commands accordingly.
$pesterObject = Invoke-Pester ./tests/unit -CodeCoverage -PassThru

$pesterObject.CodeCoverage.MissedCommands |
   Convert-LineNumber -ErrorAction 'Stop' -PassThru | Out-Null

$pesterObject.CodeCoverage.HitCommands |
   Convert-LineNumber -ErrorAction 'Stop' -PassThru | Out-Null

New-SamplerJaCoCoDocument `
   -MissedCommands $pesterObject.CodeCoverage.MissedCommands `
   -HitCommands $pesterObject.CodeCoverage.HitCommands `
   -PackageName 'source'
```
<!-- markdownlint-enable MD013 - Line length -->

This example will create a new JaCoCo report based on the commands that
was hit or missed from the Pester run. It will use the ModuleBuilder's
command `Convert-LineNumber` to correlate the correct line number from
the built module script file to the source script files.

<!-- markdownlint-disable MD013 - Line length -->
```powershell
New-SamplerJaCoCoDocument `
   -MissedCommands @{
         Class            = 'ResourceBase'
         Function         = 'Compare'
         HitCount         = 0
         SourceFile       = '.\Classes\001.ResourceBase.ps1'
         SourceLineNumber = 4
   } `
   -HitCommands @{
         Class            = 'ResourceBase'
         Function         = 'Compare'
         HitCount         = 2
         SourceFile       = '.\Classes\001.ResourceBase.ps1'
         SourceLineNumber = 3
   } `
   -PackageName 'source'
```
<!-- markdownlint-enable MD013 - Line length -->

This example will create a new JaCoCo report based on the two hashtables
containing hit or missed line.

### `Out-SamplerXml`

This command outputs an XML document to the file specified in the parameter
**Path**.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Out-SamplerXml [-XmlDocument] <XmlDocument> [-Path] <String> [[-Encoding] <String>]
  [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

None.

#### Example

<!-- markdownlint-disable MD013 - Line length -->
```powershell
Out-SamplerXml -Path 'C:\temp\my.xml' -XmlDocument '<?xml version="1.0"?><a><b /></a>' -Encoding 'UTF8'
```
<!-- markdownlint-enable MD013 - Line length -->

This example will create a new XML file based on the XML document passed
in the parameter **XmlDocument**.

### `Set-SamplerTaskVariable`

This is an alias that points to a script file that is meant to be dot-sourced
from (in) a build task. The script will set common task variables for a build
task. This function should normally never be called outside of a build task, but
an exception can be tests; tests can call the alias to set the values prior to
running tests.

> **Note:** Running the command `Get-Help -Name 'Set-SamplerTaskVariable'` will
> only return help for the alias. To see the comment-based help for the script,
> run:
>
> ```powershell
> Import-Module -Name Sampler
>
> Get-Help -Name (Get-Alias -Name 'Set-SamplerTaskVariable').Definition -Detailed
> ```

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Set-SamplerTaskVariable [-AsNewBuild] [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

None. Sets variables in the current PowerShell session. See comment-based help
for more information about the variables that are set.

#### Example

<!-- markdownlint-disable MD013 - Line length -->
```powershell
. Set-SamplerTaskVariable
```
<!-- markdownlint-enable MD013 - Line length -->

Call the scriptblock and tells the script to evaluate the module version
by not checking after the module manifest in the built module.

<!-- markdownlint-disable MD013 - Line length -->
```powershell
. Set-SamplerTaskVariable -AsNewBuild
```
<!-- markdownlint-enable MD013 - Line length -->

Call the scriptblock set script variables. The parameter **AsNewBuild** tells
the script to skip variables that can only be set when the module has been
built.

### `Split-ModuleVersion`

This command parses a SemVer2 version string, and also a version string returned
by a certain property of GitVersion (containing additional metadata).

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Split-ModuleVersion [[-ModuleVersion] <String>] [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

`[System.Management.Automation.PSCustomObject]`

| Property Name    | Type              | Description                                    |
| ---------------- | ----------------- | ---------------------------------------------- |
| Version          | `[System.String]` | The module version (without prerelease string) |
| PreReleaseString | `[System.String]` | The prerelease string part                     |
| ModuleVersion    | `[System.String]` | The full semantic version                      |

#### Example

<!-- markdownlint-disable MD013 - Line length -->
```powershell
Split-ModuleVersion -ModuleVersion '1.15.0-pr0224-0022+Sha.47ae45eb2cfed02b249f239a7c55e5c71b26ab76.Date.2020-01-07'
```
<!-- markdownlint-enable MD013 - Line length -->

This example will return a hashtable with the different parts of the module
version for a version string that was returned by GitVersion.

### `Update-JaCoCoStatistic`

This command updates statistics of a JaCoCo report. This is meant to be
run after the command [`Merge-JaCoCoReport`](#merge-jacocoreport) has been
used.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Update-JaCoCoStatistic [-Document] <XmlDocument> [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

`[System.Xml.XmlDocument]`

#### Example

<!-- markdownlint-disable MD013 - Line length -->
```powershell
Update-JaCoCoStatistic -Document (Merge-JaCoCoReport OriginalDocument $report1 -MergeDocument $report2)
```
<!-- markdownlint-enable MD013 - Line length -->

This example will return a XML document containing the JaCoCo report with
the updated statistics.

## Build Task Variables

A task variable is used in a build task and it can be added as a script
parameter to build.ps1 or set as as an environment variable. It can often
be used if defined in parent scope or read from the $BuildInfo properties
defined in the configuration file.

### `BuildModuleOutput`

This is the path where the module will be built. The path will, for example,
be used for the parameter `OutputDirectory` when calling the cmdlet
`Build-Module` of the PowerShell module _Invoke-Build_. Defaults to
the path for `OutputDirectory`, and concatenated with `BuiltModuleSubdirectory`
if it is set.

### `BuiltModuleSubdirectory`

An optional path that will suffix the `OutputDirectory` to build the
default path in variable `BuildModuleOutput`.

### `ModuleVersion`

The module version of the built module. Defaults to the property `ModuleVersion`
returned by the executable `gitversion`, or if the executable `gitversion`
is not available the variable defaults to an empty string, and the
build module task will use the version found in the Module Manifest.

It is also possible to set the session environment variable `$env:ModuleVersion`
in the PowerShell session or set the variable `$ModuleVersion` in the
PowerShell session (the parent scope to `Invoke-Build`) before running the
task `build`

This `ModuleVersion` task variable can be overridden by using the key `SemVer`
in the file `build.yml`, e.g. `SemVer: '99.0.0-preview1'`. This can be used
if the preferred method of using GitVersion is not available.

The order that the module version is determined is as follows:

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
   ~~override 1), 2), 3), 4), and 5)~~. This is not yet supported.

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

## Tasks

### `Create_Changelog_Branch`

This build task creates pushes a branch with the changelog updated with
the current release version.

This is an example of how to use the task in the _azure-pipelines.yml_ file:

```yaml
- task: PowerShell@2
  name: sendChangelogPR
  displayName: 'Send Changelog PR'
  inputs:
    filePath: './build.ps1'
    arguments: '-tasks Create_Changelog_Branch'
    pwsh: true
  env:
    MainGitBranch: 'main'
    BasicAuthPAT: $(BASICAUTHPAT)
```

This can be use in conjunction with the `Create_Release_Git_Tag` task
that creates the release tag.

```yaml
  publish:
    - Create_Release_Git_Tag
    - Create_Changelog_Branch
```

#### Task parameters

Some task parameters are vital for the resource to work. See comment based
help for the description for each available parameter. Below is the most
important.

#### Task configuration

The build configuration (_build.yaml_) can be used to control the behavior
of the build task.

```yaml
####################################################
#             Changelog Configuration              #
####################################################
ChangelogConfig:
  FilesToAdd:
    - 'CHANGELOG.md'
  UpdateChangelogOnPrerelease: false

####################################################
#                Git Configuration                 #
####################################################
GitConfig:
  UserName: bot
  UserEmail: bot@company.local
```

#### Section ChangelogConfig

##### Property FilesToAdd

This specifies one or more files to add to the commit when creating the
PR branch. If left out it will default to the one file _CHANGELOG.md_.

##### Property UpdateChangelogOnPrerelease

- `true`: Always create a changelog PR, even on preview releases.
- `false`: Only create a changelog PR for full releases. Default.

#### Section GitConfig

This configures git.  user name and e-mail address of the user before task pushes the
tag.

##### Property UserName

User name of the user that should push the tag.

##### Property UserEmail

E-mail address of the user that should push the tag.

### `Create_Release_Git_Tag`

This build task creates and pushes a preview release tag to the default branch.

>Note: This task is primarily meant to be used for SCM's that does not have
>releases that connects to tags like GitHub does with GitHub Releases, but
>this task can also be used as an alternative when using GitHub as SCM.

This is an example of how to use the task in the _build.yaml_ file:

```yaml
  publish:
    - Create_Release_Git_Tag
```

#### Task parameters

Some task parameters are vital for the resource to work. See comment based
help for the description for each available parameter. Below is the most
important.

#### Task configuration

The build configuration (_build.yaml_) can be used to control the behavior
of the build task.

```yaml
####################################################
#                Git Configuration                 #
####################################################
GitConfig:
  UserName: bot
  UserEmail: bot@company.local
```

#### Section GitConfig

This configures git.  user name and e-mail address of the user before task pushes the
tag.

##### Property UserName

User name of the user that should push the tag.

##### Property UserEmail

E-mail address of the user that should push the tag.

### `Set_PSModulePath`

This task sets the `PSModulePath` according to the configuration in the `build.yml`
file.

This task can be important when compiling DSC resource modules or
DSC composite resource modules. When a DSC resource module is available in
'Program Files' and the Required Modules folder, DSC sees this as a conflict.

> Note: The paths `$BuiltModuleSubdirectory` and `$RequiredModulesDirectory` are
> always prepended to the `PSModulePath`.

This sequence sets the `PSModulePath` before starting the tests.

```yaml
  test:
    - Set_PSModulePath
    - Pester_Tests_Stop_On_Fail
    - Pester_If_Code_Coverage_Under_Threshold
```

#### Task parameters

Some task parameters are vital for the resource to work. See comment based
help for the description for each available parameter. Below is the most
important.

#### Task configuration

The build configuration (_build.yaml_) can be used to control the behavior
of the build task.

```yaml
####################################################
#           Setting Sampler PSModulePath           #
####################################################
SetPSModulePath:
  PSModulePath: C:\Users\Install\OneDrive\Documents\WindowsPowerShell\Modules;C:\Program Files\WindowsPowerShell\Modules;C:\Windows\system32\WindowsPowerShell\v1.0\Modules;c:\Users\Install\.vscode\extensions\ms-vscode.powershell-2022.5.1\modules;
  RemovePersonal: false
  RemoveProgramFiles: false
  RemoveWindows: false
  SetSystemDefault: false
```

The `PSModulePath` parameter can access variables and contain sub-expressions.

```yaml
####################################################
#           Setting Sampler PSModulePath           #
####################################################
SetPSModulePath:
  PSModulePath: $ProjectPath\.temp\Microsoft Azure AD Sync\Bin;$([System.Environment]::GetFolderPath('ProgramFiles'))\WindowsPowerShell\Modules;$([System.Environment]::GetFolderPath('System'))\WindowsPowerShell\v1.0\Modules
  RemovePersonal: false
  RemoveProgramFiles: false
  RemoveWindows: false
  SetSystemDefault: false
```

#### Section SetPSModulePath

##### Property PSModulePath

Sets the `PSModulePath` to the specified value. This string is treated like an expandable
string and can access variables and contain sub-expressions.

##### Property RemovePersonal

Removed the personal path from `PSModulePath`, like `C:\Users\Install\Documents\WindowsPowerShell\Modules`.

#### Section RemoveProgramFiles

Removed the 'Program Files' path from `PSModulePath`, like `C:\Program Files\WindowsPowerShell\Modules`.

##### Property RemoveWindows

Removed the Windows path from `PSModulePath`, like `C:\Windows\system32\WindowsPowerShell\v1.0\Modules`.

> **Note: It is not recommended to remove the Windows path from `PSModulePath`.**

##### Property SetSystemDefault

Sets the module path to what is defined for the machine. The machines `PSModulePath` is retrieved with this call:

```powershell
[System.Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')
```
