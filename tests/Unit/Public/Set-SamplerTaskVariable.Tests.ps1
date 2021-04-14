$ProjectPathToTest = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectNameToTest = ((Get-ChildItem -Path $ProjectPathToTest\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName

Import-Module $ProjectNameToTest

Describe 'Set-SamplerTaskVariable' {
    BeforeAll {
        # $previousProjectName = InModuleScope $ProjectNameToTest {
        #     # Remove parent scope's value.
        #     $ProjectName
        # }

        InModuleScope $ProjectNameToTest {
            # Mock InvokeBuild variable $BuildRoot.
            $script:BuildRoot = 'C:\source\MyProject'

            # Remove parent scope's value.
            $script:ProjectName = $null
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

    # AfterAll {
    #     InModuleScope $ProjectNameToTest {
    #         # Remove parent scope's value.
    #         $script:ProjectName = $previousProjectName
    #     }
    # }

    Context 'When calling the function with parameter AsNewBuild' {
        It 'Should return the expected output' {
            <#
                Since Sampler dot-sources the functions into the session we must point
                out that the function to test is the one in the module.
            #>
            $result = Sampler\Set-SamplerTaskVariable -AsNewBuild

            Write-Verbose ($result | Out-String) -Verbose

            $result | Should -Contain "`tProject Name               = 'MyProject'"
            $result | Should -Contain "`tSource Path                = 'C:\source\MyProject\source'"
        }
    }
}
