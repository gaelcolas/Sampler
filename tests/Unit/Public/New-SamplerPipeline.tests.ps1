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
                    TestCaseName = 'Build'
                    NewSamplerPipelineParams = @{
                        DestinationPath = $TestDrive
                        Pipeline = 'Build'
                        ProjectName =  'MyBuild'
                        License = 'true'
                        LicenseType = 'MIT'
                        SourceDirectory = 'Source'
                        MainGitBranch = 'main'
                        ModuleDescription = 'some desc'
                        CustomRepo = 'PSGallery'
                        Features = 'All'
                    }
                }

                @{
                    TestCaseName = 'ChocolateyPipeline'
                    NewSamplerPipelineParams = @{
                        DestinationPath = $TestDrive
                        Pipeline = 'ChocolateyPipeline'
                        ProjectName =  'MyChoco'
                        License = 'true'
                        LicenseType = 'MIT'
                        SourceDirectory = 'Source'
                        MainGitBranch = 'main'
                        ModuleDescription = 'some desc'
                        CustomRepo = 'PSGallery'
                        Features = 'All'
                    }
                }
            )

            mock Invoke-Plaster -mockWith {} -Verifiable -ModuleName Sampler

            It 'New-SamplerPipeline should call Invoke-Plaster with test case <TestCaseName>' -TestCases $testCases {
                param
                (
                    $TestCaseName,
                    $NewSamplerPipelineParams
                )

               { Sampler\New-SamplerPipeline @NewSamplerPipelineParams  } | Should -Not -Throw

               Assert-MockCalled -CommandName Invoke-Plaster -Scope It -Times 1
            }
        }
    }
}
