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
}

AfterAll {
    Remove-Module -Name $script:moduleName
}

Describe 'Clean.ModuleBuilder' {
    It 'Should have exported the alias correct' {
        $taskAlias = Get-Alias -Name 'Clean.ModuleBuilder.build.Sampler.ib.tasks'

        $taskAlias.Name | Should -Be 'Clean.ModuleBuilder.build.Sampler.ib.tasks'
        $taskAlias.ReferencedCommand | Should -Be 'Clean.ModuleBuilder.build.ps1'
        $taskAlias.Definition | Should -Match 'Sampler[\/|\\]\d+\.\d+\.\d+[\/|\\]tasks[\/|\\]Clean\.ModuleBuilder\.build\.ps1'
    }
}

Describe 'Clean' {
    BeforeAll {
        $taskAlias = Get-Alias -Name 'Clean.ModuleBuilder.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'MyModule/output'
        }
    }

    Context 'When creating a preview release tag' {
        BeforeAll {
            Mock -CommandName Get-ChildItem
            Mock -CommandName Remove-Item
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'Clean' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw
        }
    }
}

Describe 'CleanModule' {
    BeforeAll {
        $taskAlias = Get-Alias -Name 'Clean.ModuleBuilder.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'MyModule/output'
        }
    }

    Context 'When creating a preview release tag' {
        BeforeAll {
            Mock -CommandName Get-ChildItem
            Mock -CommandName Remove-Item
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'CleanModule' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw
        }
    }
}

Describe 'CleanAll' {
    BeforeAll {
        $taskAlias = Get-Alias -Name 'Clean.ModuleBuilder.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'MyModule/output'
        }
    }

    Context 'When creating a preview release tag' {
        BeforeAll {
            Mock -CommandName Get-ChildItem
            Mock -CommandName Remove-Item
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'CleanAll' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw
        }
    }
}
