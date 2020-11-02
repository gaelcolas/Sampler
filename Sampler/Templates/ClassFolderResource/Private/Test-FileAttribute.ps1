
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
    $isPresent = $false

    if ($attributeValue -gt 0 )
    {
        $isPresent = $true
    }

    return $isPresent
}
