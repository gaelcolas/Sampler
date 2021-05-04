$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName

Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'New-SamplerXmlJaCoCoCounter' {
        BeforeEach {
            $mockXmlDocument = New-Object -TypeName 'System.Xml.XmlDocument'
            $mockElement = $mockXmlDocument.CreateElement('report')
        }

        Context 'When calling without PassThru' {
            It 'Should append the correct element' {
               { New-SamplerXmlJaCoCoCounter -XmlNode $mockElement -CounterType 'LINE' -Covered 2 -Missed 1 } | Should -Not -Throw

               $mockElement.OuterXml | Should -Be '<report><counter type="LINE" missed="1" covered="2" /></report>'
            }
        }

        Context 'When calling with PassThru' {
            It 'Should append the correct element' {
               $result = New-SamplerXmlJaCoCoCounter -XmlNode $mockElement -CounterType 'LINE' -Covered 2 -Missed 1 -PassThru

               $mockElement.OuterXml | Should -Be '<report><counter type="LINE" missed="1" covered="2" /></report>'

               $result.OuterXml | Should -Be '<counter type="LINE" missed="1" covered="2" />'
            }
        }
    }
}
