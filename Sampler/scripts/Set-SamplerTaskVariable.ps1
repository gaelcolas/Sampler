<#
    .SYNOPSIS
        Public function that set all script variables for a build task. This function
        should normally never be called by it's own, the function should only be called
        (as a function) by tests.

    .DESCRIPTION
        Public function that set all script variables for a build task. This function
        should normally never be called by it's own, the function should only be called
        (as a function) by tests.

    .PARAMETER AsNewBuild
       Tells the script to skip variables that need the finished built module to
       be able to be returned. For example, if this parameter is used it evaluates
       the ModuleVersion from GitVersion, instead from the built module's manifest.

    .PARAMETER ArtifactContext
       Tells the script which artifact the current task is working with. Use
       'Chocolatey' for Chocolatey packaging tasks so source-kind detection stays
       separate from artifact packaging.

    .NOTES
        Only the scriptblock portion of this function is used by the task by
        calling:

        . Set-SamplerTaskVariable

        This dot-sources the entire scriptblock of this function. This is done so
        that the variables are set in the task's scope, and so that the variables
        can be re-used throughout the tasks.

        To use the scriptblock the task can (must?) have the parameters (and its
        respective default value):

        - $ProjectName = (property ProjectName '')
        - $SourcePath = (property SourcePath '')
        - $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output'))
        - $BuiltModuleSubdirectory = (property BuiltModuleSubdirectory '')
        - $ModuleVersion = (property ModuleVersion '')
        - $VersionedOutputDirectory = (property VersionedOutputDirectory $true)
        - $ReleaseNotesPath = (property ReleaseNotesPath (Join-Path $OutputDirectory 'ReleaseNotes.md'))
        - $BuildInfo = (property BuildInfo @{ })

        TODO: The above should be in the README.md instead, or CONTRIBUTING.md.

    .OUTPUTS
        [System.String[]]

        See https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.

    .EXAMPLE
        . Set-SamplerTaskVariable -AsNewBuild

        Call the scriptblock set script variables. The parameter AsNewBuild tells the
        script to skip variables that need the finished built module.

    .EXAMPLE
        . Set-SamplerTaskVariable

        Call the scriptblock and tells the script to evaluate the module version
        by not checking after the module manifest in the built module.

#>
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Because the variables like BuildModuleOutput are not usedin the script but in the tasks that dot-source this script.')]
param
(
    [Parameter()]
    [System.Management.Automation.SwitchParameter]
    $AsNewBuild,

    [Parameter()]
    [AllowEmptyString()]
    [System.String]
    $ArtifactContext = 'Auto'
)

$OutputDirectory = Get-SamplerAbsolutePath -Path $OutputDirectory -RelativeTo $BuildRoot

"`tOutput Directory           = '$OutputDirectory'"

$ReleaseNotesPath = Get-SamplerAbsolutePath -Path $ReleaseNotesPath -RelativeTo $OutputDirectory

"`tRelease Notes path         = '$ReleaseNotesPath'"

$getSamplerProjectBuildInfoParameters = @{
    ProjectPath              = $BuildRoot
    OutputDirectory          = $OutputDirectory
    BuiltModuleSubdirectory  = $BuiltModuleSubdirectory
    VersionedOutputDirectory = $VersionedOutputDirectory
    ProjectName              = $ProjectName
    SourcePath               = $SourcePath
    ModuleVersion            = $ModuleVersion
    BuildInfo                = $BuildInfo
}

$samplerProjectBuildInfo = Get-SamplerProjectBuildInfo @getSamplerProjectBuildInfoParameters

$ProjectName = $samplerProjectBuildInfo.ProjectName
$SourcePath = Get-SamplerAbsolutePath -Path $samplerProjectBuildInfo.SourcePath -RelativeTo $BuildRoot

if ([System.String]::IsNullOrEmpty($ModuleVersion))
{
    $ModuleVersion = $samplerProjectBuildInfo.ModuleVersion
}

$sourceBuildType = $samplerProjectBuildInfo.BuildType

if ([System.String]::IsNullOrEmpty($ArtifactContext) -or $ArtifactContext -eq 'Auto')
{
    if ($sourceBuildType -eq 'PowerShellModule')
    {
        $ArtifactContext = 'Module'
    }
    else
    {
        $ArtifactContext = 'Standalone'
    }
}

if ($ArtifactContext -notin @('Module', 'Chocolatey', 'Standalone'))
{
    throw ("Unknown artifact context '{0}'. Valid values are 'Auto', 'Module', 'Chocolatey', and 'Standalone'." -f $ArtifactContext)
}

"`tProject Name               = '$ProjectName'"
"`tSource Path                = '$SourcePath'"
"`tSource Build Type          = '$sourceBuildType'"
"`tArtifact Context           = '$ArtifactContext'"

<#
    We check if the value is set in build.yaml.
    1 . If it past to parameter, or defined in parameter property we use parameter,
    2 . If it set in build.yaml we use it
    3 . If it set nowhere, we used an empty value
#>
if (-not [System.String]::IsNullOrEmpty($BuiltModuleSubDirectory))
{
    $BuiltModuleSubdirectory = Get-SamplerAbsolutePath -Path $BuiltModuleSubDirectory -RelativeTo $OutputDirectory
}
elseif ($BuildInfo.ContainsKey('BuiltModuleSubdirectory'))
{
    $BuiltModuleSubdirectory = Get-SamplerAbsolutePath -Path $BuildInfo['BuiltModuleSubdirectory'] -RelativeTo $OutputDirectory
    $BuildModuleOutput = $BuiltModuleSubdirectory
}
else {
    $BuiltModuleSubdirectory = Get-SamplerAbsolutePath -Path '' -RelativeTo $OutputDirectory
}

