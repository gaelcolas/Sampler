$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here/../../*/$sut" #for files in Public\Private folders, called from the tests folder

function Get-PrivateFunction {Param($PrivateData) }

Describe 'Get-Something' {
    Mock Get-PrivateFunction -MockWith {$PrivateData} -Verifiable #Return untransformed Data

    Context 'Basic Use case' {
        It 'Runs without Errors' {
            {Get-Something -Data 'This is a test'} | Should Not Throw
        }

        It 'Returns expected result' {
            $TestInput = 'This is a test'
            Get-Something -Data $TestInput | Should Be $TestInput
        }

        It 'Should call Get-PrivateFunction private module function' {
            Assert-MockCalled Get-PrivateFunction
        }
    }
}