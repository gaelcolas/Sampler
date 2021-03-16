<#
    .SYNOPSIS
        Gets the absolute value of a path, that can be relative to another folder
        or the current Working Directory `$PWD` or Drive.

    .DESCRIPTION
        This function will resolve the Absolute value of a path, whether it's
        potentially relative to another path, relative to the current working
        directory, or it's provided with an absolute Path.

        The Path does not need to exist, but the command will use the right
        [System.Io.Path]::DirectorySeparatorChar for the OS, and adjust the
        `..` and `.` of a path by removing parts of a path when needed.

    .PARAMETER Path
        Relative or Absolute Path to resolve, can also be $null/Empty and will
        return the RelativeTo absolute path.
        It can be Absolute but relative to the current drive: i.e. `/Windows`
        would resolve to `C:\Windows` on most Windows systems.

    .PARAMETER RelativeTo
        Path to prepend to $Path if $Path is not Absolute.
        If $RelativeTo is not absolute either, it will first be resolved
        using [System.Io.Path]::GetFullPath($RelativeTo) before
        being pre-pended to $Path.

    .EXAMPLE
        Get-SamplerAbsolutePath -Path '/src' -RelativeTo 'C:\Windows'
        # C:\src

    .EXAMPLE
        Get-SamplerAbsolutePath -Path 'MySubFolder' -RelativeTo '/src'
        # C:\src\MySubFolder

    .NOTES
        When the root drive is omitted on Windows, the path is not considered absolute.
        `Split-Path -IsAbsolute -Path '/src/`
        # $false
#>
function Get-SamplerAbsolutePath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [AllowNull()]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $RelativeTo
    )

    if (-not [System.Io.Path]::IsPathRooted($RelativeTo))
    {
        # If the path is not rooted it's a relative path
        $RelativeTo = Join-Path -Path ([System.Io.Path]::GetFullPath('.')) -ChildPath $RelativeTo
    }
    elseif (-not (Split-Path -IsAbsolute -Path $RelativeTo) -and [System.Io.Path]::IsPathRooted($RelativeTo))
    {
        # If the path is not Absolute but is rooted, it's starts with / or \ on Windows.
        # Add the Current PSDrive root
        $CurrentDriveRoot = $pwd.drive.root
        $RelativeTo = Join-Path -Path $CurrentDriveRoot -ChildPath $RelativeTo
    }

    if ($PSVersionTable.PSVersion.Major -ge 7)
    {
        # This behave differently in 5.1 where * are forbidden. :(
        $RelativeTo = [System.io.Path]::GetFullPath($RelativeTo)
    }

    if (-not [System.Io.Path]::IsPathRooted($Path))
    {
        # If the path is not rooted it's a relative path (relative to $RelativeTo)
        $Path = Join-Path -Path $RelativeTo -ChildPath $Path
    }
    elseif (-not (Split-Path -IsAbsolute -Path $Path) -and [System.Io.Path]::IsPathRooted($Path))
    {
        # If the path is not Absolute but is rooted, it's starts with / or \ on Windows.
        # Add the Current PSDrive root
        $CurrentDriveRoot = $pwd.drive.root
        $Path = Join-Path -Path $CurrentDriveRoot -ChildPath $Path
    }
    # Else The Path is Absolute

    if ($PSVersionTable.PSVersion.Major -ge 7)
    {
        # This behave differently in 5.1 where * are forbidden. :(
        $Path = [System.io.Path]::GetFullPath($Path)
    }

    return $Path
}
