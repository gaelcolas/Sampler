
<#
    .SYNOPSIS
        Get the module version from the module built by Sampler.

    .DESCRIPTION
        Will read the ModuleVersion and PrivateData.PSData.Prerelease tag of the Module Manifest
        that has been built by Sampler, by looking into the OutputDirectory where the Project's
        Module should have been built.

    .PARAMETER OutputDirectory
        Output directory (usually as defined by the Project).
        By default it is set to 'output' in a Sampler project.

    .PARAMETER BuiltModuleSubdirectory
        Sub folder where you want to build the Module to (instead of $OutputDirectory/$ModuleName).
        This is especially useful when you want to build DSC Resources, but you don't want the
        `Get-DscResource` command to find several instances of the same DSC Resources because
        of the overlapping $Env:PSmodulePath (`$buildRoot/output` for the built module and `$buildRoot/output/RequiredModules`).

        In most cases I would recommend against setting $BuiltModuleSubdirectory.

    .PARAMETER VersionedOutputDirectory
        Whether the Module is built with its versioned Subdirectory, as you would see it on a System.
        For instance, if VersionedOutputDirectory is $true, the built module's ModuleBase would be: `output/MyModuleName/2.0.1/`

    .PARAMETER ModuleName
        Name of the Module to retrieve the version from its manifest (See Get-SamplerProjectName).

    .EXAMPLE
        Get-BuiltModuleVersion -OutputDirectory 'output' -ProjectName Sampler

#>
function Get-BuiltModuleVersion
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.String]
        $OutputDirectory,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $BuiltModuleSubdirectory,

        [Parameter(Mandatory = $true)]
        [Alias('ProjectName')]
        [System.String]
        $ModuleName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $VersionedOutputDirectory
    )

    $BuiltModuleManifestPath = Get-SamplerBuiltModuleManifest @PSBoundParameters

    Write-Verbose -Message (
        "Get the module version from module manifest in path '{0}'." -f $BuiltModuleManifestPath
    )

    $moduleInfo = Import-PowerShellDataFile -Path $BuiltModuleManifestPath -ErrorAction 'Stop'

    $ModuleVersion = $moduleInfo.ModuleVersion

    if ($moduleInfo.PrivateData.PSData.Prerelease)
    {
        $ModuleVersion = $ModuleVersion + '-' + $moduleInfo.PrivateData.PSData.Prerelease
    }

    $moduleVersionParts = Split-ModuleVersion -ModuleVersion $ModuleVersion

    Write-Verbose -Message (
        "Current module version is '{0}'." -f $moduleVersionParts.ModuleVersion
    )

    return $moduleVersionParts.ModuleVersion
}
