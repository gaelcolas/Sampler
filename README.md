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
- Build
    - [ ] Extend the project to DSC Builds
    - [ ] Add DSL for Build file / Task Composition as per Brandon Padgett's suggestion
    - [ ] ...