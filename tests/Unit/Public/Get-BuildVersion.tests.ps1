BeforeAll {
    $script:moduleName = 'Sampler'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 2)
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
                Mock -CommandName Get-Command
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
                    }
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
                    }
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
                }

                InModuleScope -ScriptBlock {
                    # Stub for gitversion.exe so we can mock the result.
                    function script:gitversion
                    {
                        throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
                    }
                }
            }

            AfterAll {
                InModuleScope -ScriptBlock {
                    Remove-Item -Path 'function:gitversion' -Force
                }
            }

            Context 'When passing a module version' {
                BeforeAll {
                    Mock -CommandName gitversion -MockWith {
                        return '{"NuGetVersionV2": "2.1.3"}'
                    }
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
                    }
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
                Mock -CommandName Get-Command
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
                    }
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
                    }
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
                }

                InModuleScope -ScriptBlock {
                    # Stub for gitversion.exe so we can mock the result.
                    function script:gitversion
                    {
                        throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
                    }
                }
            }

            AfterAll {
                InModuleScope -ScriptBlock {
                    Remove-Item -Path 'function:gitversion' -Force
                }
            }

            Context 'When passing a module version' {
                BeforeAll {
                    Mock -CommandName gitversion -MockWith {
                        return '{"NuGetVersionV2": "2.1.3"}'
                    }
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
                    }
                }

                It 'Should return the correct module version' {
                    $result = Sampler\Get-BuildVersion -ModuleManifestPath $TestDrive

                    $result | Should -Be '2.1.3-preview0023'
                }
            }
        }
    }

    Context 'When no value is passed for parameter -ModuleManifestPath' {
        BeforeAll {
            Mock -CommandName Get-Command -MockWith {
                return $false
            }
        }

        Context 'When $null value is passed for parameter ModuleManifestPath' {
            It 'Should throw the correct error' {
                $mockErrorMessage = "Could not determine the module version because neither GitVersion or a module manifest was present. Please provide the ModuleVersion parameter manually in the file build.yaml with the property 'SemVer:'."

                { Sampler\Get-BuildVersion -ModuleManifestPath $null } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        Context 'When empty value is passed for parameter ModuleManifestPath' {
            It 'Should throw the correct error' {
                $mockErrorMessage = "Could not determine the module version because neither GitVersion or a module manifest was present. Please provide the ModuleVersion parameter manually in the file build.yaml with the property 'SemVer:'."

                { Sampler\Get-BuildVersion -ModuleManifestPath '' } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }
}
