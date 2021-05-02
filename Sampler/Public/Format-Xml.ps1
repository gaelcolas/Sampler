
<#
    .SYNOPSIS
        Formats an XML document and returns a string.

    .DESCRIPTION
        Formats an XML document and returns a string.

    .PARAMETER XmlDocument
        The XML document to format.

    .PARAMETER Indented
        Specifies if the XML document should be formatted with indentation.

    .EXAMPLE
        Format-Xml -XmlDocument '<?xml version="1.0"?><a><b /></a>' -Indented

    .EXAMPLE
        $xmlResult | Format-Xml -Indented

#>
function Format-Xml
{
    [OutputType([System.String])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Xml.XmlDocument]
        $XmlDocument,

        [Parameter()]
        [Switch]
        $Indented
    )

    $xmlSettings = New-Object -TypeName 'System.Xml.XmlWriterSettings'

    if ($Indented.IsPresent)
    {
        $xmlSettings.Indent = $true
    }
    else
    {
        $xmlSettings.Indent = $false
    }

    $xmlOutput = New-Object -TypeName 'System.Text.StringBuilder'

    $xmlWriter = [System.Xml.XmlWriter]::Create($xmlOutput, $xmlSettings)

    $XmlDocument.Save($xmlWriter)

    $XmlWriter.Flush()
    $xmlWriter.Close()

    return $xmlOutput.ToString()
}
