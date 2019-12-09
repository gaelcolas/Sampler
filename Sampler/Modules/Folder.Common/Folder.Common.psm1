
<#
    .SYNOPSIS
        Test if an attribute on a folder is present.

    .PARAMETER Folder
        The System.IO.DirectoryInfo object of the folder that should be checked
        for the attribute.

    .PARAMETER Attribute
        The name of the attribute from the enum System.IO.FileAttributes.
#>
function Test-FileAttribute
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.IO.DirectoryInfo]
        $Folder,

        [Parameter(Mandatory = $true)]
        [System.IO.FileAttributes]
        $Attribute
    )

    $attributeValue = $Folder.Attributes -band [System.IO.FileAttributes]::$Attribute

    switch ($attributeValue)
    {
        { $_ -gt 0 }
        {
            $isPresent = $true
        }

        default
        {
            $isPresent = $false
        }
    }

    return $isPresent
}

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
            $Folder.Attributes = [System.IO.FileAttributes]::$Attribute

        }

        $false
        {
            $Folder.Attributes -= [System.IO.FileAttributes]::$Attribute
        }
    }
}

Export-ModuleMember -Function Set-FileAttribute, Test-FileAttribute
