# Sample Module

[![Build status](https://ci.appveyor.com/api/projects/status/nwjaovie2iqoexf5?svg=true)](https://ci.appveyor.com/project/gaelcolas/samplemodule)

This project is a sample module to experiment with a PowerShell Build Pipeline and its various steps.
It includes minumum component of a real module, but with minimum amount of code.

## Goal

The goal is to have a sandbox to experiment with a PowerShell Module pipeline, develop re-usable steps in a maintainable, re-usable fashion.

Eventually, the aim is to extract this structure and the key re-usable files into a Plaster template.

## TODO
- Sample Build Workflow:
    - [x] .init.ps1  -> Bootstrap by installing InvokeBuild from gallery
    - [x] .build.ps1 -> Compose the default task in the build workflow
    - [x] Clean the BuildOutput folder
    - [x] Resolve Dependencies with PSDepend from [Dependencies.psd1](./Dependencies.psd1)
    - [ ] Test the Functions' Code (aka Function Unit Test)
        - [x] Run all Unit test files against their function equivalent
        - [ ] Run all Unit test files against their Class equivalent
        - [x] Save code coverage to file (CLIXml), fail if under threshold
        - [x] Save Test results in XML
        - [x] Upload test results to Appveyor
    - [ ] Test the Module Mechanics (aka Module Unit Test)
        - [x] Merge Classes and Functions into the PSM1 file
        - [ ] Run Integration tests against 'compiled' module
        - [ ] Save code coverage to file (CLIXml), fail if under threshold
        - [ ] Save test results in XML
        - [ ] Upload test results to Appveyor
    - [ ] Run QA tests
        - [x] Ensure each function file has an associated test file
        - [ ] Ensure each Class file has an associated test file
        - [x] Ensure PSSA is clean for each function file
        - [ ] Ensure PSSA is clean for each Class file
        - [x] Ensure each function as minimum help
        - [ ] Save test results in XML
        - [ ] Upload test results to Appveyor
    - [ ] Generate the help
        - [ ] PlatyPS to generate or update the help MDs in BuildOutput\docs
        - [ ] PlatyPS to generate or update the help MAML in BuildOutput\SampleModule
    - [ ] Prepare Module for export
        - [ ] Update Metadata with FunctionToExports
        - [ ] Update Metadata with new version
        - [ ] Update RequiredModules with what it has been tested with
        - [ ] Update RequiredAssemblies with the one it has been tested with
    - [ ] Deploy artefacts
        - [ ] PSDeploy Docs
        - [ ] PSDeploy Module to Appveyor Gallery
        - [ ] Package and make available all outputs

---------------
- Build Tasks
    - [ ] Create most-generic and re-usable tasks in \.build\ folder
    - [ ] push those tasks upstream in their associate repos (i.e. PSDepend, PSDeploy)
    - [ ] make those tasks discoverable (i.e. Extension metadata, similar to Plaster Templates)
    - [ ] Evaluate work for discoverability (autoloading?) into InvokeBuild

- Tests
    - [ ] Create Test function to run tests based on folder, so that tasks don't duplicate code (Unit,Integration,QA)
    - [ ] Allow Module Quality by Managing Quality level i.e. `Invoke-pester -ExcludeTag HelpQuality` 
    - ~~[ ] Allow tests to be run either in current session or in New PSSession with no-profile (to have no Class / Assemblies loaded)~~ <-- Less important within CI

- Build
    - [ ] Extend the project to DSC Builds
    - [ ] Add DSL for Build file / Task Composition as per Brandon Padgett's suggestion
    - [ ] Find what would be needed to build on Linux/PSCore


## Usage (intented)

`.init.ps1` should be fairly static and do just enough to bootstrap any project, the rest of the environment initialization should be handled by dedicated modules such as PSDepend for installing required module/lib.

`.build.ps1` is where most of the Build customization is done for the project. This is where the default task `.` is composed by importing required tasks exposed by different modules (i.e. BuildHelpers). The logic should be minimum: ordering/selecting tasks, so that this high level abstraction only gives the overview and the overridden parameter values.
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

#Compose pre-existing tasks in custom workflow
task .  ResolveDependencies,
        SetBuildVariable,
        UnitTests, 
        DoSomethingBeforeFailing,
        FailBuildIfFailedUnitTest, 
        IntegrationTests, 
        QualityTestsStopOnFail
```
Eventually, the composition should be DSL powered similar to what Brandon Padgett suggested:

```PowerShell
#Rough idea, needs to play with...
# The idea is that the With could automatically resolve Module, 
#  with discoverable tasks and then auto-load the available parameters/DSL for that task.

BuildWorkflow SampleBuild {
    Task Init {
        With BuildHelpers {
            Task Clean
        }
    }
    
    Task Build {
        With PSDeploy {
            Task Deploy
            Tag Build
            StepVersion Minor
            DependingOn Init
        }
    }
    
    Task Test {
        Path "$ProjectRoot\Tests"
        DependingOn Build
    }
    Task Publish {
        With PSDeploy {
            Tag Publish
            DependingOn Test
        }
    }
}

```
