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

Describe 'Get-SamplerProjectModuleManifest' {
    Context 'When returning the projects module manifest' {
        Context 'When no module manifest is found' {
            BeforeAll {
                New-Item -Path (Join-Path -Path $TestDrive -ChildPath 'MyModule') -ItemType Directory
            }

            AfterAll {
                Remove-Item -Path (Join-Path -Path $TestDrive -ChildPath 'MyModule') -Recurse -Force
            }

            It 'Should not return a module manifest' {
                InModuleScope -ScriptBlock {
                    $result = Get-SamplerProjectModuleManifest -BuildRoot (Join-Path -Path $TestDrive -ChildPath 'MyModule')

                    $result.FullName | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When the source folder is named ''source''' {
            BeforeAll {
                New-Item -Path (Join-Path -Path $TestDrive -ChildPath 'MyModule/source') -ItemType Directory
                New-Item -Path (Join-Path -Path $TestDrive -ChildPath 'MyModule/source/MyModule.psd1') -ItemType File

                Mock -CommandName Test-ModuleManifest -MockWith {
                    return @{
                        Version = '1.0.0'
                    }
                }
            }

            AfterAll {
                Remove-Item -Path (Join-Path -Path $TestDrive -ChildPath 'MyModule') -Recurse -Force
            }

            It 'Should return the correct module manifest' {
                InModuleScope -ScriptBlock {
                    $result = Get-SamplerProjectModuleManifest -BuildRoot (Join-Path -Path $TestDrive -ChildPath 'MyModule')

                    $result.FullName | Should -Be (Join-Path -Path $TestDrive -ChildPath 'MyModule/source/MyModule.psd1')
                }
            }
        }

        Context 'When the source folder is named ''src''' {
            BeforeAll {
                New-Item -Path (Join-Path -Path $TestDrive -ChildPath 'MyModule/src') -ItemType Directory
                New-Item -Path (Join-Path -Path $TestDrive -ChildPath 'MyModule/src/MyModule.psd1') -ItemType File

                Mock -CommandName Test-ModuleManifest -MockWith {
                    return @{
                        Version = '1.0.0'
                    }
                }
            }

            AfterAll {
                Remove-Item -Path (Join-Path -Path $TestDrive -ChildPath 'MyModule') -Recurse -Force
            }

            It 'Should return the correct module manifest' {
                InModuleScope -ScriptBlock {
                    $result = Get-SamplerProjectModuleManifest -BuildRoot (Join-Path -Path $TestDrive -ChildPath 'MyModule')

                    $result.FullName | Should -Be (Join-Path -Path $TestDrive -ChildPath 'MyModule/src/MyModule.psd1')
                }
            }
        }

        Context 'When the source folder is named as the module name, ''MyModule''' {
            BeforeAll {
                New-Item -Path (Join-Path -Path $TestDrive -ChildPath 'MyModule/MyModule') -ItemType Directory
                New-Item -Path (Join-Path -Path $TestDrive -ChildPath 'MyModule/MyModule/MyModule.psd1') -ItemType File

                Mock -CommandName Test-ModuleManifest -MockWith {
                    return @{
                        Version = '1.0.0'
                    }
                }
            }

            AfterAll {
                Remove-Item -Path (Join-Path -Path $TestDrive -ChildPath 'MyModule') -Recurse -Force
            }

            It 'Should return the correct module manifest' {
                InModuleScope -ScriptBlock {
                    $result = Get-SamplerProjectModuleManifest -BuildRoot (Join-Path -Path $TestDrive -ChildPath 'MyModule')

                    $result.FullName | Should -Be (Join-Path -Path $TestDrive -ChildPath 'MyModule/MyModule/MyModule.psd1')
                }
            }
        }

        Context 'When the module manifest does not contain the property Version' {
            BeforeAll {
                New-Item -Path (Join-Path -Path $TestDrive -ChildPath 'MyModule/source') -ItemType Directory
                New-Item -Path (Join-Path -Path $TestDrive -ChildPath 'MyModule/source/MyModule.psd1') -ItemType File

                Mock -CommandName Test-ModuleManifest -MockWith {
                    return @{}
                }
            }

            AfterAll {
                Remove-Item -Path (Join-Path -Path $TestDrive -ChildPath 'MyModule') -Recurse -Force
            }

            It 'Should not return a module manifest' {
                InModuleScope -ScriptBlock {
                    $result = Get-SamplerProjectModuleManifest -BuildRoot (Join-Path -Path $TestDrive -ChildPath 'MyModule')

                    $result.FullName | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When the module manifest contains two .psd1 files but excludes one' {
            Context 'When excluding file <MockFileName>' -ForEach @(
                @{
                    MockFileName = 'build.psd1'
                }
                @{
                    MockFileName = 'analyzersettings.psd1'
                }
            ) {
                BeforeAll {
                    New-Item -Path (Join-Path -Path $TestDrive -ChildPath 'MyModule/source') -ItemType Directory
                    New-Item -Path (Join-Path -Path $TestDrive -ChildPath 'MyModule/source/MyModule.psd1') -ItemType File

                    Mock -CommandName Test-ModuleManifest -MockWith {
                        return @{
                            Version = '1.0.0'
                        }
                    }
                }

                AfterAll {
                    Remove-Item -Path (Join-Path -Path $TestDrive -ChildPath 'MyModule') -Recurse -Force
                }

                It 'Should return the correct module manifest' {
                    InModuleScope -ScriptBlock {
                        $result = Get-SamplerProjectModuleManifest -BuildRoot (Join-Path -Path $TestDrive -ChildPath 'MyModule')

                        $result.FullName | Should -Be (Join-Path -Path $TestDrive -ChildPath 'MyModule/source/MyModule.psd1')
                    }
                }
            }
        }

        Context 'When there are more than one .psd1 file' {
            BeforeAll {
                New-Item -Path (Join-Path -Path $TestDrive -ChildPath 'MyModule/source') -ItemType Directory
                New-Item -Path (Join-Path -Path $TestDrive -ChildPath 'MyModule/source/MyModule.psd1') -ItemType File
                New-Item -Path (Join-Path -Path $TestDrive -ChildPath 'MyModule/source/MyModule2.psd1') -ItemType File

                Mock -CommandName Test-ModuleManifest -MockWith {
                    return @{
                        Version = '1.0.0'
                    }
                }
            }

            AfterAll {
                Remove-Item -Path (Join-Path -Path $TestDrive -ChildPath 'MyModule') -Recurse -Force
            }

            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    { Get-SamplerProjectModuleManifest -BuildRoot (Join-Path -Path $TestDrive -ChildPath 'MyModule') } |
                        Should -Throw -ExpectedMessage 'Found more than one project folder containing a module manifest, please make sure there are only one;*'
                }
            }
        }
    }
}
