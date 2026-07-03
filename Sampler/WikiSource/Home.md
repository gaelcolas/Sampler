# Welcome to the Sampler wiki

<sup>*Sampler v#.#.#*</sup>

Here you will find all the information you need to make use of Sampler.

Please leave comments, feature requests, and bug reports for this module in
the [issues section](https://github.com/gaelcolas/Sampler/issues)
for this repository.

## Getting started

See the section [[Getting started]]

## Working across related repositories

See [[Workspace-Dependencies]] for how to link sibling workspace module builds
into the local output path so they are discoverable during builds and tests
without publishing them to a feed.

## GitHub Copilot integration

See [[Copilot-Instructions-Template]] for how to scaffold GitHub Copilot
instruction files and a `validate-changes` skill into a new or existing module.

## Exporting classes as type accelerators

See [[Type-Accelerators]] for how to scaffold a `suffix.ps1` that exports your
module's PSv5+ classes as type accelerators, so consumers can use them without
a `using module` statement.

## Prerequisites

- PowerShell 5.or higher

The build command will download all other modules required (if you choose too) into the `RequiredModules` folder of your module project for you. 

## Change log

A full list of changes in each version can be found in the [change log](https://github.com/gaelcolas/Sampler/blob/main/CHANGELOG.md).
