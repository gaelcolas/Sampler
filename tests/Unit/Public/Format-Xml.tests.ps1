$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            {
                Test-ModuleManifest $_.FullName -ErrorAction Stop
            }
            catch
            {
                $false
            } )
    }).BaseName

Import-Module $ProjectName

Describe 'Format-Xml' {
    BeforeAll {
        $mockXmlDocument = '<?xml version="1.0" encoding="utf-16" standalone="no"?><a><b /></a>'
    }

    It 'Should format the XML without indentation' {
        $result = Sampler\Format-Xml -XmlDocument $mockXmlDocument

        $result | Should -Be $mockXmlDocument
    }

    It 'Should format the XML with indentation' {
        $result = Sampler\Format-Xml -XmlDocument $mockXmlDocument -Indented

        $mockExpectedResult = @"
<?xml version="1.0" encoding="utf-16" standalone="no"?>
<a>
  <b />
</a>
"@
        ($result -replace '\r?\n', "`n") | Should -Be ($mockExpectedResult -replace '\r?\n', "`n")
    }
}
