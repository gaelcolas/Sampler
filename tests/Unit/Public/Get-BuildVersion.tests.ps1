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

Describe 'Get-BuildVersion' {
    Context 'When a value for parameter ModuleVersion is passed' {
        Context 'When passing a module version' {
            It 'Should return the correct module version' {
                $result = Sampler\Get-BuildVersion -ModuleManifestPath $TestDrive -ModuleVersion '2.1.3'

                $result | Should -Be '2.1.3'
            }
        }

        Context 'When passing a preview module version' {
            It 'Should return the correct module version' {
                $result = Sampler\Get-BuildVersion -ModuleManifestPath $TestDrive -ModuleVersion '2.1.3-preview0023'

                $result | Should -Be '2.1.3-preview0023'
            }
        }
    }

    Context 'When an empty string is passed as value for parameter ModuleVersion' {
        Context 'When gitversion is not available' {
            BeforeAll {
                Mock -CommandName Get-Command -ModuleName $ProjectName
            }

            Context 'When passing a module version' {
                BeforeAll {
                    Mock -CommandName Import-PowerShellDataFile -MockWith {
                        return @{
                            ModuleVersion = '2.1.3'
                            PrivateData = @{
                                PSData = @{
                                    Prerelease = ''
                                }
                            }
                        }
                    } -ModuleName $ProjectName
                }

                It 'Should return the correct module version' {
                    $result = Sampler\Get-BuildVersion -ModuleManifestPath $TestDrive -ModuleVersion ''

                    $result | Should -Be '2.1.3'
                }
            }

            Context 'When passing a preview module version' {
                BeforeAll {
                    Mock -CommandName Import-PowerShellDataFile -MockWith {
                        return @{
                            ModuleVersion = '2.1.3'
                            PrivateData = @{
                                PSData = @{
                                    Prerelease = 'preview0023'
                                }
                            }
                        }
                    } -ModuleName $ProjectName
                }

                It 'Should return the correct module version' {
                    $result = Sampler\Get-BuildVersion -ModuleManifestPath $TestDrive -ModuleVersion ''

                    $result | Should -Be '2.1.3-preview0023'
                }
            }
        }

        Context 'When gitversion is available' {
            BeforeAll {
                Mock -CommandName Get-Command -MockWith {
                    return $true
                } -ModuleName $ProjectName

                # Stub for gitversion.exe so we can mock the result.
                function gitversion
                {
                    throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
                }
            }

            AfterAll {
                Remove-Item -Path 'function:gitversion' -Force
            }

            Context 'When passing a module version' {
                BeforeAll {
                    Mock -CommandName gitversion -MockWith {
                        return '{"NuGetVersionV2": "2.1.3"}'
                    } -ModuleName $ProjectName
                }

                It 'Should return the correct module version' {
                    $result = Sampler\Get-BuildVersion -ModuleManifestPath $TestDrive -ModuleVersion ''

                    $result | Should -Be '2.1.3'
                }
            }

            Context 'When passing a preview module version' {
                BeforeAll {
                    Mock -CommandName gitversion -MockWith {
                        return '{"NuGetVersionV2": "2.1.3-preview0023"}'
                    } -ModuleName $ProjectName
                }

                It 'Should return the correct module version' {
                    $result = Sampler\Get-BuildVersion -ModuleManifestPath $TestDrive -ModuleVersion ''

                    $result | Should -Be '2.1.3-preview0023'
                }
            }
        }
    }

    Context 'When no value is passed for parameter ModuleVersion' {
        Context 'When gitversion is not available' {
            BeforeAll {
                Mock -CommandName Get-Command -ModuleName $ProjectName
            }

            Context 'When passing a module version' {
                BeforeAll {
                    Mock -CommandName Import-PowerShellDataFile -MockWith {
                        return @{
                            ModuleVersion = '2.1.3'
                            PrivateData = @{
                                PSData = @{
                                    Prerelease = ''
                                }
                            }
                        }
                    } -ModuleName $ProjectName
                }

                It 'Should return the correct module version' {
                    $result = Sampler\Get-BuildVersion -ModuleManifestPath $TestDrive

                    $result | Should -Be '2.1.3'
                }
            }

            Context 'When passing a preview module version' {
                BeforeAll {
                    Mock -CommandName Import-PowerShellDataFile -MockWith {
                        return @{
                            ModuleVersion = '2.1.3'
                            PrivateData = @{
                                PSData = @{
                                    Prerelease = 'preview0023'
                                }
                            }
                        }
                    } -ModuleName $ProjectName
                }

                It 'Should return the correct module version' {
                    $result = Sampler\Get-BuildVersion -ModuleManifestPath $TestDrive

                    $result | Should -Be '2.1.3-preview0023'
                }
            }
        }

        Context 'When gitversion is available' {
            BeforeAll {
                Mock -CommandName Get-Command -MockWith {
                    return $true
                } -ModuleName $ProjectName

                # Stub for gitversion.exe so we can mock the result.
                function gitversion
                {
                    throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
                }
            }

            AfterAll {
                Remove-Item -Path 'function:gitversion' -Force
            }

            Context 'When passing a module version' {
                BeforeAll {
                    Mock -CommandName gitversion -MockWith {
                        return '{"NuGetVersionV2": "2.1.3"}'
                    } -ModuleName $ProjectName
                }

                It 'Should return the correct module version' {
                    $result = Sampler\Get-BuildVersion -ModuleManifestPath $TestDrive

                    $result | Should -Be '2.1.3'
                }
            }

            Context 'When passing a preview module version' {
                BeforeAll {
                    Mock -CommandName gitversion -MockWith {
                        return '{"NuGetVersionV2": "2.1.3-preview0023"}'
                    } -ModuleName $ProjectName
                }

                It 'Should return the correct module version' {
                    $result = Sampler\Get-BuildVersion -ModuleManifestPath $TestDrive

                    $result | Should -Be '2.1.3-preview0023'
                }
            }
        }
    }
}
