
<#
    .SYNOPSIS
        Returns the Platform name.

    .DESCRIPTION
        Gets whether the platform is Windows, Linux or MacOS.

    .EXAMPLE
        Get-OperatingSystemShortName # no Parameter needed

    .NOTES
        General notes
#>
function Get-OperatingSystemShortName
{
    [CmdletBinding()]
    param ()

    $osShortName = if ($IsWindows -or $PSVersionTable.PSVersion.Major -le 5)
    {
        'Windows'
    }
    elseif ($IsMacOS)
    {
        'MacOS'
    }
    else
    {
        'Linux'
    }

    return $osShortName
}
