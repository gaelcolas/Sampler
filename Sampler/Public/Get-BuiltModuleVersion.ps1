<#
.SYNOPSIS
Get the module version from the module built by Sampler.

.DESCRIPTION
Will read the ModuleVersion and PrivateData.PSData.Prerelease tag of the Module Manifest
that has been built by Sampler, by looking into the OutputDirectory where the Project's
Module should have been built.

.PARAMETER OutputDirectory
Output directory as defined by the Project.
By default it is set to 'output' in a Sampler project.

.PARAMETER ProjectName
Name of the current project (See Get-SamplerProjectName).

.EXAMPLE
Get-BuiltModuleVersion -OutputDirectory 'output' -ProjectName Sampler

#>
function Get-BuiltModuleVersion
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        $OutputDirectory,

        [Parameter()]
        [System.String]
        $ProjectName
    )

    $ModuleManifestPath = "$OutputDirectory/$ProjectName/*/$ProjectName.psd1"

    Write-Verbose -Message (
        "Get the module version from module manifest in path '{0}'." -f $ModuleManifestPath
    )

    $moduleInfo = Import-PowerShellDataFile -Path $ModuleManifestPath -ErrorAction 'Stop'

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
