
<#
    .SYNOPSIS
        Creates a filesystem link (symbolic link or junction) at a given path.

    .DESCRIPTION
        Creates a filesystem link at `LinkPath` pointing to `TargetPath`. The
        algorithm is:

        1. If `LinkPath` already exists, it is removed with `-Recurse -Force`.
        2. A symbolic link creation is attempted via `New-Item -ItemType SymbolicLink`.
           On success, `'SymbolicLink'` is returned.
        3. On failure: if the platform is not Windows, the error is re-thrown.
           On Windows, execution falls through to the junction fallback.
        4. A junction creation is attempted via `New-Item -ItemType Junction`.
           On success, `'Junction'` is returned.
        5. If junction creation also fails, a combined error message is thrown.

    .PARAMETER LinkPath
        The filesystem path where the link should be created.

    .PARAMETER TargetPath
        The target path the link should point to.

    .PARAMETER IsWindowsPlatform
        Whether the current platform is Windows. Defaults to
        `($env:OS -eq 'Windows_NT')`. Override for testing purposes.

    .EXAMPLE
        New-SamplerWorkspaceModuleLink -LinkPath 'C:\src\MyRepo\output\module\OtherModule' -TargetPath 'C:\src\OtherModule\output\module\OtherModule'
        # SymbolicLink
#>
function New-SamplerWorkspaceModuleLink
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LinkPath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TargetPath,

        [Parameter()]
        [System.Boolean]
        $IsWindowsPlatform = ($env:OS -eq 'Windows_NT')
    )

    if (Test-Path -Path $LinkPath)
    {
        Remove-Item -Path $LinkPath -Recurse -Force
    }

    if ($PSCmdlet.ShouldProcess($LinkPath, ('Create workspace module link to {0}' -f $TargetPath)))
    {
        try
        {
            $newItemParams = @{
                Path        = $LinkPath
                ItemType    = 'SymbolicLink'
                Target      = $TargetPath
                Force       = $true
                ErrorAction = 'Stop'
            }

            $null = New-Item @newItemParams
            return 'SymbolicLink'
        }
        catch
        {
            if (-not $IsWindowsPlatform)
            {
                throw ("Failed to create the symbolic link '{0}' -> '{1}'. Ensure symbolic links are allowed in this session. {2}" -f $LinkPath, $TargetPath, $_.Exception.Message)
            }
        }

        try
        {
            $newItemParams = @{
                Path        = $LinkPath
                ItemType    = 'Junction'
                Target      = $TargetPath
                Force       = $true
                ErrorAction = 'Stop'
            }

            $null = New-Item @newItemParams
            return 'Junction'
        }
        catch
        {
            throw ("Failed to create a local workspace link '{0}' -> '{1}'. Symbolic link and junction creation both failed. {2}" -f $LinkPath, $TargetPath, $_.Exception.Message)
        }
    }
}
