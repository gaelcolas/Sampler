$here = $PSScriptRoot
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

$ProjectPath = "$here\..\..\.." | Convert-Path
$ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        ($moduleManifest = Test-ModuleManifest $_.FullName -ErrorAction SilentlyContinue) }
    ).BaseName

Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe Get-PrivateFunction {
        Context 'Default' {
            BeforeEach {
                $return = Get-PrivateFunction -PrivateData 'string'
            }

            It 'Returns a single object' {
                ($return | Measure-Object).Count | Should -Be 1
            }

            It 'Returns a string based on the parameter PrivateData' {
                $return | Should -Be 'string'
            }
        }
    }
}
