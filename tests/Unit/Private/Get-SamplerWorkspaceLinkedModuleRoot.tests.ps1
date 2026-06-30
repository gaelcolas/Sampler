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
                $result = Get-SamplerWorkspaceLinkedModuleRoot `
                    -BuildRoot 'C:\src\MyRepo' `
                    -OutputDirectory 'C:\src\MyRepo\output' `
                    -BuiltModuleSubdirectory 'module'

                $result | Should -Be (Join-Path -Path 'C:\src\MyRepo\output' -ChildPath 'module')
            }
        }
    }

    Context 'When OutputDirectory is relative' {
        It 'Should join OutputDirectory with BuildRoot before appending BuiltModuleSubdirectory' {
            InModuleScope -ScriptBlock {
                $result = Get-SamplerWorkspaceLinkedModuleRoot `
                    -BuildRoot 'C:\src\MyRepo' `
                    -OutputDirectory 'output' `
                    -BuiltModuleSubdirectory 'module'

                $expectedOutputRoot = Join-Path -Path 'C:\src\MyRepo' -ChildPath 'output'
                $result | Should -Be (Join-Path -Path $expectedOutputRoot -ChildPath 'module')
            }
        }
    }

    Context 'When BuiltModuleSubdirectory is empty' {
        It 'Should return the output root without any subdirectory appended' {
            InModuleScope -ScriptBlock {
                $result = Get-SamplerWorkspaceLinkedModuleRoot `
                    -BuildRoot 'C:\src\MyRepo' `
                    -OutputDirectory 'C:\src\MyRepo\output' `
                    -BuiltModuleSubdirectory ''

                $result | Should -Be 'C:\src\MyRepo\output'
            }
        }
    }

    Context 'When BuiltModuleSubdirectory is absolute' {
        It 'Should return the absolute BuiltModuleSubdirectory path directly' {
            InModuleScope -ScriptBlock {
                $result = Get-SamplerWorkspaceLinkedModuleRoot `
                    -BuildRoot 'C:\src\MyRepo' `
                    -OutputDirectory 'C:\src\MyRepo\output' `
                    -BuiltModuleSubdirectory 'C:\custom\moduleroot'

                $result | Should -Be 'C:\custom\moduleroot'
            }
        }
    }
}
