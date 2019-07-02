# Contributing

Thank you for considering contributing to this resource module. Every little
change helps make the DSC resources even better for everyone to use.

## Common contribution guidelines

This resource module follow all of the common contribution guidelines for
DSC resource modules [outlined in DscResources repository](https://github.com/PowerShell/DscResources/blob/master/CONTRIBUTING.md),
so please review these as a baseline for contributing.

## Specific guidelines for this resource module

### Automatic formatting with VS Code

There is a VS Code workspace settings file within this project with formatting
settings matching the style guideline. That will make it possible inside VS Code
to press SHIFT+ALT+F, or press F1 and choose 'Format document' in the list. The
PowerShell code will then be formatted according to the Style Guideline
(although maybe not complete, but would help a long way).

### Naming convention

#### mof-based resource

All mof-based resource (with Get/Set/Test-TargetResource) should be prefixed
with 'MSFT'. I.e. MSFT\_Folder.

>**Note:** If the resource module is not part of the DSC Resource Kit the
>prefix can be any abbreviation, for example your name or company name.
>For the example below, the 'MSFT' prefix is used.

##### Folder and file structure

```Text
DSCResources/MSFT_Folder/MSFT_Folder.psm1
DSCResources/MSFT_Folder/MSFT_Folder.schema.mof
DSCResources/MSFT_Folder/en-US/MSFT_Folder.strings.psd1

Tests/Unit/MSFT_Folder.Tests.ps1

Examples/Resources/Folder/1-AddConfigurationOption.ps1
Examples/Resources/Folder/2-RemoveConfigurationOption.ps1
```

>**Note:** For the examples folder we don't use the 'MSFT\_' prefix on the
>resource folders. This is to make those folders resemble the name the user
>would use in the configuration file.

##### Schema mof file

Please note that the `FriendlyName` in the schema mof file should not
contain the prefix `MSFT\_`.

```powershell
[ClassVersion("1.0.0.0"), FriendlyName("Folder")]
class MSFT_Folder : OMI_BaseResource
{
    # Properties removed for readability.
};
```

#### Composite or class-based resource

Any composite (with a Configuration) or class-based resources should be
prefixed with just 'Sql'

### Helper functions

Helper functions that are only used by one resource
so preferably be put in the same script file as the resource.
Helper function that can used by more than one resource can preferably
be placed in the resource module file [DscResource.Common](/Modules/DscResource.Common/DscResource.Common.psm1).

### Localization

Please see the localization section in the [style guideline](https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md#localization).
The helper functions is found in the module [DscResource.LocalizationHelper](/Modules/DscResource.LocalizationHelper/DscResource.LocalizationHelper.psm1).

### Unit tests

For a review of a Pull Request (PR) to start, all tests must pass without error.
If you need help to figure why some test don't pass, just write a comment in the
Pull Request (PR), or submit an issue, and somebody will come along and assist.

To run all tests manually run the following.

```powershell
Install-Module Pester
cd '<path to cloned repository>\Tests\Unit'
Invoke-Pester
```

#### Unit tests for style check of Markdown files

When sending in a Pull Request (PR) a style check will be performed on all Markdown
files, and if the tests find any error the build will fail.
See the section [Documentation with Markdown](#documentation-with-markdown) how
these errors can be found before sending in the PR.

The Markdown tests can be run locally if the packet manager 'npm' is available.
To have npm available you need to install [node.js](https://nodejs.org/en/download/).
If 'npm' is not available, a warning text will print and the rest of the tests
will continue run.

>**Note:* To run the common tests, at least one unit tests must have be run for
>the common test framework to have been cloned locally.

```powershell
cd '<path to cloned repository>'
Invoke-Pester .\DSCResource.Tests\Meta.Tests.ps1
```

#### Unit tests for examples files

When sending in a Pull Request (PR) all example files will be tested so they can
be compiled to a .mof file. If the tests find any errors the build will fail.
Before the test runs in AppVeyor the module will be copied to a path of
`$env:PSModulePath`.
To run this test locally, make sure you have the resource module
deployed to a path where it can be used.
See `$env:PSModulePath` to view the existing paths.

>**Note:* To run the common tests, at least one unit tests must have be run for
>the common test framework to have been cloned locally.

```powershell
cd '<path to cloned repository>'
Invoke-Pester .\DSCResource.Tests\Meta.Tests.ps1
```

### Integration tests

Integration tests should be written for resources so they can be validated by
the automated test framework which is run in AppVeyor when commits are pushed
to a Pull Request (PR).
Please see the [Testing Guidelines](https://github.com/PowerShell/DscResources/blob/master/TestsGuidelines.md)
for common DSC Resource Kit testing guidelines.
There are also configurations made by existing integration tests that can be reused
to write integration tests for other resources. This is documented in the
[Integration tests README](/Tests/Integration/README.md).

#### AppVeyor

AppVeyor is the platform where the tests is run when sending in a Pull Request (PR).
All tests are run on a clean AppVeyor build worker for each push to the Pull
Request (PR).
The tests that are run on the build worker are common tests, unit tests and
integration tests (with some limitations).

### Documentation with Markdown

If using Visual Studio Code to edit Markdown files it can be a good idea to install
the markdownlint extension. It will help to find lint errors and style checking.
The file [.markdownlint.json](/.markdownlint.json) is prepared with a default set
of rules which will automatically be used by the extension.
