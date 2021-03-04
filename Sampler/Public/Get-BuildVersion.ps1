<#
.SYNOPSIS
Calculates or retrieves the version of the Repository.

.DESCRIPTION
Attempts to retrieve the version associated with the repository or the module within
the repository.
If the Version is not provided, the preferred way is to use GitVersion if available,
but alternatively it will locate a module manifest in the source folder and read its version.

.PARAMETER ModuleManifestPath
Path to the Module Manifest that should determine the version if GitVersion is not available.

.PARAMETER ModuleVersion
Provide the Version to be splitted and do not rely on GitVersion or the Module's manifest.

.EXAMPLE
Get-BuildVersion -ModuleManifestPath source\MyModule.psd1

#>
function Get-BuildVersion
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleManifestPath,

        [Parameter()]
        [System.String]
        $ModuleVersion
    )

    if ([System.String]::IsNullOrEmpty($ModuleVersion))
    {
        Write-Verbose -Message 'Module version is not determined yet. Evaluating methods to get module version.'

        if ((Get-Command -Name 'gitversion' -ErrorAction 'SilentlyContinue'))
        {
            Write-Verbose -Message 'Using the version from GitVersion.'

            $ModuleVersion = (gitversion | ConvertFrom-Json -ErrorAction 'Stop').NuGetVersionV2
        }
        else
        {
            Write-Verbose -Message (
                "GitVersion is not installed. Trying to use the version from module manifest in path '{0}'." -f $ModuleManifestPath
            )

            $moduleInfo = Import-PowerShellDataFile -Path $ModuleManifestPath -ErrorAction 'Stop'

            $ModuleVersion = $moduleInfo.ModuleVersion

            if ($moduleInfo.PrivateData.PSData.Prerelease)
            {
                $ModuleVersion = $ModuleVersion + '-' + $moduleInfo.PrivateData.PSData.Prerelease
            }
        }
    }

    $moduleVersionParts = Split-ModuleVersion -ModuleVersion $ModuleVersion

    Write-Verbose -Message (
        "Current module version is '{0}'." -f $moduleVersionParts.ModuleVersion
    )

    return $moduleVersionParts.ModuleVersion
}
