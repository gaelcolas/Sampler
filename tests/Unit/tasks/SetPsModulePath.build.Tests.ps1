BeforeAll {
    $script:moduleName = 'Sampler'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 2)
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' > $null
    }

    # Re-import the module using force to get any code changes between runs.
    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'
}

AfterAll {
    Remove-Module -Name $script:moduleName
}

Describe 'SetPsModulePath' -Tag x {

    BeforeAll {
        $taskAlias = Get-Alias -Name 'SetPsModulePath.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            #OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'MyModule/output'
        }
    }

    It 'Should have exported the alias correct' {

        $taskAlias.Name | Should -Be 'SetPsModulePath.build.Sampler.ib.tasks'
        $taskAlias.ReferencedCommand | Should -Be 'SetPsModulePath.build.ps1'
        $taskAlias.Definition | Should -Match 'Sampler[\/|\\]\d+\.\d+\.\d+[\/|\\]tasks[\/|\\]SetPsModulePath\.build\.ps1'
    }

    Context 'When setting the PSModulePath' {
        BeforeAll {
            Mock -CommandName Set-SamplerPSModulePath
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'Set_PSModulePath' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw

            Assert-MockCalled -CommandName Set-SamplerPSModulePath -Exactly -Times 1 -Scope It
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
