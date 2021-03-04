<#
.SYNOPSIS
Gets the path to the Module manifest in the source folder.

.DESCRIPTION
This command finds the Module Manifest of the current Sampler project,
regardless of the name of the source folder (src, source, or MyProjectName).
It looks for psd1 that are not build.psd1 or analyzersettings, 1 folder under
the $BuildRoot, and where a property ModuleVersion is set.

This allows to deduct the Module name's from that module Manifest.

.PARAMETER BuildRoot
Root folder where the build is called, usually the root of the repository.

.EXAMPLE
Get-SamplerProjectModuleManifest -BuildRoot .

#>
function Get-SamplerProjectModuleManifest
{
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $BuildRoot
    )

    $excludeFiles = @(
        'build.psd1'
        'analyzersettings.psd1'
    )

    $moduleManifestItem = Get-ChildItem -Path "$BuildRoot\*\*.psd1" -Exclude $excludeFiles |
            Where-Object -FilterScript {
                ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                $(Test-ModuleManifest -Path $_.FullName -ErrorAction 'SilentlyContinue' ).Version
            }

    if ($moduleManifestItem.Count -gt 1)
    {
        throw ("Found more than one project folder containing a module manifest, please make sure there are only one; `n Manifest: {0}" -f ($moduleManifestItem.FullName -join "`n Manifest: "))
    }
    else
    {
        return $moduleManifestItem
    }
}
