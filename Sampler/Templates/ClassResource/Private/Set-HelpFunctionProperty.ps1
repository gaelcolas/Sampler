
<#
    .SYNOPSIS
        Sets a property on a dummy object.
        This function is just an example of how to use an helper function
        in Class based resource.

    .PARAMETER Object
        A dummy Object

    .PARAMETER Property
       The name of the property from the dummy object that you want to change.

    .PARAMETER Value
       Value of the property.
#>
function Set-HelpFunctionProperty
{
    [CmdletBinding()]
    [OutputType([System.IO.DirectoryInfo])]
    param
    (
        [Parameter(Mandatory = $true)]
        [pscustomobject]
        $Object,

        [Parameter(Mandatory = $true)]
        [string]
        $Property,

        [Parameter(Mandatory = $true)]
        $Value
    )

    $Object.$Property = $Value
}
