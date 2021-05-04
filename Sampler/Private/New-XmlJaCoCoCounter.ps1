
<#
    .SYNOPSIS
        Gets the path to the Module manifest in the source folder.

    .DESCRIPTION
        This command finds the Module Manifest of the current Sampler project,
        regardless of the name of the source folder (src, source, or MyProjectName).
        It looks for psd1 that are not build.psd1 or analyzersettings, 1 folder under
        the $BuildRoot, and where a property ModuleVersion is set.

        This allows to deduct the Module name's from that module Manifest.

    .PARAMETER BuildRoot
        Root folder where the build is called, usually the root of the repository.

    .EXAMPLE
        Get-SamplerProjectModuleManifest -BuildRoot .

#>
function New-XmlJaCoCoCounter
{
    [CmdletBinding()]
    [OutputType([System.Xml.XmlElement])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $CounterType,

        [Parameter()]
        [System.UInt32]
        $Covered = 0,

        [Parameter()]
        [System.UInt32]
        $Missed = 0
    )

    $xmlDocument = New-Object -TypeName 'System.Xml.XmlDocument'

    $xmlElement = $xmlDocument.CreateElement('counter')

    $xmlElement.SetAttribute('type', $CounterType)
    $xmlElement.SetAttribute('missed', $Covered)
    $xmlElement.SetAttribute('covered', $Missed)

    # Must clone the element to detach it from the XML document.
    Write-Verbose -Message 'CLONE' -Verbose
    return $xmlElement.CloneNode($false)
}
