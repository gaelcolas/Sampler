<#
.SYNOPSIS
Create a module scaffolding and add samples & build pipeline.

.DESCRIPTION
New-SampleModule helps you bootstrap your PowerShell module project by
creating a the folder structure of your module, and optionally add the
pipeline files to help with compiling the module, publishing to PSGallery
and GitHub and testing quality and style such as per the DSC Community
guildelines.

.PARAMETER DestinationPath
Destination of your module source root folder, defaults to the current directory ".".
We assume that your current location is the module folder, and within this folder we
will find the source folder, the tests folder and other supporting files.

.PARAMETER ModuleType
Specifies the type of module to create. The default value is 'SimpleModule'.
Preset of module you would like to create:
    - CompleteSample
    - SimpleModule
    - SimpleModule_NoBuild
    - dsccommunity

.PARAMETER ModuleAuthor
The author of module that will be populated in the Module Manifest and will show in the Gallery.

.PARAMETER ModuleName
The Name of your Module.

.PARAMETER ModuleDescription
The Description of your Module, to be used in your Module manifest.

.PARAMETER CustomRepo
The Custom PS repository if you want to use an internal (private) feed to pull for dependencies.

.PARAMETER ModuleVersion
Version you want to set in your Module Manifest. If you follow our approach, this will be updated during compilation anyway.

.PARAMETER LicenseType
Type of license you would like to add to your repository. We recommend MIT for Open Source projects.

.PARAMETER SourceDirectory
How you would like to call your Source repository to differentiate from the output and the tests folder. We recommend to call it 'source',
and the default value is 'source'.

.PARAMETER Features
If you'd rather select specific features from this template to build your module, use this parameter instead.

.EXAMPLE
C:\src> New-SampleModule -DestinationPath . -ModuleType CompleteSample -ModuleAuthor "Gael Colas" -ModuleName MyModule -ModuleVersion 0.0.1 -ModuleDescription "a sample module" -LicenseType MIT -SourceDirectory Source

.NOTES
See Add-Sample to add elements such as functions (private or public), tests, DSC Resources to your project.
#>
function New-SampleModule
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(DefaultParameterSetName = 'ByModuleType')]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('Path')]
        [System.String]
        $DestinationPath,

        [Parameter(ParameterSetName = 'ByModuleType')]
        [string]
        [ValidateSet('SimpleModule', 'CompleteSample', 'SimpleModule_NoBuild', 'newDscCommunity', 'dsccommunity')]
        $ModuleType = 'SimpleModule',

        [Parameter()]
        [System.String]
        $ModuleAuthor = $env:USERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleName,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $ModuleDescription,

        [Parameter()]
        [System.String]
        $CustomRepo = 'PSGallery',

        [Parameter()]
        [System.String]
        $ModuleVersion = '0.0.1',

        [Parameter()]
        [System.String]
        [ValidateSet('MIT','Apache','None')]
        $LicenseType = 'MIT',

        [Parameter()]
        [System.String]
        [ValidateSet('source','src')]
        $SourceDirectory = 'source',

        [Parameter(ParameterSetName = 'ByFeature')]
        [ValidateSet(
            'All',
            'Enum',
            'Classes',
            'DSCResources',
            'ClassDSCResource',
            'SampleScripts',
            'git',
            'Gherkin',
            'UnitTests',
            'ModuleQuality',
            'Build',
            'AppVeyor',
            'TestKitchen'
            )]
        [System.String[]]
        $Features
    )

    $templateSubPath = 'Templates/Sampler'
    $samplerBase = $MyInvocation.MyCommand.Module.ModuleBase

    $invokePlasterParam = @{
        TemplatePath = Join-Path -Path $samplerBase -ChildPath $templateSubPath
        DestinationPath   = $DestinationPath
        NoLogo            = $true
        ModuleName        = $ModuleName
    }

    foreach ($paramName in $MyInvocation.MyCommand.Parameters.Keys)
    {
        $paramValue = Get-Variable -Name $paramName -ValueOnly -ErrorAction SilentlyContinue

        # if $paramName is $null, leave it to Plaster to ask the user.
        if ($paramvalue -and -not $invokePlasterParam.ContainsKey($paramName))
        {
            $invokePlasterParam.Add($paramName, $paramValue)
        }
    }

    if ($LicenseType -eq 'none')
    {
        $invokePlasterParam.Remove('LicenseType')
        $invokePlasterParam.add('License', 'false')
    }
    else
    {
        $invokePlasterParam.add('License', 'true')
    }

    Invoke-Plaster @invokePlasterParam
}
