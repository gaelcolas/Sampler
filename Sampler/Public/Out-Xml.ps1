
<#
    .SYNOPSIS
        Outputs an XML document to a file.

    .DESCRIPTION
        Outputs an XML document to the file specified in the parameter Path.

    .PARAMETER XmlDocument
        The XML document to format.

    .PARAMETER Path
        The path to the file name to write to.

    .PARAMETER Encoding
        Specifies the encoding for the file.

    .EXAMPLE
        Out-Xml -XmlDocument '<?xml version="1.0"?><a><b /></a>' -Encoding 'UTF8'
#>
function Out-Xml
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]
        $XmlDocument,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter()]
        [ValidateSet('UTF8')]
        [System.String]
        $Encoding = 'UTF8'
    )

    $xmlSettings = New-Object -TypeName 'System.Xml.XmlWriterSettings'

    $xmlSettings.Encoding = [System.Text.Encoding]::$Encoding

    $xmlWriter = [System.Xml.XmlWriter]::Create($Path, $xmlSettings)

    $XmlDocument.Save($xmlWriter)

    $XmlWriter.Flush()
    $xmlWriter.Close()
}
