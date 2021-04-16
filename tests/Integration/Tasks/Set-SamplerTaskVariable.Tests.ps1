$ProjectPathToTest = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectNameToTest = ((Get-ChildItem -Path $ProjectPathToTest\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName

Import-Module $ProjectNameToTest

<#
    This test need to change the variable names that are used in the pipeline to
    properly mock the code being tested.
    The current values are saved and set back at the end of the test.
#>

Describe 'Set-SamplerTaskVariable' {
    BeforeAll {
        # Remember the correct values for the pipeline.
        $previousBuildRoot = $BuildRoot
        $previousProjectName = $ProjectName
        $previousSourcePath = $SourcePath

        # Mock InvokeBuild variable $BuildRoot.
        $BuildRoot = Join-Path -Path $TestDrive -ChildPath 'MyProject'

        # Remove parent scope's value.
        $ProjectName = $null
        $SourcePath = $null

        Mock -CommandName Get-SamplerProjectName -MockWith {
            return 'MyProject'
        }

        Mock -CommandName Get-SamplerSourcePath -MockWith {
            return (Join-Path -Path $TestDrive -ChildPath 'MyProject/source')
        }

        Mock -CommandName Get-SamplerAbsolutePath -MockWith {
            return ''
        }

        Mock -CommandName Get-SamplerAbsolutePath -MockWith {
            return (Join-Path -Path $TestDrive -ChildPath 'MyProject\source\MyProject.psd1')
        } -ParameterFilter {
            $Path -eq 'MyProject.psd1'
        }

        Mock -CommandName Get-BuildVersion -MockWith {
            return ''
        }
    }

    AfterAll {
        # Return the correct values that the pipeline expects.
        $BuildRoot = $previousBuildRoot
        $ProjectName = $previousProjectName
        $SourcePath = $previousSourcePath
    }

    Context 'When calling the function with parameter AsNewBuild' {
        It 'Should return the expected output' {
            <#
                Since Sampler adds its own alias in build.ps1 that does not point
                to the built module's Set-SamplerTaskVariable we must point
                out that the alias to test is the one in the module.
            #>
            $result = . Sampler\Set-SamplerTaskVariable -AsNewBuild

            Write-Verbose ($result | Out-String) -Verbose

            $result | Should -Contain "`tProject Name               = 'MyProject'"
            $result | Should -Contain ("`tSource Path                = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/source'))
        }
    }
}
