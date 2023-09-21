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

    Import-Module -Name "$PSScriptRoot\..\..\IntegrationTestHelpers.psm1"

    Install-TreeCommand
}

AfterAll {
    Remove-Module -Name $script:moduleName
}

Describe 'Simple Module Plaster Template' {
    Context 'When creating a new module project' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'
            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName

            $listOfExpectedFilesAndFolders = @(
                # Folders (relative to module root)

                '.vscode'
                'source'
                'source/en-US'
                'source/Private'
                'source/Public'
                'tests'
                'tests/QA'
                'tests/Unit'
                'tests/Unit/Private'
                'tests/Unit/Public'
                'output'
                'output/RequiredModules'

                # Files (relative to module root)

                '.gitattributes'
                '.gitignore'
                'azure-pipelines.yml'
                'build.ps1'
                'build.yaml'
                'CHANGELOG.md'
                'codecov.yml'
                'GitVersion.yml'
                'README.md'
                'RequiredModules.psd1'
                'Resolve-Dependency.ps1'
                'Resolve-Dependency.psd1'
                '.vscode/tasks.json'
                'source/ModuleDsc.psd1'
                'source/ModuleDsc.psm1'
                'source/en-US/about_ModuleDsc.help.txt'
                'source/Private/Get-PrivateFunction.ps1'
                'source/Public/Get-Something.ps1'
                'tests/QA/module.tests.ps1'
                'tests/Unit/Private/Get-PrivateFunction.tests.ps1'
                'tests/Unit/Public/Get-Something.tests.ps1'
            )
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath         = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
                DestinationPath      = $TestDrive
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

        It 'Should have the expected folder and file structure' {
            $modulePaths = Get-ChildItem -Path $mockModuleRootPath -Recurse -Force

            # Make the path relative to module root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockModuleRootPath)

            # Change to slash when testing on Windows.
            $relativeModulePaths = ($relativeModulePaths -replace '\\', '/').TrimStart('/')

            # check files & folders discrepencies
            $missingFilesOrFolders    = $listOfExpectedFilesAndFolders.Where{$_ -notin $relativeModulePaths}
            $unexpectedFilesAndFolders  = $relativeModulePaths.Where{$_ -notin $listOfExpectedFilesAndFolders}
            $TreeStructureIsOk = ($missingFilesOrFolders.count -eq 0 -and $unexpectedFilesAndFolders.count -eq 0)

            # format the report to be used in because
            $report = ":`r`n  Missing:`r`n`t$($missingFilesOrFolders -join "`r`n`t")`r`n  Unexpected:`r`n`t$($unexpectedFilesAndFolders -join "`r`n`t")`r`n."

            # Check if tree structure failed. If so output the module directory tree.
            if ( -not $TreeStructureIsOk)
            {
                $treeOutput = Get-DirectoryTree -Path $mockModuleRootPath
                Write-Verbose -Message ($treeOutput | Out-String) -Verbose
            }

            $TreeStructureIsOk | Should -BeTrue -Because $report
        }
    }

    Context 'When creating a new module project that is not using GitVersion' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'
            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName

            $listOfExpectedFilesAndFolders = @(
                # Folders (relative to module root)

                '.vscode'
                'source'
                'source/en-US'
                'source/Private'
                'source/Public'
                'tests'
                'tests/QA'
                'tests/Unit'
                'tests/Unit/Private'
                'tests/Unit/Public'
                'output'
                'output/RequiredModules'

                # Files (relative to module root)

                '.gitattributes'
                '.gitignore'
                'azure-pipelines.yml'
                'build.ps1'
                'build.yaml'
                'CHANGELOG.md'
                'codecov.yml'
                'README.md'
                'RequiredModules.psd1'
                'Resolve-Dependency.ps1'
                'Resolve-Dependency.psd1'
                '.vscode/tasks.json'
                'source/ModuleDsc.psd1'
                'source/ModuleDsc.psm1'
                'source/Private/Get-PrivateFunction.ps1'
                'source/Public/Get-Something.ps1'
                'source/en-US/about_ModuleDsc.help.txt'
                'tests/QA/module.tests.ps1'
                'tests/Unit/Private/Get-PrivateFunction.tests.ps1'
                'tests/Unit/Public/Get-Something.tests.ps1'
            )
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath         = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
                DestinationPath      = $TestDrive
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
                UseGitVersion        = $false
                UseCodeCovIo         = $true
                UseGitHub            = $true
                UseAzurePipelines    = $true
                UseVSCode            = $true
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should have the expected folder and file structure' {
            $modulePaths = Get-ChildItem -Path $mockModuleRootPath -Recurse -Force

            # Make the path relative to module root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockModuleRootPath)

            # Change to slash when testing on Windows.
            $relativeModulePaths = ($relativeModulePaths -replace '\\', '/').TrimStart('/')

            # check files & folders discrepencies
            $missingFilesOrFolders    = $listOfExpectedFilesAndFolders.Where{$_ -notin $relativeModulePaths}
            $unexpectedFilesAndFolders  = $relativeModulePaths.Where{$_ -notin $listOfExpectedFilesAndFolders}
            $TreeStructureIsOk = ($missingFilesOrFolders.count -eq 0 -and $unexpectedFilesAndFolders.count -eq 0)

            # format the report to be used in because
            $report = ":`r`n  Missing:`r`n`t$($missingFilesOrFolders -join "`r`n`t")`r`n  Unexpected:`r`n`t$($unexpectedFilesAndFolders -join "`r`n`t")`r`n."

            # Check if tree structure failed. If so output the module directory tree.
            if ( -not $TreeStructureIsOk)
            {
                $treeOutput = Get-DirectoryTree -Path $mockModuleRootPath
                Write-Verbose -Message ($treeOutput | Out-String) -Verbose
            }

            $TreeStructureIsOk | Should -BeTrue -Because $report
        }
    }

    Context 'When creating a new module project that is not using Codecov.io' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'
            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName

            $listOfExpectedFilesAndFolders = @(
                # Folders (relative to module root)

                '.vscode'
                'source'
                'source/en-US'
                'source/Private'
                'source/Public'
                'tests'
                'tests/QA'
                'tests/Unit'
                'tests/Unit/Private'
                'tests/Unit/Public'
                'output'
                'output/RequiredModules'

                # Files (relative to module root)

                '.gitattributes'
                '.gitignore'
                'azure-pipelines.yml'
                'build.ps1'
                'build.yaml'
                'CHANGELOG.md'
                'GitVersion.yml'
                'README.md'
                'RequiredModules.psd1'
                'Resolve-Dependency.ps1'
                'Resolve-Dependency.psd1'
                '.vscode/tasks.json'
                'source/ModuleDsc.psd1'
                'source/ModuleDsc.psm1'
                'source/en-US/about_ModuleDsc.help.txt'
                'source/Private/Get-PrivateFunction.ps1'
                'source/Public/Get-Something.ps1'
                'tests/QA/module.tests.ps1'
                'tests/Unit/Private/Get-PrivateFunction.tests.ps1'
                'tests/Unit/Public/Get-Something.tests.ps1'
            )
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath         = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
                DestinationPath      = $TestDrive
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
                UseCodeCovIo         = $false
                UseGitHub            = $true
                UseAzurePipelines    = $true
                UseVSCode            = $true
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should have the expected folder and file structure' {
            $modulePaths = Get-ChildItem -Path $mockModuleRootPath -Recurse -Force

            # Make the path relative to module root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockModuleRootPath)

            # Change to slash when testing on Windows.
            $relativeModulePaths = ($relativeModulePaths -replace '\\', '/').TrimStart('/')

            # check files & folders discrepencies
            $missingFilesOrFolders    = $listOfExpectedFilesAndFolders.Where{$_ -notin $relativeModulePaths}
            $unexpectedFilesAndFolders  = $relativeModulePaths.Where{$_ -notin $listOfExpectedFilesAndFolders}
            $TreeStructureIsOk = ($missingFilesOrFolders.count -eq 0 -and $unexpectedFilesAndFolders.count -eq 0)

            # format the report to be used in because
            $report = ":`r`n  Missing:`r`n`t$($missingFilesOrFolders -join "`r`n`t")`r`n  Unexpected:`r`n`t$($unexpectedFilesAndFolders -join "`r`n`t")`r`n."

            # Check if tree structure failed. If so output the module directory tree.
            if ( -not $TreeStructureIsOk)
            {
                $treeOutput = Get-DirectoryTree -Path $mockModuleRootPath
                Write-Verbose -Message ($treeOutput | Out-String) -Verbose
            }

            $TreeStructureIsOk | Should -BeTrue -Because $report
        }
    }
}
