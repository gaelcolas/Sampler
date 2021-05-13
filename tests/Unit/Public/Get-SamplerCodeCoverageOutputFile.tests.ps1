$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = (
    (Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(
            try
            {
                Test-ModuleManifest $_.FullName -ErrorAction Stop
            }
            catch
            {
                $false
            }
        )
    }
).BaseName

Import-Module $ProjectName

Describe 'Get-SamplerCodeCoverageOutputFile' {
    Context 'When there is no build configuration value' {
        It 'Should return $null' {
            $result = Sampler\Get-SamplerCodeCoverageOutputFile -PesterOutputFolder $TestDrive -BuildInfo @{}

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When using deprecated Pester build configuration value' {
        BeforeAll {
            $mockAbsolutePath = Join-Path -Path $TestDrive -ChildPath 'JaCoCo_coverage.xml'
        }

        Context 'When passing absolute path' {
            It 'Should return the absolute path' {
                $result = Sampler\Get-SamplerCodeCoverageOutputFile -PesterOutputFolder $TestDrive -BuildInfo @{
                    Pester = @{
                        CodeCoverageOutputFile = $mockAbsolutePath
                    }
                }

                $result | Should -Be $mockAbsolutePath
            }
        }

        Context 'When passing relative path' {
            It 'Should return the configured value' {
                $result = Sampler\Get-SamplerCodeCoverageOutputFile -PesterOutputFolder $TestDrive -BuildInfo @{
                    Pester = @{
                        CodeCoverageOutputFile = 'JaCoCo_coverage.xml'
                    }
                }

                $result | Should -Be $mockAbsolutePath
            }
        }
    }

    Context 'When using advanced Pester build configuration value' {
        BeforeAll {
            $mockAbsolutePath = Join-Path -Path $TestDrive -ChildPath 'JaCoCo_coverage.xml'
        }

        Context 'When passing absolute path' {
            It 'Should return the absolute path' {
                $result = Sampler\Get-SamplerCodeCoverageOutputFile -PesterOutputFolder $TestDrive -BuildInfo @{
                    Pester = @{
                        Configuration = @{
                            CodeCoverage = @{
                                OutputPath = $mockAbsolutePath
                            }
                        }
                    }
                }

                $result | Should -Be $mockAbsolutePath
            }
        }

        Context 'When passing relative path' {
            It 'Should return the configured value' {
                $result = Sampler\Get-SamplerCodeCoverageOutputFile -PesterOutputFolder $TestDrive -BuildInfo @{
                    Pester = @{
                        Configuration = @{
                            CodeCoverage = @{
                                OutputPath = 'JaCoCo_coverage.xml'
                            }
                        }
                    }
                }

                $result | Should -Be $mockAbsolutePath
            }
        }
    }
}
