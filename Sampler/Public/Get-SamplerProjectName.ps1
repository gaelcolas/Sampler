
<#
.SYNOPSIS
Gets the Project Name based on the ModuleManifest if Available.

.DESCRIPTION
Finds the Module Manifest through `Get-SamplerProjectModuleManifest`
and deduce ProjectName based on the BaseName of that manifest.

.PARAMETER BuildRoot
BuildRoot of the Sampler project to search the Module manifest from.

.EXAMPLE
Get-SamplerProjectName -BuildRoot 'C:\src\MyModule'

#>
function Get-SamplerProjectName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $BuildRoot
    )

    return (Get-SamplerProjectModuleManifest -BuildRoot $BuildRoot).BaseName
}
