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
        }

        Mock -CommandName Get-SamplerProjectName -MockWith {
            return 'MyProject'
        } -ModuleName $ProjectNameToTest

        Mock -CommandName Get-SamplerSourcePath -MockWith {
            return 'C:\source\MyProject\source'
        } -ModuleName $ProjectNameToTest

        Mock -CommandName Get-SamplerAbsolutePath -MockWith {
            return ''
        } -ModuleName $ProjectNameToTest

        Mock -CommandName Get-SamplerAbsolutePath -MockWith {
            return 'C:\source\MyProject\source\MyProject.psd1'
        } -ParameterFilter {
            $Path -eq 'MyProject.psd1'
        } -ModuleName $ProjectNameToTest

        Mock -CommandName Get-BuildVersion -MockWith {
            return ''
        } -ModuleName $ProjectNameToTest
    }

    Context 'When calling the function with parameter IsBuild' {
        It 'Should return the expected output' {
            $result = Set-TaskScriptVariables -IsBuild

            #Write-Verbose ($result | Out-String) -Verbose

            $result | Should -Contain "`tProject Name               = 'MyProject'"
            $result | Should -Contain "`tSource Path                = 'C:\source\MyProject\source'"
        }
    }
}
