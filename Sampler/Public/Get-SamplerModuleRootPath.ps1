<#
.SYNOPSIS
Gets the absolute ModuleRoot path (the psm1) of a module.

.DESCRIPTION
This function reads the module manifest (.psd1) and if the ModuleRoot property
is defined, it will resolve its absolute path based on the ModuleManifest's Path.

If no ModuleRoot is defined, then this function will return $null.

.PARAMETER ModuleManifestPath
The path (relative to the current working directory or absolute) to the ModuleManifest to
read to find the ModuleRoot.

.EXAMPLE
Get-SamplerModuleRootPath -ModuleManifestPath C:\src\MyModule\output\MyModule\2.3.4\MyModule.psd1
# C:\src\MyModule\output\MyModule\2.3.4\MyModule.psm1

#>
function Get-SamplerModuleRootPath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Path')]
        [ValidateNotNull()]
        [System.String]
        $ModuleManifestPath
    )

    $moduleInfo = Get-SamplerModuleInfo @PSBoundParameters

    if ($moduleInfo.Keys -contains 'RootModule')
    {
        Get-SamplerAbsolutePath -Path $moduleInfo.RootModule -RelativeTo (Split-Path -Parent -Path $BuiltModuleManifest)
    }
    else
    {
        return $null
    }
}
