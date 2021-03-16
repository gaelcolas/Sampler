<#
.SYNOPSIS
Loads the PowerShell data file of a module manifest.

.DESCRIPTION
This function loads a psd1 (usually a module manifest), and return the hashtable.
This implementation works around the issue where Windows PowerShell version have issues
with the pwsh $Env:PSModulePath such as in vscode with the vscode powershell extension.

.PARAMETER ModuleManifestPath
Path to the ModuleManifest to load. This will not use Import-Module because the
module may not be finished building, and might be missing some information to make
it a valid module manifest.

.EXAMPLE
Get-SamplerModuleInfo -ModuleManifestPath C:\src\MyProject\output\MyProject\MyProject.psd1

#>
function Get-SamplerModuleInfo
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Path')]
        [ValidateNotNull()]
        [System.String]
        $ModuleManifestPath
    )

    $isImportPowerShellDataFileAvailable = Get-Command -Name Import-PowerShellDataFile -ErrorAction SilentlyContinue

    if ($PSversionTable.PSversion.Major -le 5 -and -not $isImportPowerShellDataFileAvailable)
    {
        Import-Module -Name Microsoft.PowerShell.Utility -RequiredVersion 3.1.0.0
    }

    Import-PowerShellDataFile -Path $ModuleManifestPath -ErrorAction 'Stop'
}
