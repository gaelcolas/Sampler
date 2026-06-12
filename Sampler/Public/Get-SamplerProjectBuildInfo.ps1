<#
    .SYNOPSIS
        Resolves common project build inputs and identifies the project build type.

    .DESCRIPTION
        This function normalizes values used by build tasks and identifies what kind
        of project is being built.

        A project is treated as a PowerShell module when the source root contains
        exactly one valid module manifest (`*.psd1`, excluding build/analyzer
        settings manifests) and that manifest has the publishing metadata needed for
        a build.

        If the project is a PowerShell module and a built manifest can be resolved
        in output, `HasBuiltOutput` is `$true`; otherwise `$false`.

    .PARAMETER ProjectPath
        Root path of the project or repository.

    .PARAMETER OutputDirectory
        Root output directory that contains the built module and related build
        artifacts for the project.

    .PARAMETER BuiltModuleSubdirectory
        Optional built module subdirectory under the output directory.

    .PARAMETER VersionedOutputDirectory
        Specifies whether the built module output is versioned.

    .PARAMETER ProjectName
        Optional project or module name. If omitted, this function tries to infer
        it from build metadata or the source manifest.

    .PARAMETER SourcePath
        Optional source path. If omitted, this function tries to resolve it.

    .PARAMETER ModuleVersion
        Optional module version. If omitted, this function does not synthesize a
        fallback value and leaves version resolution to downstream build logic such
        as Set-SamplerTaskVariable -AsNewBuild.

    .PARAMETER BuildInfo
        Build configuration hashtable from build.yaml.

    .EXAMPLE
        Get-SamplerProjectBuildInfo -ProjectPath $BuildRoot -OutputDirectory $OutputDirectory -BuildInfo $BuildInfo

#>
function Get-SamplerProjectBuildInfo
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ProjectPath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $OutputDirectory,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $BuiltModuleSubdirectory,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $VersionedOutputDirectory,

        [Parameter()]
        [AllowEmptyString()]
        [System.String]
        $ProjectName,

        [Parameter()]
        [AllowEmptyString()]
        [System.String]
        $SourcePath,

        [Parameter()]
        [AllowEmptyString()]
        [System.String]
        $ModuleVersion,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $BuildInfo
    )

    if ([System.String]::IsNullOrEmpty($ProjectName) -and $BuildInfo.ContainsKey('ProjectName'))
    {
        $ProjectName = $BuildInfo['ProjectName']
    }

    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $ProjectPath -ErrorAction 'Ignore'
    }

    if ([System.String]::IsNullOrEmpty($SourcePath) -and $BuildInfo.ContainsKey('SourcePath'))
    {
        $SourcePath = $BuildInfo['SourcePath']
    }

    if ([System.String]::IsNullOrEmpty($SourcePath))
    {
        $sourceModuleManifest = Get-SamplerProjectModuleManifest -BuildRoot $ProjectPath -ErrorAction 'Ignore'
        $sourcePathCandidate = $null

        if ($sourceModuleManifest)
        {
            $sourcePathCandidate = $sourceModuleManifest.Directory.FullName
        }
        else
        {
            $namedSourcePaths = @(
                (Join-Path -Path $ProjectPath -ChildPath 'source')
                (Join-Path -Path $ProjectPath -ChildPath 'src')
            )

            foreach ($namedSourcePath in $namedSourcePaths)
            {
                if (Test-Path -Path $namedSourcePath)
                {
                    $sourcePathCandidate = $namedSourcePath
                    break
                }
            }
        }

        if ([System.String]::IsNullOrEmpty($sourcePathCandidate))
        {
            $SourcePath = $ProjectPath
        }
        else
        {
            $SourcePath = $sourcePathCandidate
        }
    }

    $SourcePath = Get-SamplerAbsolutePath -Path $SourcePath -RelativeTo $ProjectPath

    if ([System.String]::IsNullOrEmpty($ModuleVersion) -and $BuildInfo.ContainsKey('SemVer'))
    {
        $ModuleVersion = $BuildInfo['SemVer']
    }

    $buildType = 'Other'
    $hasBuiltOutput = $false

    if (-not [System.String]::IsNullOrEmpty($SourcePath))
    {
        $manifestSearchPath = Join-Path -Path $SourcePath -ChildPath '*.psd1'
        $excludedManifestNames = @(
            'build.psd1'
            'analyzersettings.psd1'
        )

        $sourceManifestCandidates = Get-ChildItem -Path $manifestSearchPath -File -ErrorAction 'Ignore' |
            Where-Object -FilterScript {
                $_.Name -notin $excludedManifestNames
            }

        $validSourceManifests = @()

        foreach ($sourceManifestCandidate in $sourceManifestCandidates)
        {
            $testedManifest = Test-ModuleManifest -Path $sourceManifestCandidate.FullName -ErrorAction 'Ignore'

            if (-not $testedManifest)
            {
                continue
            }

            $isValidPublishableManifest =
                $testedManifest.Version -and
                $testedManifest.Guid -and
                $testedManifest.Guid -ne [System.Guid]::Empty -and
                -not [System.String]::IsNullOrEmpty($testedManifest.Author) -and
                -not [System.String]::IsNullOrEmpty($testedManifest.Description)

            if ($isValidPublishableManifest)
            {
                $validSourceManifests += $sourceManifestCandidate
            }
        }

        if ($validSourceManifests.Count -gt 1)
        {
            throw (
                "Found more than one valid source module manifest in '{0}': {1}" -f
                $SourcePath,
                ($validSourceManifests.FullName -join ', ')
            )
        }

        if ($validSourceManifests.Count -eq 1)
        {
            $buildType = 'PowerShellModule'

            if ([System.String]::IsNullOrEmpty($ProjectName))
            {
                $ProjectName = $validSourceManifests[0].BaseName
            }
        }
    }

    if ($buildType -eq 'PowerShellModule')
    {
        if (-not [System.String]::IsNullOrEmpty($ProjectName))
        {
            $getSamplerBuiltModuleManifestParameters = @{
                OutputDirectory          = $OutputDirectory
                BuiltModuleSubdirectory  = $BuiltModuleSubdirectory
                ModuleName               = $ProjectName
                VersionedOutputDirectory = $VersionedOutputDirectory
            }

            if (-not [System.String]::IsNullOrEmpty($ModuleVersion))
            {
                $getSamplerBuiltModuleManifestParameters['ModuleVersion'] = $ModuleVersion
            }

            $builtModuleManifestPath = Get-SamplerBuiltModuleManifest @getSamplerBuiltModuleManifestParameters
            $hasBuiltOutput = [System.Boolean] (Get-Item -Path $builtModuleManifestPath -ErrorAction 'Ignore')
        }
    }

    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Split-Path -Path $ProjectPath -Leaf
    }

    return @{
        ProjectName    = $ProjectName
        SourcePath     = $SourcePath
        ModuleVersion  = $ModuleVersion
        BuildType      = $buildType
        HasBuiltOutput = $hasBuiltOutput
    }
}
