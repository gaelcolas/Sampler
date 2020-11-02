
<#
    .SYNOPSIS
        Sets or removes an attribute on a folder.

    .PARAMETER Folder
        The System.IO.DirectoryInfo object of the folder that should have the
        attribute set or removed.

    .PARAMETER Attribute
       The name of the attribute from the enum System.IO.FileAttributes.

    .PARAMETER Enabled
       If the attribute should be enabled or disabled.
#>
function Set-FileAttribute
{
    [CmdletBinding()]
    [OutputType([System.IO.DirectoryInfo])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.IO.DirectoryInfo]
        $Folder,

        [Parameter(Mandatory = $true)]
        [System.IO.FileAttributes]
        $Attribute,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $Enabled
    )

    switch ($Enabled)
    {
        $true
        {
            $Folder.Attributes = $Folder.Attributes -bor [System.IO.FileAttributes]$Attribute
        }

        $false
        {
            $Folder.Attributes = $Folder.Attributes -bxor [System.IO.FileAttributes]$Attribute
        }
    }
}
