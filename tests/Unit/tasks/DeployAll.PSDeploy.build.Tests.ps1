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

Describe 'DeployAll.PSDeploy' {
    It 'Should have exported the alias correct' {
        $taskAlias = Get-Alias -Name 'DeployAll.PSDeploy.build.Sampler.ib.tasks'

        $taskAlias.Name | Should -Be 'DeployAll.PSDeploy.build.Sampler.ib.tasks'
        $taskAlias.ReferencedCommand | Should -Be 'DeployAll.PSDeploy.build.ps1'
        $taskAlias.Definition | Should -Match 'Sampler[\/|\\]\d+\.\d+\.\d+[\/|\\]tasks[\/|\\]DeployAll\.PSDeploy\.build\.ps1'
    }
}

Describe 'Deploy_with_PSDeploy' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $taskAlias = Get-Alias -Name 'DeployAll.PSDeploy.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            BuildOutput = Join-Path -Path $TestDrive -ChildPath 'MyModule/output'
            ProjectName = 'MyModule'
        }
    }

    It 'Should run the build task without throwing' {
        # Stub for Invoke-PSDeploy since the module is not part of Sampler build process.
        function Invoke-PSDeploy {}

        Mock -CommandName Import-Module
        Mock -CommandName Invoke-PSDeploy

        {
            Invoke-Build -Task 'Deploy_with_PSDeploy' -File $taskAlias.Definition @mockTaskParameters
        } | Should -Not -Throw
    }
}
