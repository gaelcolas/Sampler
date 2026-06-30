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

Describe 'Get-SamplerWorkspaceLinkedModuleRoot' {
    Context 'When OutputDirectory is absolute and BuiltModuleSubdirectory is provided' {
        It 'Should return the joined absolute output and subdirectory path' {
            InModuleScope -ScriptBlock {
                $buildRoot  = $TestDrive
                $absOutput  = Join-Path -Path $TestDrive -ChildPath 'output'

                $result = Get-SamplerWorkspaceLinkedModuleRoot `
                    -BuildRoot $buildRoot `
                    -OutputDirectory $absOutput `
                    -BuiltModuleSubdirectory 'module'

                $result | Should -Be (Join-Path -Path $absOutput -ChildPath 'module')
            }
        }
    }

    Context 'When OutputDirectory is relative' {
        It 'Should join OutputDirectory with BuildRoot before appending BuiltModuleSubdirectory' {
            InModuleScope -ScriptBlock {
                $buildRoot = $TestDrive

                $result = Get-SamplerWorkspaceLinkedModuleRoot `
                    -BuildRoot $buildRoot `
                    -OutputDirectory 'output' `
                    -BuiltModuleSubdirectory 'module'

                $expectedOutputRoot = Join-Path -Path $buildRoot -ChildPath 'output'
                $result | Should -Be (Join-Path -Path $expectedOutputRoot -ChildPath 'module')
            }
        }
    }

    Context 'When BuiltModuleSubdirectory is empty' {
        It 'Should return the output root without any subdirectory appended' {
            InModuleScope -ScriptBlock {
                $absOutput = Join-Path -Path $TestDrive -ChildPath 'output'

                $result = Get-SamplerWorkspaceLinkedModuleRoot `
                    -BuildRoot $TestDrive `
                    -OutputDirectory $absOutput `
                    -BuiltModuleSubdirectory ''

                $result | Should -Be $absOutput
            }
        }
    }

    Context 'When BuiltModuleSubdirectory is absolute' {
        It 'Should return the absolute BuiltModuleSubdirectory path directly' {
            InModuleScope -ScriptBlock {
                $absSubDir = Join-Path -Path $TestDrive -ChildPath 'custom-moduleroot'

                $result = Get-SamplerWorkspaceLinkedModuleRoot `
                    -BuildRoot $TestDrive `
                    -OutputDirectory (Join-Path -Path $TestDrive -ChildPath 'output') `
                    -BuiltModuleSubdirectory $absSubDir

                $result | Should -Be $absSubDir
            }
        }
    }
}
