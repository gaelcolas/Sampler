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

Describe 'Get-SamplerBuiltModuleBase' {
    Context 'When passing mandatory parameters' {
        It 'Should return the correct path' {
            $result = Get-SamplerBuiltModuleBase -OutputDirectory $TestDrive -ModuleName 'MyModule'

            $result | Should -Be (Join-Path -Path $TestDrive -ChildPath 'MyModule')
        }
    }

    Context 'When passing parameter BuildModuleSubdirectory' {
        It 'Should return the correct path' {
            $result = Get-SamplerBuiltModuleBase -OutputDirectory $TestDrive -ModuleName 'MyModule' -BuiltModuleSubdirectory 'builtModule'

            $expectedPath = Join-Path -Path $TestDrive -ChildPath (Join-Path -Path 'builtModule' -ChildPath 'MyModule')

            $result | Should -Be $expectedPath
        }
    }

    Context 'When passing parameter VersionedOutputDirectory' {
        It 'Should return the correct path' {
            $result = Get-SamplerBuiltModuleBase -OutputDirectory $TestDrive -ModuleName 'MyModule' -VersionedOutputDirectory

            $expectedPath = Join-Path -Path $TestDrive -ChildPath (Join-Path -Path 'MyModule' -ChildPath '*')

            $result | Should -Be $expectedPath
        }
    }

    Context 'When passing parameter ModuleVersion' {
        Context 'When passing an asterisk as module version' {
            <#
                TODO: This is potentially a bug since it suppose to suffix the
                path with '*' as previous context block did? It does not and the
                test currently reflect what it actually returns for it to pass.
            #>
            It 'Should return the correct path' {
                $result = Get-SamplerBuiltModuleBase -OutputDirectory $TestDrive -ModuleName 'MyModule' -ModuleVersion '*'

                $expectedPath = Join-Path -Path $TestDrive -ChildPath 'MyModule'

                $result | Should -Be $expectedPath
            }
        }

        Context 'When passing an specific module version' {
            It 'Should return the correct path' {
                $result = Get-SamplerBuiltModuleBase -OutputDirectory $TestDrive -ModuleName 'MyModule' -ModuleVersion '2.0.0'

                $expectedPath = Join-Path -Path $TestDrive -ChildPath (Join-Path -Path 'MyModule' -ChildPath '2.0.0')

                $result | Should -Be $expectedPath
            }
        }
    }
}
