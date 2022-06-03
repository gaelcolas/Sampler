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

Describe 'Get-SamplerSourcePath' {
    Context 'When no module source path is found' {
        BeforeAll {
            Mock -CommandName Get-SamplerProjectModuleManifest
        }

        It 'Should throw the correct error message' {
            { Get-SamplerSourcePath -BuildRoot $TestDrive } | Should -Throw -ExpectedMessage 'Module Source Path not found.'
        }
    }

    Context 'When source path is ''src'' and module manifest is not found' {
        BeforeAll {
            Mock -CommandName Get-SamplerProjectModuleManifest
            Mock -CommandName Write-Debug
            Mock -CommandName Test-Path -MockWith {
                return $false
            }

            Mock -CommandName Test-Path -MockWith {
                return $true
            } -ParameterFilter {
                $Path -match 'src'
            }
        }

        It 'Should return the correct path' {
            $result = Get-SamplerSourcePath -BuildRoot $TestDrive

            $result | Should -Be (Join-Path -Path $TestDrive -ChildPath 'src')
        }
    }

    Context 'When source path is ''source'' and module manifest is not found' {
        BeforeAll {
            Mock -CommandName Get-SamplerProjectModuleManifest
            Mock -CommandName Write-Debug
            Mock -CommandName Test-Path -MockWith {
                return $false
            }

            Mock -CommandName Test-Path -MockWith {
                return $true
            } -ParameterFilter {
                $Path -match 'source'
            }
        }

        It 'Should return the correct path' {
            $result = Get-SamplerSourcePath -BuildRoot $TestDrive

            $result | Should -Be (Join-Path -Path $TestDrive -ChildPath 'source')
        }
    }

    Context 'When source path is ''src'' and module manifest is found' {
        BeforeAll {
            Mock -CommandName Get-SamplerProjectModuleManifest -MockWith {
                return @{
                    Directory = @{
                        FullName = Join-Path -Path $TestDrive -ChildPath (Join-Path -Path 'src' -ChildPath 'MyModule.psd1')
                    }
                }
            }
        }

        It 'Should return the correct path' {
            $result = Get-SamplerSourcePath -BuildRoot $TestDrive

            $result | Should -Be (Join-Path -Path $TestDrive -ChildPath (Join-Path -Path 'src' -ChildPath 'MyModule.psd1'))
        }
    }

    Context 'When source path is ''source'' and module manifest is found' {
        BeforeAll {
            Mock -CommandName Get-SamplerProjectModuleManifest -MockWith {
                return @{
                    Directory = @{
                        FullName = Join-Path -Path $TestDrive -ChildPath (Join-Path -Path 'source' -ChildPath 'MyModule.psd1')
                    }
                }
            }
        }

        It 'Should return the correct path' {
            $result = Get-SamplerSourcePath -BuildRoot $TestDrive

            $result | Should -Be (Join-Path -Path $TestDrive -ChildPath (Join-Path -Path 'source' -ChildPath 'MyModule.psd1'))
        }
    }
}
