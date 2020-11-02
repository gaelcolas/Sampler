
<#
    .SYNOPSIS
        This function is use to generate a dummy object for sampler template.
        It can be replace by real function.
        Or if you use a .net object, you can rename this function and replace
        this content.

    .PARAMETER Name
        It's dummy parameter
#>
function Get-DummyObject
{
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Name
    )

    [pscustomobject]@{
        Name = $Name
        PropertyMandatory          = $true
        PropertyBoolReadWrite      = $false
        PropertyBoolReadOnly       = $true
        PropertyStringReadOnly     = 'This is a readonly string'
    }
}
