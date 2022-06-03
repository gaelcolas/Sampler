BeforeAll {
    $script:moduleName = 'Sampler'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 3)
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    }

    # Re-import the module using force to get any code changes between runs.
    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Module -Name $script:moduleName
}

Describe 'Merge-JaCoCoReport' {
    Context 'When lines in a sourcefile is missing in original document' {
        BeforeAll {
            $mockXmlDocument1 = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <class name="3.0.0\prefix" sourcefilename="prefix.ps1">
            <method name="&lt;script&gt;" desc="()" line="2">
                <counter type="INSTRUCTION" missed="0" covered="3" />
                <counter type="LINE" missed="0" covered="3" />
                <counter type="METHOD" missed="0" covered="1" />
            </method>
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
        </class>
        <sourcefile name="prefix.ps1">
            <line nr="2" mi="0" ci="1" mb="0" cb="0" />
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
            <line nr="5" mi="0" ci="1" mb="0" cb="0" />
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
        </sourcefile>
        <counter type="INSTRUCTION" missed="0" covered="3" />
        <counter type="LINE" missed="0" covered="3" />
        <counter type="METHOD" missed="0" covered="1" />
        <counter type="CLASS" missed="0" covered="1" />
    </package>
    <counter type="INSTRUCTION" missed="0" covered="3" />
    <counter type="LINE" missed="0" covered="3" />
    <counter type="METHOD" missed="0" covered="1" />
    <counter type="CLASS" missed="0" covered="1" />
</report>
"@

    $mockXmlDocument2 = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <class name="3.0.0\prefix" sourcefilename="prefix.ps1">
            <method name="&lt;script&gt;" desc="()" line="2">
                <counter type="INSTRUCTION" missed="0" covered="3" />
                <counter type="LINE" missed="0" covered="3" />
                <counter type="METHOD" missed="0" covered="1" />
            </method>
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
        </class>
        <sourcefile name="prefix.ps1">
            <line nr="10" mi="0" ci="1" mb="0" cb="0" />
            <line nr="11" mi="1" ci="0" mb="0" cb="0" />
            <counter type="INSTRUCTION" missed="1" covered="1" />
            <counter type="LINE" missed="1" covered="1" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
        </sourcefile>
        <counter type="INSTRUCTION" missed="1" covered="1" />
        <counter type="LINE" missed="1" covered="1" />
        <counter type="METHOD" missed="0" covered="1" />
        <counter type="CLASS" missed="0" covered="1" />
    </package>
    <counter type="INSTRUCTION" missed="1" covered="1" />
    <counter type="LINE" missed="1" covered="1" />
    <counter type="METHOD" missed="0" covered="1" />
    <counter type="CLASS" missed="0" covered="1" />
</report>
"@

        }
        It 'Should merge the coverage reports' {
            $result = Merge-JaCoCoReport -OriginalDocument $mockXmlDocument1 -MergeDocument $mockXmlDocument2

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $mockExpectedOuterXml = @'
<?xml version="1.0" encoding="us-ascii" standalone="no"?><!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <class name="3.0.0\prefix" sourcefilename="prefix.ps1">
            <method name="&lt;script&gt;" desc="()" line="2">
                <counter type="INSTRUCTION" missed="0" covered="3" />
                <counter type="LINE" missed="0" covered="3" />
                <counter type="METHOD" missed="0" covered="1" />
            </method>
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
        </class>
        <sourcefile name="prefix.ps1">
            <line nr="2" mi="0" ci="1" mb="0" cb="0" />
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
            <line nr="5" mi="0" ci="1" mb="0" cb="0" />
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
            <line nr="10" mi="0" ci="1" mb="0" cb="0" />
            <line nr="11" mi="1" ci="0" mb="0" cb="0" />
        </sourcefile>
        <counter type="INSTRUCTION" missed="0" covered="3" />
        <counter type="LINE" missed="0" covered="3" />
        <counter type="METHOD" missed="0" covered="1" />
        <counter type="CLASS" missed="0" covered="1" />
    </package>
    <counter type="INSTRUCTION" missed="0" covered="3" />
    <counter type="LINE" missed="0" covered="3" />
    <counter type="METHOD" missed="0" covered="1" />
    <counter type="CLASS" missed="0" covered="1" />
</report>
'@
            $result.OuterXml | Should -Be (($mockExpectedOuterXml -replace '\r?\n')  -replace '>\s*<', '><')
        }
    }
}
