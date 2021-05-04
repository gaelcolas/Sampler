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

Describe 'Out-SamplerXml' {
    BeforeAll {
        $mockXmlDocument = '<?xml version="1.0" encoding="utf-16" standalone="no"?><a><b /></a>'
    }

    It 'Should write a file with the correct content and correct encoding' {
        $mockPath = Join-Path -Path $TestDrive -ChildPath 'mockOutput.xml'

        $result = Sampler\Out-SamplerXml -XmlDocument $mockXmlDocument -Path $mockPath

        $contentsInFile = Get-Content -Path $mockPath -Raw

        $contentsInFile | Should -Be '<?xml version="1.0" encoding="utf-8" standalone="no"?><a><b /></a>'
    }
}
