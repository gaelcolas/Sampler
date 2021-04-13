$ProjectPathToTest = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectNameToTest = ((Get-ChildItem -Path $ProjectPathToTest\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName

Import-Module $ProjectNameToTest

Describe 'Set-TaskScriptVariables' {
    BeforeAll {
        # Mock InvokeBuild variable $BuildRoot.
        InModuleScope $ProjectNameToTest {
            $script:BuildRoot = 'C:\source\MyProject'

            $mockProjectName = 'MyProject'
            $mockSourcePath = 'C:\source\MyProject\source'
        }

        Mock -CommandName Get-SamplerProjectName -MockWith {
            return $mockProjectName
        } -ModuleName $ProjectNameToTest

        Mock -CommandName Get-SamplerSourcePath -MockWith {
            return $mockSourcePath
        } -ModuleName $ProjectNameToTest

        # Mock -CommandName Get-SamplerAbsolutePath -MockWith {
        #     return ''
        # } -ModuleName $ProjectName

        Mock -CommandName Get-SamplerAbsolutePath -MockWith {
            return 'C:\source\MyProject\source\MyProject.psd1'
        } -ParameterFilter {
            $Path -eq "$mockProjectName.psd1"
        } -ModuleName $ProjectNameToTest


        Mock -CommandName Get-BuildVersion -MockWith {
            return ''
        } -ModuleName $ProjectNameToTest
    }

    Context 'When calling the function with parameter IsBuild' {
        It 'Should return the expected output' {
            $result = Set-TaskScriptVariables -IsBuild

            $result | Should -Contain "`tProject Name               = '$mockProjectName'"
            $result | Should -Contain "`tSource Path                = '$mockSourcePath'"
        }
    }
}
