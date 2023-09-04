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
        #$mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName
        $mockModuleRootPath = Join-Path -Path 'C:\Temp' -ChildPath $mockModuleName
    }

    AfterAll {
        # Revert back location to repository root.
        Set-Location -Path (Join-Path -Path $PSScriptRoot -ChildPath '../../')
    }

    It 'Should create MySimpleModule without throwing' {
        $invokePlasterParameters = @{
            TemplatePath         = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
            DestinationPath      = 'C:\Temp' #$TestDrive
            SourceDirectory      = 'source'
            NoLogo               = $true
            Force                = $true

            # Template
            ModuleType           = 'SimpleModule'

            # Template properties
            ModuleName           = $mockModuleName
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
            git add *
            git commit --message=first
            git status > c:\temp\log.txt

            ./build.ps1 -ResolveDependency -Tasks 'build' #4>&1 5>&1 6>&1 > $null
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
}
