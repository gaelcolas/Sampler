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

    if ([System.String]::IsNullOrEmpty($Path))
    {
        if ($PSBoundParameters.ContainsKey('RelativeTo') -and -not [System.String]::IsNullOrEmpty($RelativeTo))
        {
            [System.Io.Path]::GetFullPath($RelativeTo)
        }
        else
        {
            [System.Io.Path]::GetFullPath('.')
        }
    }
    elseif (
        -not (Split-Path -IsAbsolute -Path $Path) -and
        $Path -notmatch '^\\|^\/' -and
        $PSBoundParameters.ContainsKey('RelativeTo')
    )
    {
        if (Split-Path -IsAbsolute -Path $RelativeTo)
        {
            [System.IO.Path]::GetFullPath((Join-Path -Path $RelativeTo -ChildPath $Path))
        }
        else
        {
            $AbsoluteRelativeTo = [System.IO.Path]::GetFullPath($RelativeTo)
            [System.IO.Path]::GetFullPath((Join-Path -Path $AbsoluteRelativeTo -ChildPath $Path))
        }
    }
    else
    {
        [System.IO.Path]::GetFullPath($Path)
    }
}
