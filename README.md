# Sample Module

This project is a sample module to experiment with a PowerShell Build Pipeline and its various steps.
It includes minumum component of a real module, but with minimum amount of code.

## Goal

The goal is to have a sandbox to experiment with a PowerShell Module pipeline, develop re-usable steps in a maintainable, re-usable fashion.

Eventually, the aim is to extract this structure and the key re-usable files into a Plaster template.

## TODO

- Build Tasks
    - [ ] Create most-generic and re-usable tasks in \.build\ folder
    - [ ] push those tasks upstream in their associate repos (i.e. PSDepend, PSDeploy)
    - [ ] make those tasks discoverable (i.e. Extension metadata, similar to Plaster Templates)
    - [ ] Evaluate work for discoverability (autoloading?) into InvokeBuild

- Tests
    - [ ] Create Test function to run tests based on folder, so that tasks don't duplicate code (Unit,Integration,QA)
    - [ ] Allow Module Quality by Managing Quality level i.e. `Invoke-pester -ExcludeTag HelpQuality` 
    - [ ] Allow tests to be run either in current session or in New PSSession with no-profile (to have no Class / Assemblies loaded)

- Build
    - [ ] Extend the project to DSC Builds
    - [ ] Add DSL for Build file / Task Composition as per Brandon Padgett's suggestion
    - [ ] Find what would be needed to build on Linux/PSCore

    
## Usage (intented)

`.init.ps1` should be fairly static and do just enough to bootstrap any project, the rest of the environment initialization should be handled by dedicated modules such as PSDepend for installing required module/lib.

`.build.ps1` is where most of the Build customization is done for the project. This is where the default task `.` is composed by importing required tasks exposed by different modules (i.e. BuildHelpers). The logic should be minimum: ordering/selecting tasks, so that this high level abstraction only gives the overview and the overridden parameter values.
Eventually, the composition should be DSL powered similar to what Brandon Padgett suggested:
```
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