"`tBuilt Module Subdirectory  = '$BuiltModuleSubdirectory'"

if (-not [System.String]::IsNullOrEmpty($ChocolateyBuildOutput))
{
    $ChocolateyBuildOutput = Get-SamplerAbsolutePath -Path $ChocolateyBuildOutput -RelativeTo $OutputDirectory
}

if ($sourceBuildType -eq 'PowerShellModule')
{
    Write-Debug -Message 'Building from a PowerShell module source.'

    $ModuleManifestPath = Get-SamplerAbsolutePath -Path "$ProjectName.psd1" -RelativeTo $SourcePath

    "`tModule Manifest Path (src) = '$ModuleManifestPath'"
}
else
{
    Write-Debug -Message 'Building from a non-module source.'

    $ModuleManifestPath = $null
}

$shouldUseBuiltModuleManifest =
    -not $AsNewBuild.IsPresent -and
    $sourceBuildType -eq 'PowerShellModule' -and
    $ArtifactContext -eq 'Module'

if ($shouldUseBuiltModuleManifest)
{
    if ($VersionedOutputDirectory)
    {
        <#
            VersionedOutputDirectory is not [bool]'' nor $false nor [bool]$null
            Assume true, wherever it was set.
        #>
        $null = [System.Boolean]::TryParse($VersionedOutputDirectory, [ref] $VersionedOutputDirectory)
    }
    else
    {
        # VersionedOutputDirectory may be [bool]'' but we can't tell where it's
        # coming from, so assume the build info (Build.yaml) is right
        $VersionedOutputDirectory = $BuildInfo['VersionedOutputDirectory']
    }

    "`tVersioned Output Directory = '$VersionedOutputDirectory'"

    $GetBuiltModuleManifestParams = @{
        OutputDirectory          = $OutputDirectory
        BuiltModuleSubdirectory  = $BuiltModuleSubDirectory
        ModuleName               = $ProjectName
        VersionedOutputDirectory = $VersionedOutputDirectory
        ErrorAction              = 'Stop'
    }

    $BuiltModuleManifest = Get-SamplerBuiltModuleManifest @GetBuiltModuleManifestParams

    # Resolve path to replace '*' with version number.
    if ($BuiltModuleManifest)
    {
        $BuiltModuleManifest = (Get-Item -Path $BuiltModuleManifest -ErrorAction 'Ignore').FullName
    }

    "`tBuilt Module Manifest      = '$BuiltModuleManifest'"

    if (-not $BuiltModuleManifest)
    {
        throw ("Could not find the built module manifest for module '{0}'. Build the module before running tasks that require the built module output." -f $ProjectName)
    }

    $BuiltModuleBase = Get-SamplerBuiltModuleBase @GetBuiltModuleManifestParams

    # Resolve path to replace '*' with version number.
    if ($BuiltModuleBase)
    {
        $BuiltModuleBase = (Get-Item -Path $BuiltModuleBase -ErrorAction 'Ignore').FullName
    }

    "`tBuilt Module Base          = '$BuiltModuleBase'"

    $ModuleVersion = Get-BuiltModuleVersion @GetBuiltModuleManifestParams

    "`tModule Version             = '$ModuleVersion'"

    $BuiltModuleRootScriptPath = Get-SamplerModuleRootPath -ModuleManifestPath $BuiltModuleManifest

    # Resolve path to replace '*' with version number.
    if ($BuiltModuleRootScriptPath)
    {
        $BuiltModuleRootScriptPath = (Get-Item -Path $BuiltModuleRootScriptPath -ErrorAction 'Ignore').FullName
    }
}
else
{
    $getBuildVersionParameters = @{
        ModuleManifestPath = $ModuleManifestPath
        ModuleVersion      = $ModuleVersion
    }

    <#
        This will get the version from $ModuleVersion if is was set as a parameter
        or as a property. If $ModuleVersion is $null or an empty string the version
        will fetched from GitVersion if it is installed. If GitVersion is _not_
        installed the version is fetched from the module manifest in SourcePath, or
        fallback to the default repository version for non-module sources.
    #>
    $ModuleVersion = Get-SamplerBuildVersion @getBuildVersionParameters

    $BuiltModuleManifest = $null
    $BuiltModuleBase = $null
    $BuiltModuleRootScriptPath = $null

    "`tModule Version             = '$ModuleVersion'"
}

if (-not [System.String]::IsNullOrEmpty($ModuleVersion))
{
    $moduleVersionObject = Split-ModuleVersion -ModuleVersion $ModuleVersion
    $ModuleVersionFolder = $moduleVersionObject.Version

    "`tModule Version Folder      = '$ModuleVersionFolder'"

    $PreReleaseTag = $moduleVersionObject.PreReleaseString

    "`tPre-release Tag            = '$PreReleaseTag'"
}

"`tBuilt Module Root Script   = '$BuiltModuleRootScriptPath'"

# Dump PSModulePath to support debugging
"`tPSModulePath               = '$($s=''; foreach ($p1 in $env:PSModulePath.Split([System.IO.Path]::PathSeparator)) { $s += "$p1;`n`t$(' '*30)" }; $s.Trim())'"

# Blank row in output.
""
