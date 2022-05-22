BeforeAll {
    $script:moduleName = 'Sampler'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 3)
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    }

    # Re-import the module using force to get any code changes between runs.
    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Module -Name $script:moduleName
}

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
