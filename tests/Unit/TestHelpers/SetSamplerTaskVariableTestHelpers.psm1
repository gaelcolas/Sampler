<#
    .SYNOPSIS
        Returns the machine's PSModulePath.
#>
function Get-SystemPSModulePath
{
    $psModulePath = [System.Environment]::GetEnvironmentVariable('PSModulePath', 'Machine') -split [System.IO.Path]::PathSeparator |
        Select-Object -Unique
    Where-Object { $_ -ne '' }

    return $psModulePath -join [System.IO.Path]::PathSeparator
}

<#
    .SYNOPSIS
        Returns the user's PSModulePath.
#>
function Get-UserPSModulePath
{
    $psModulePath = $env:PSModulePath -split [System.IO.Path]::PathSeparator |
        Select-Object -Unique
    Where-Object { $_ -ne '' }

    return $psModulePath -join [System.IO.Path]::PathSeparator
}

<#
    .SYNOPSIS
        Removed duplicate entries from the given path.

    .PARAMETER Path
        The path to remove duplicate entries from.
#>
function Remove-DuplicateElementsInPath
{
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    $value = $Path -split [System.IO.Path]::PathSeparator |
        Select-Object -Unique
    Where-Object { $_ -ne '' }

    return $value -join [System.IO.Path]::PathSeparator
}

<#
    .SYNOPSIS
        Returns if running on Windows.
#>
function Test-IsWindows
{
    return [System.Environment]::OSVersion.Platform -like 'Win*'
}
