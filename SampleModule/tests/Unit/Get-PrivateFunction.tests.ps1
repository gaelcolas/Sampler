$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here/../../*/$sut" #for files in Public\Private folders, called from the tests folder

Describe 'Get-PrivateFunction' {
    Context 'Basic Use case' {
        It 'Runs without Errors' {
            {Get-PrivateFunction -PrivateData 'This is a test'} | Should Not Throw
        }

        It 'Returns expected result' {
            $TestInput = 'This is a test'
            Get-PrivateFunction -PrivateData $TestInput | Should Be $TestInput
        }
    }
}