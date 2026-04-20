
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
            - CustomModule

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

    .PARAMETER MainGitBranch
        The name of the default Git branch to configure in templates that use Git (defaults to 'main').

    .PARAMETER LicenseType
        Type of license you would like to add to your repository. We recommend MIT for Open Source projects.

    .PARAMETER SourceDirectory
        How you would like to call your Source repository to differentiate from the output and the tests folder. We recommend to call it 'source',
        and the default value is 'source'.

    .PARAMETER Features
        If you'd rather select specific features from this template to build your module, use this parameter instead.
        Valid values mirror the Plaster template feature choices:
            All, Enum, Classes, DSCResources, ClassDSCResource, SampleScripts,
            git, gitversion, github, vscode, codecov, azurepipelines,
            Gherkin, UnitTests, ModuleQuality, Build, AppVeyor, TestKitchen.

    .EXAMPLE
        C:\src> New-SampleModule -DestinationPath . -ModuleType CompleteSample -ModuleAuthor "Gael Colas" -ModuleName MyModule -ModuleVersion 0.0.1 -ModuleDescription "a sample module" -LicenseType MIT -SourceDirectory Source

    .NOTES
        See Add-Sample to add elements such as functions (private or public), tests, DSC Resources to your project.
#>
function New-SampleModule
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('Path')]
        [System.String]
        $DestinationPath,

        [Parameter()]
        [string]
        [ValidateSet('SimpleModule', 'CompleteSample', 'SimpleModule_NoBuild', 'dsccommunity', 'CustomModule')]
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
        $MainGitBranch = 'main',

        [Parameter()]
        [System.String]
        [ValidateSet('MIT','Apache','None')]
        $LicenseType = 'MIT',

        [Parameter()]
        [System.String]
        [ValidateSet('source','src')]
        $SourceDirectory = 'source',

        [Parameter()]
        [ValidateSet(
            'All',
            'Enum',
            'Classes',
            'DSCResources',
            'ClassDSCResource',
            'SampleScripts',
            'git',
            'gitversion',
            'github',
            'vscode',
            'codecov',
            'azurepipelines',
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

    <#
        When the caller supplies -Features but does not explicitly choose a
        -ModuleType, treat the invocation as a CustomModule cherry-pick. The
        Plaster template only honors the Features multichoice when ModuleType
        is 'CustomModule', so without this auto-switch the Features values
        would be silently ignored and the user would still be prompted for
        every Use* option of the default 'SimpleModule' preset.
    #>
    if ($PSBoundParameters.ContainsKey('Features') -and -not $PSBoundParameters.ContainsKey('ModuleType'))
    {
        $ModuleType = 'CustomModule'
    }

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

    <#
        For CustomModule scaffolding, derive every Use* template parameter
        from the explicit Features list so that Plaster never prompts the
        caller for them. Each Use* is set to 'true' when the matching
        feature (or 'All') is selected, and to 'false' otherwise. This
        guarantees that an invocation that fully specifies -Features runs
        non-interactively.
    #>
    if ($ModuleType -eq 'CustomModule' -and $PSBoundParameters.ContainsKey('Features'))
    {
        $featureToUseParameter = [ordered]@{
            UseGit            = 'git'
            UseGitVersion     = 'gitversion'
            UseGitHub         = 'github'
            UseAzurePipelines = 'azurepipelines'
            UseCodeCovIo      = 'codecov'
            UseVSCode         = 'vscode'
        }

        $allFeatures = $Features -contains 'All'

        foreach ($useParameter in $featureToUseParameter.Keys)
        {
            $featureName = $featureToUseParameter[$useParameter]
            $isEnabled   = $allFeatures -or ($Features -contains $featureName)

            $invokePlasterParam[$useParameter] = if ($isEnabled) { 'true' } else { 'false' }
        }
    }

    Invoke-Plaster @invokePlasterParam
}
