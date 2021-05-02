
<#
    .SYNOPSIS
        Returns a hashtable containing all the attributes in the given search query.

    .DESCRIPTION
        This command returns a hashtable containing all the attributes in the
        path provided in the parameter XPath.


    .PARAMETER XmlDocument
        Specifies an XML document to perform the search query on.

    .PARAMETER XPath
        Specifies an XPath search query.

    .EXAMPLE
        $xmlResult | Get-XmlAttribute -XPath '/report/counter[@type="LINE"]'

#>
function Get-XmlAttribute
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '')]
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Xml.XmlDocument]
        $XmlDocument,

        [Parameter(Mandatory = $true)]
        [System.String]
        $XPath
    )

    $attributeValues = @{}

    $filteredDocument = $XmlDocument | Select-Xml -XPath $XPath

    ($filteredDocument.Node | Select-Xml -XPath '@*').Node | ForEach-Object -Process {
        $attributeValues[$_.Name] = $_.Value
    }

    return $attributeValues
}
