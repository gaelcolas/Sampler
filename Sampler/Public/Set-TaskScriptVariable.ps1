<#
    .SYNOPSIS
        Public function that set all script variables for a build task. This function
        should normally never be called by it's own, the function should only be called
        (as a function) by tests.

    .DESCRIPTION
        Public function that set all script variables for a build task. This function
        should normally never be called by it's own, the function should only be called
        (as a function) by tests.

    .PARAMETER IsBuild
       Tells the script to skip variables that need the finished built module to
       be able to be returned. For example is evaluates the ModuleVersion from,
       for example, GitVersion.

    .NOTES
        Only the scriptblock portion of this function is used by the task by
        calling:

        . (Get-Command -Name 'Set-TaskScriptVariable').ScriptBlock

        This dot-sources the entire scriptblock of this function. This is done
        so that the variables are set in the tasks scope, and so the variables can
        be re-used throughout the tasks.

        To use the scriptblock the task can (must?) have the parameters (and its default
        value):

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

        See https://github.com/gaelcolas/Sampler#task-variables.

    .EXAMPLE
        . (Get-Command -Name 'Set-TaskScriptVariable').ScriptBlock -IsBuild

        Call the scriptblock set script variables. The parameter IsBuild tells the
        script to skip variables that need the finished built module.

    .EXAMPLE
        . (Get-Command -Name 'Set-TaskScriptVariable').ScriptBlock

        Call the scriptblock and tells the script to evaluate the module version
        by not checking after the module manifest in the built module.

#>
function Set-TaskScriptVariable
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [Switch]
        $IsBuild
    )

    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    "`tProject Name               = '$ProjectName'"

    if ([System.String]::IsNullOrEmpty($SourcePath))
    {
        $SourcePath = Get-SamplerSourcePath -BuildRoot $BuildRoot
    }

    "`tSource Path                = '$SourcePath'"

    $OutputDirectory = Get-SamplerAbsolutePath -Path $OutputDirectory -RelativeTo $BuildRoot

    "`tOutput Directory           = '$OutputDirectory'"

    $BuiltModuleSubdirectory = Get-SamplerAbsolutePath -Path $BuiltModuleSubdirectory -RelativeTo $OutputDirectory

    "`tBuilt Module Subdirectory  = '$BuiltModuleSubdirectory'"

    $moduleManifestPath = Get-SamplerAbsolutePath -Path "$ProjectName.psd1" -RelativeTo $SourcePath

    "`tModule Manifest Path (src) = '$moduleManifestPath'"

    if ($IsBuild.IsPresent)
    {
        $getBuildVersionParameters = @{
            ModuleManifestPath = $moduleManifestPath
            ModuleVersion      = $ModuleVersion
        }

        <#
            This will get the version from $ModuleVersion if is was set as a parameter
            or as a property. If $ModuleVersion is $null or an empty string the version
            will fetched from GitVersion if it is installed. If GitVersion is _not_
            installed the version is fetched from the module manifest in SourcePath.
        #>
        $ModuleVersion = Get-BuildVersion @getBuildVersionParameters

        "`tModule Version             = '$ModuleVersion'"
    }
    else
    {
        if ($VersionedOutputDirectory)
        {
            # VersionedOutputDirectory is not [bool]'' nor $false nor [bool]$null
            # Assume true, wherever it was set
            $VersionedOutputDirectory = $true
        }
        else
        {
            # VersionedOutputDirectory may be [bool]'' but we can't tell where it's
            # coming from, so assume the build info (Build.yaml) is right
            $VersionedOutputDirectory = $BuildInfo['VersionedOutputDirectory']
        }

        $GetBuiltModuleManifestParams = @{
            OutputDirectory          = $OutputDirectory
            BuiltModuleSubdirectory  = $BuiltModuleSubDirectory
            ModuleName               = $ProjectName
            VersionedOutputDirectory = $VersionedOutputDirectory
            ErrorAction              = 'Stop'
        }

        $builtModuleManifest = Get-SamplerBuiltModuleManifest @GetBuiltModuleManifestParams
        $builtModuleManifest = (Get-Item -Path $builtModuleManifest).FullName

        "`tBuilt Module Manifest      = '$builtModuleManifest'"

        $builtModuleBase = Get-SamplerBuiltModuleBase @GetBuiltModuleManifestParams
        $builtModuleBase = (Get-Item -Path $builtModuleBase).FullName

        "`tBuilt Module Base          = '$builtModuleBase'"

        $moduleVersion = Get-BuiltModuleVersion @GetBuiltModuleManifestParams

        "`tModule Version             = '$ModuleVersion'"

        $moduleVersionObject = Split-ModuleVersion -ModuleVersion $moduleVersion
        $moduleVersionFolder = $moduleVersionObject.Version

        "`tModule Version Folder      = '$moduleVersionFolder'"

        $preReleaseTag = $moduleVersionObject.PreReleaseString

        "`tPre-release Tag            = '$preReleaseTag'"

        $BuiltModuleRootScriptPath = Get-SamplerModuleRootPath -ModuleManifestPath $builtModuleManifest

        if ($BuiltModuleRootScriptPath)
        {
            $BuiltModuleRootScriptPath = (Get-Item -Path $BuiltModuleRootScriptPath -ErrorAction 'SilentlyContinue').FullName
        }

        "`tBuilt Module Root Script   = '$BuiltModuleRootScriptPath'"
    }

    $ReleaseNotesPath = Get-SamplerAbsolutePath -Path $ReleaseNotesPath -RelativeTo $OutputDirectory

    "`tRelease Notes path         = '$ReleaseNotesPath'"

    # Blank row in output.
    ""
}
