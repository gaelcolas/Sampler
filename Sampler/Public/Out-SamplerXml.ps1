
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
        Out-SamplerXml -Path 'C:\temp\my.xml' -XmlDocument '<?xml version="1.0"?><a><b /></a>' -Encoding 'UTF8'
#>
function Out-SamplerXml
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
        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Latin1', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
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
