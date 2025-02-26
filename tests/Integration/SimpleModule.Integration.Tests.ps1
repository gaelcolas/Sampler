BeforeAll {
    $script:moduleName = 'Sampler'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 2)
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    }

    # Re-import the module using force to get any code changes between runs.
    $importedModule = Import-Module -Name $script:moduleName -Force -PassThru -ErrorAction 'Stop'
}

AfterAll {
    Remove-Module -Name $script:moduleName
}

Describe 'SimpleModule' {
    BeforeAll {
        $mockModuleName = 'MySimpleModule'
        $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName
    }

    AfterAll {
        # Revert back location to repository root.
        Set-Location -Path (Join-Path -Path $PSScriptRoot -ChildPath '../../')
    }

    It 'Should create MySimpleModule without throwing' {
        $invokePlasterParameters = @{
            TemplatePath         = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
            DestinationPath      = $TestDrive
            NoLogo               = $true
            Force                = $true

            # Template
            ModuleType           = 'SimpleModule'

            # Template properties
            ModuleName           = $mockModuleName
            SourceDirectory      = 'source'
            ModuleAuthor         = 'SamplerTestUser'
            ModuleDescription    = 'Module description'
            ModuleVersion        = '1.0.0'
            CustomRepo           = 'PSGallery'
            MainGitBranch        = 'main'
            GitHubOwner          = 'AccountName'
            UseGit               = $true
            UseGitVersion        = $true
            UseCodeCovIo         = $true
            UseGitHub            = $true
            UseAzurePipelines    = $true
            UseVSCode            = $true
        }

        { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
    }

    It 'Should build MySimpleModule without throwing' {
        # Must be set so $Using:PWD works.
        Set-Location -Path $mockModuleRootPath

        # Running in separate job so that we do not mess up the current session.
        Start-Job -ScriptBlock {
            Set-Location $using:PWD

            git init --initial-branch=main

            git config --local user.name "SamplerIntegrationTester"
            git config --local user.email "SamplerIntegrationTester@company.local"

            <#
                Use 2>&1 to avoid the warning messages
                "LF will be replaced by CRLF the next time Git touches it"
                reported by git to be sent to stderr and fail the test.
            #>
            git add . 2>&1
            git commit --message=first

            ./build.ps1 -ResolveDependency -Tasks 'noop' 4>&1 5>&1 6>&1 > $null

            # This is a workaround for the issue: https://github.com/PoshCode/ModuleBuilder/pull/136
            Install-PSResource -Name 'Viscalyx.Common' -Repository PSGallery -TrustRepository -Quiet -Confirm:$false
            Import-Module -Name Viscalyx.Common
            Install-ModulePatch -SkipHashValidation -Uri 'https://raw.githubusercontent.com/viscalyx/Viscalyx.Common/refs/heads/main/patches/ModuleBuilder_3.1.7_patch.json' -Force

            ./build.ps1 -Tasks 'build' 4>&1 5>&1 6>&1 > $null
        } |
            Receive-Job -Wait -AutoRemoveJob -ErrorVariable buildError

        $buildError | Should -BeNullOrEmpty
    }

    It 'Should import MySimpleModule without throwing' {
        # Must be set so $Using:PWD works.
        Set-Location -Path $mockModuleRootPath

        # Running in separate job so that we do not mess up the current session.
        Start-Job -ScriptBlock {
            Set-Location $using:PWD

            Import-Module -Name (Join-Path -Path '.' -ChildPath 'output/module/MySimpleModule') -Verbose
        } |
            Receive-Job -Wait -AutoRemoveJob -ErrorVariable buildError

        $buildError | Should -BeNullOrEmpty
    }

    <#
        Skipping on Windows PowerShell since it throws with the error:
        "ScriptCallDepthException: The script failed due to call depth overflow".
        This is probably due to running Invoke-Build task that runs Invoke-Pester
        that then again runs Invoke-Build that again runs Invoke-Pester.
    #>
    It 'Should pass all sample tests' -Skip:($PSVersionTable.PSEdition -eq 'Desktop') {
        # Must be set so $Using:PWD works.
        Set-Location -Path $mockModuleRootPath

        # Running in separate job so that we do not mess up the current session.
        Start-Job -ScriptBlock {
            Set-Location $using:PWD

            Import-Module -Name 'ChangelogManagement'

            Add-ChangelogData -Path './CHANGELOG.md' -Type 'Fixed' -Data 'Entry for testing'

            ./build.ps1 -Tasks 'test' #4>&1 5>&1 6>&1 > $null
        } |
            Receive-Job -Wait -AutoRemoveJob -ErrorVariable buildError

        $buildError | Should -BeNullOrEmpty
    }
}
