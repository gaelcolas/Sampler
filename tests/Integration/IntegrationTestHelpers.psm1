function Install-TreeCommand
{
    if (-not (Get-Command -Name 'tree' -ErrorAction 'SilentlyContinue'))
    {
        if ($IsMacOS)
        {
            brew install tree
        }

        if ($IsLinux)
        {
            sudo apt-get install tree
        }
    }
}

function Get-DirectoryTree
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    $treeOutput = switch ($true)
        {
            { $IsLinux -or $IsMacOS }
            {
                tree -a $Path
            }

            # Assume Windows
            default
            {
                tree /f $Path
            }
        }

    return $treeOutput
}
