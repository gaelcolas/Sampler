$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName

Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe New-SampleModule {
        Context 'invoke plaster with correct parameters for template' {

            BeforeAll {

            }

            $testCases = @(
                # If the templates do not define those parameters, Invoke-Plaster will fail and this test will catch it.
                # The template integration is done separately, hence why we don't need to test it here.
                # We only test that the New-SampleModule parameters & parameter set work with the template we have defined.
                @{
                    TestCaseName = 'CompleteSample_NoLicense'
                    NewSampleModuleParams = @{
                        DestinationPath = $TestDrive
                        ModuleName      = 'MyModule'
                        ModuleVersion   = '0.0.1'
                        ModuleAuthor    = "test user"
                        LicenseType     = 'None'
                        ModuleType      = 'CompleteSample'
                    }
                }

                @{
                    TestCaseName = 'SimpleModule_MIT'
                    NewSampleModuleParams = @{
                        DestinationPath = $TestDrive
                        ModuleName      = 'MyModule'
                        ModuleVersion   = '0.0.1'
                        ModuleAuthor    = "test user"
                        LicenseType     = 'MIT'
                        ModuleType      = 'SimpleModule'
                    }
                }
            )

            mock Invoke-Plaster -mockWith {} -Verifiable -ModuleName Sampler

            It 'New-Sample module should call Invoke-Plaster with test case <TestCaseName>' -TestCases $testCases {
                param
                (
                    $TestCaseName,
                    $NewSampleModuleParams
                )

               { New-SampleModule @NewSampleModuleParams  } | Should -Not -Throw
               Assert-MockCalled -CommandName Invoke-Plaster -Scope It -Times 1
            }
        }
    }
}
