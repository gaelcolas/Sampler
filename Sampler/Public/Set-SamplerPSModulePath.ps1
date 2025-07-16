<#
    .SYNOPSIS
        Sets the PSModulePath for the build environment.

    .DESCRIPTION
        This command let you define the PSModulePath for the build environment. This could
        be important for DSC related builds when there are conflicts with modules in the
        Program Files folder.

    .PARAMETER PSModulePath
        Makes the command to set the PSModulePath to the specified value.

    .PARAMETER BuiltModuleSubdirectory
        The BuiltModuleSubdirectory that should be added to the PSModulePath.

    .PARAMETER RequiredModulesDirectory
        The RequiredModulesDirectory that should be added to the PSModulePath.

    .PARAMETER RemovePersonal
        Removes the personal module path from the PSModulePath.

    .PARAMETER RemoveProgramFiles
        Removes the Program Files module path from the PSModulePath.

    .PARAMETER RemoveWindows
        Removes the Windows module path from the PSModulePath.

    .PARAMETER SetSystemDefault
        Sets the PSModulePath to the default value for the system.

    .PARAMETER PassThru
        Returns the PSModulePath after the command has been executed.

    .EXAMPLE
        Set-SamplerPSModulePath -PSModulePath "C:\Modules" -RemovePersonal -RemoveProgramFiles
#>

function Set-SamplerPSModulePath
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'ByPath')]
        [string]
        $PSModulePath,

        [Parameter()]
        [string]
        $BuiltModuleSubdirectory,

        [Parameter()]
        [string]
        $RequiredModulesDirectory,

        [Parameter(ParameterSetName = 'BySwitches')]
        [switch]
        $RemovePersonal,

        [Parameter(ParameterSetName = 'BySwitches')]
        [switch]
        $RemoveProgramFiles,

        [Parameter(ParameterSetName = 'BySwitches')]
        [switch]
        $RemoveWindows,

        [Parameter(ParameterSetName = 'BySwitches')]
        [switch]
        $SetSystemDefault,

        [Parameter()]
        [switch]
        $PassThru
    )

    $pathSeparator = [System.IO.Path]::PathSeparator
    $directorySeparator = [System.IO.Path]::DirectorySeparatorChar

    if ($BuiltModuleSubdirectory)
    {
        $BuiltModuleSubdirectory = $BuiltModuleSubdirectory.TrimEnd($directorySeparator)
    }

    if ($RequiredModulesDirectory)
    {
        $RequiredModulesDirectory = $RequiredModulesDirectory.TrimEnd($directorySeparator)
    }

    $newModulePath = if ($PSCmdlet.ParameterSetName -eq 'ByPath')
    {
        $PSModulePath
    }
    elseif ($SetSystemDefault)
    {
        [System.Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')
    }
    else
    {
        $env:PSModulePath
    }

    $newModulePath = $newModulePath -split $pathSeparator |
        Select-Object -Unique |
            Where-Object { $_ }
    Write-Verbose -Message "`t...The 'PSModulePath' has $($newModulePath.Count) paths"
    Write-Debug -Message "The 'PSModulePath' is '$newModulePath'"

    if ($RemovePersonal)
    {
        $newModulePath = $newModulePath -notmatch '.+Documents.(Windows)?PowerShell.Modules'
        Write-Verbose -Message "`t...Removing Personal from 'PSModulePath'"
    }

    if ($RemoveProgramFiles)
    {
        $newModulePath = $newModulePath -notmatch '.+Program Files.(Windows)?PowerShell.(7.)?Modules'
        Write-Verbose -Message "`t...Removing Program Files from 'PSModulePath'"
    }

    if ($RemoveWindows)
    {
        $newModulePath = $newModulePath -ne 'C:\Windows\system32\WindowsPowerShell\v1.0\Modules'
        Write-Warning -Message "It is not recommended to remove the Windows 'PSModulePath'"
        Write-Verbose -Message "`t...Removing Windows from 'PSModulePath'"
    }
    Write-Verbose -Message "`t...The 'PSModulePath' has $($newModulePath.Count) paths"
    Write-Debug -Message "The 'PSModulePath' is '$newModulePath'"

    if ($RequiredModulesDirectory)
    {
        if ($newModulePath -contains $RequiredModulesDirectory)
        {
            Write-Verbose -Message "`t...Removing RequiredModulesDirectory from 'PSModulePath'"
            $newModulePath = $newModulePath -ne $RequiredModulesDirectory
        }
        Write-Verbose -Message "`t...Adding 'RequiredModulesDirectory' to 'PSModulePath'"
        $newModulePath = @($RequiredModulesDirectory) + $newModulePath
    }
    else
    {
        Write-Warning -Message "The parameter 'RequiredModulesDirectory' is not set"
    }

    if ($BuiltModuleSubdirectory)
    {
        if ($newModulePath -contains $BuiltModuleSubdirectory)
        {
            Write-Verbose -Message "`t...Removing BuiltModuleSubdirectory from 'PSModulePath'"
            $newModulePath = $newModulePath -ne $BuiltModuleSubdirectory
        }
        Write-Verbose -Message "`t...Adding 'BuiltModuleSubdirectory' to 'PSModulePath'"
        $newModulePath = @($BuiltModuleSubdirectory) + $newModulePath
    }
    else
    {
        Write-Warning -Message "The parameter 'BuiltModuleSubdirectory' is not set"
    }

    $newModulePath = $newModulePath -join $pathSeparator
    Write-Verbose -Message "`t...Writing '`$env:PSModulePath' variable"

    if ($PSCmdlet.ShouldProcess($env:PSModulePath, "Set PSModulePath to '$newModulePath'"))
    {
        $env:PSModulePath = $newModulePath
    }

    if ($PassThru)
    {
        $newModulePath
    }
}
