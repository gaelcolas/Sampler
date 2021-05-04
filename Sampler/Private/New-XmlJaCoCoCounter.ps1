
<#
    .SYNOPSIS
        Returns a new JaCoCo XML counter node with the specified covered and missed
        attributes.

    .DESCRIPTION
        Returns a new JaCoCo XML counter node with the specified covered and missed
        attributes.

    .PARAMETER XmlNode
        The XML node that the element should be part appended to as a child.

    .PARAMETER CounterType
        The JaCoCo counter type.

    .PARAMETER Covered
        The number of covered lines to be used as the value for the covered XML
        attribute.

    .PARAMETER Missed
        The number of missed lines to be used as the value for the missed XML
        attribute.

    .PARAMETER PassThru
        Returns the element that was created.

    .EXAMPLE
        New-SamplerXmlJaCoCoCounter -XmlDocument $myXml -CounterType 'CLASS' -Covered 1 -Missed 2
#>
function New-SamplerXmlJaCoCoCounter
{
    [CmdletBinding()]
    [OutputType([System.Xml.XmlElement])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlNode]
        $XmlNode,

        [Parameter(Mandatory = $true)]
        [ValidateSet('CLASS', 'LINE', 'METHOD', 'INSTRUCTION')]
        [System.String]
        $CounterType,

        [Parameter()]
        [System.UInt32]
        $Covered = 0,

        [Parameter()]
        [System.UInt32]
        $Missed = 0,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru

    )

    $xmlElement = $XmlNode.OwnerDocument.CreateElement('counter')

    $xmlElement.SetAttribute('type', $CounterType)
    $xmlElement.SetAttribute('missed', $Missed)
    $xmlElement.SetAttribute('covered', $Covered)

    $XmlNode.AppendChild($xmlElement) | Out-Null

    if ($PassThru.IsPresent)
    {
        return $xmlElement
    }
}
