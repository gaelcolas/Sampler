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

Describe 'Get-CodeCoverageThreshold' {
    Context 'When passing an integer value for RuntimeCodeCoverageThreshold' {
        It 'Should return the same value as passed' {
            $result = Sampler\Get-CodeCoverageThreshold -RuntimeCodeCoverageThreshold 10

            $result | Should -Be 10
        }
    }

    Context 'When passing a string value for RuntimeCodeCoverageThreshold' {
        It 'Should return the same value as passed' {
            $result = Sampler\Get-CodeCoverageThreshold -RuntimeCodeCoverageThreshold '21'

            $result | Should -Be 21
        }
    }

    Context 'When RuntimeCodeCoverageThreshold is $null' {
        Context 'When there is no build configuration value' {
            It 'Should return 0' {
                $result = Sampler\Get-CodeCoverageThreshold -RuntimeCodeCoverageThreshold $null

                $result | Should -Be 0
            }
        }

        Context 'When using deprecated Pester build configuration value' {
            It 'Should return the configured value' {
                $result = Sampler\Get-CodeCoverageThreshold -RuntimeCodeCoverageThreshold $null -BuildInfo @{
                    Pester = @{
                        CodeCoverageThreshold = 30
                    }
                }

                $result | Should -Be 30
            }
        }

        Context 'When using advanced Pester build configuration value' {
            It 'Should return the configured value' {
                $result = Sampler\Get-CodeCoverageThreshold -RuntimeCodeCoverageThreshold $null -BuildInfo @{
                    Pester = @{
                        Configuration = @{
                            CodeCoverage = @{
                                CoveragePercentTarget = 40
                            }
                        }
                    }
                }

                $result | Should -Be 40
            }
        }
    }

    Context 'When RuntimeCodeCoverageThreshold is not passed' {
        Context 'When there is no build configuration value' {
            It 'Should return 0' {
                $result = Sampler\Get-CodeCoverageThreshold

                $result | Should -Be 0
            }
        }

        Context 'When using deprecated Pester build configuration value' {
            It 'Should return the configured value' {
                $result = Sampler\Get-CodeCoverageThreshold -BuildInfo @{
                    Pester = @{
                        CodeCoverageThreshold = 30
                    }
                }

                $result | Should -Be 30
            }
        }

        Context 'When using advanced Pester build configuration value' {
            It 'Should return the configured value' {
                $result = Sampler\Get-CodeCoverageThreshold -BuildInfo @{
                    Pester = @{
                        Configuration = @{
                            CodeCoverage = @{
                                CoveragePercentTarget = 40
                            }
                        }
                    }
                }

                $result | Should -Be 40
            }
        }
    }
}
