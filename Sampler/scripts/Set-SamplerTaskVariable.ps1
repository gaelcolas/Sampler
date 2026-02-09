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
    $AsNewBuild
)

if ([System.String]::IsNullOrEmpty($ProjectName))
{
    $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot -ErrorAction Ignore
}

"`tProject Name               = '$ProjectName'"

if ([System.String]::IsNullOrEmpty($SourcePath))
{
    $SourcePath = Get-SamplerSourcePath -BuildRoot $BuildRoot
}

"`tSource Path                = '$SourcePath'"

$OutputDirectory = Get-SamplerAbsolutePath -Path $OutputDirectory -RelativeTo $BuildRoot

"`tOutput Directory           = '$OutputDirectory'"

$ReleaseNotesPath = Get-SamplerAbsolutePath -Path $ReleaseNotesPath -RelativeTo $OutputDirectory

"`tRelease Notes path         = '$ReleaseNotesPath'"

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

$isChocolateyPackage = $false

if (-not [System.String]::IsNullOrEmpty($ChocolateyBuildOutput))
{
    $ChocolateyBuildOutput = Get-SamplerAbsolutePath -Path $ChocolateyBuildOutput -RelativeTo $OutputDirectory

    # If this returns $true then the task Build_Chocolatey_Package created the folder
    $isChocolateyPackage = Test-Path -Path $ChocolateyBuildOutput
}

if ($isChocolateyPackage)
{
    Write-Debug -Message 'Building a Chocolatey package'

    $ModuleManifestPath = $null
}
else
{
    Write-Debug -Message 'Building a module with a module manifest'

    $ModuleManifestPath = Get-SamplerAbsolutePath -Path "$ProjectName.psd1" -RelativeTo $SourcePath

    "`tModule Manifest Path (src) = '$ModuleManifestPath'"
}

if ($AsNewBuild.IsPresent -or $isChocolateyPackage)
{
    $getBuildVersionParameters = @{
        ModuleManifestPath = $ModuleManifestPath
        ModuleVersion      = $ModuleVersion
    }

    <#
        This will get the version from $ModuleVersion if is was set as a parameter
        or as a property. If $ModuleVersion is $null or an empty string the version
        will fetched from GitVersion if it is installed. If GitVersion is _not_
        installed the version is fetched from the module manifest in SourcePath.
    #>
    $ModuleVersion = Get-SamplerBuildVersion @getBuildVersionParameters

    "`tModule Version             = '$ModuleVersion'"
}
elseif ([string]::IsNullOrEmpty($ProjectName))
{
    "No PowerShell module name found. This might be because you are not building a PowerShell module, in which case you can ignore this message."
}
else
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
        $BuiltModuleManifest = (Get-Item -Path $BuiltModuleManifest -ErrorAction 'SilentlyContinue').FullName
    }

    "`tBuilt Module Manifest      = '$BuiltModuleManifest'"

    $BuiltModuleBase = Get-SamplerBuiltModuleBase @GetBuiltModuleManifestParams

    # Resolve path to replace '*' with version number.
    if ($BuiltModuleBase)
    {
        $BuiltModuleBase = (Get-Item -Path $BuiltModuleBase -ErrorAction 'SilentlyContinue').FullName
    }

    "`tBuilt Module Base          = '$BuiltModuleBase'"

    $ModuleVersion = Get-BuiltModuleVersion @GetBuiltModuleManifestParams

    "`tModule Version             = '$ModuleVersion'"

    $moduleVersionObject = Split-ModuleVersion -ModuleVersion $ModuleVersion
    $ModuleVersionFolder = $moduleVersionObject.Version

    "`tModule Version Folder      = '$ModuleVersionFolder'"

    $PreReleaseTag = $moduleVersionObject.PreReleaseString

    "`tPre-release Tag            = '$PreReleaseTag'"

    if ($BuiltModuleManifest)
    {
        $BuiltModuleRootScriptPath = Get-SamplerModuleRootPath -ModuleManifestPath $BuiltModuleManifest

        # Resolve path to replace '*' with version number.
        if ($BuiltModuleRootScriptPath)
        {
            $BuiltModuleRootScriptPath = (Get-Item -Path $BuiltModuleRootScriptPath -ErrorAction 'SilentlyContinue').FullName
        }
    }

    "`tBuilt Module Root Script   = '$BuiltModuleRootScriptPath'"
}

# Dump PSModulePath to support debugging
"`tPSModulePath               = '$($s=''; foreach ($p1 in $env:PSModulePath.Split([System.IO.Path]::PathSeparator)) { $s += "$p1;`n`t$(' '*30)" }; $s.Trim())'"

# Blank row in output.
""
