$here = $PSScriptRoot
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

$modulePath = "$here\..\..\.." | Convert-Path
if (!$ProjectName) {
    $ProjectName = $(
        try {
            (Split-Path (git config --get remote.origin.url) -Leaf) -replace '\.git'
        }
        catch {
            Split-Path -Path $modulePath -Leaf
        }
    )
}
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
