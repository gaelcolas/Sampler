<#
.SYNOPSIS
Gets the project's source Path based on the ModuleManifest location.

.DESCRIPTION
By finding the ModuleManifest of the project using `Get-SamplerProjectModuleManifest`
this function assumes that the source folder is the parent folder of
that module manifest.
This allows the source folder to be src, source, or the Module name's, without
hardcoding the name.

.PARAMETER BuildRoot
BuildRoot of the Sampler project to search the Module manifest from.

.EXAMPLE
Get-SamplerSourcePath -BuildRoot 'C:\src\MyModule'

#>
function Get-SamplerSourcePath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $BuildRoot
    )

    return (Get-SamplerProjectModuleManifest -BuildRoot $BuildRoot).Directory.FullName
}
