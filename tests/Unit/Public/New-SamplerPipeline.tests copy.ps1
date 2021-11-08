$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName

Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe New-SamplerPipeline {
        Context 'invoke plaster with correct parameters for template' {

            BeforeAll {

            }

            $testCases = @(
                # If the templates do not define those parameters, Invoke-Plaster will fail and this test will catch it.
                # The template integration is done separately, hence why we don't need to test it here.
                # We only test that the Add-Sample parameters & parameter set work with the templates we have defined.
                @{
                    TestCaseName = 'classes'
                    AddSampleParams = @{
                        Sample          = 'Classes'
                        DestinationPath = $TestDrive
                        SourceDirectory = 'Source'
                    }
                }

                @{
                    TestCaseName = 'ClassResource'
                    AddSampleParams = @{
                        Sample          = 'ClassResource'
                        DestinationPath = $TestDrive
                        ResourceName    = 'MyResource'
                        SourceDirectory = 'source'
                    }
                }

                @{
                    TestCaseName = 'Examples'
                    AddSampleParams = @{
                        Sample          = 'Examples'
                        DestinationPath = $TestDrive
                    }
                }

            )

            mock Invoke-Plaster -mockWith {} -Verifiable -ModuleName Sampler

            It 'New-Sample module should call Invoke-Plaster with test case <TestCaseName>' -TestCases $testCases {
                param
                (
                    $TestCaseName,
                    $AddSampleParams
                )

               { Sampler\Add-Sample @AddSampleParams  } | Should -Not -Throw

               Assert-MockCalled -CommandName Invoke-Plaster -Scope It -Times 1
            }
        }
    }
}
