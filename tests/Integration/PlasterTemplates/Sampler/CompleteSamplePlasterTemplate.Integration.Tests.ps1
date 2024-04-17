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

Describe 'Complete Module Plaster Template' {
    Context 'When creating a new module project' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'
            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName

            $listOfExpectedFilesAndFolders = @(
                # Folders (relative to module root)
                '.github'
                '.github/ISSUE_TEMPLATE'
                '.vscode'
                'output'
                'output/RequiredModules'
                'source'
                'source/Classes'
                # 'source/DSCResources'
                # 'source/DSCResources/DSC_Folder'
                # 'source/DSCResources/DSC_Folder/en-US'
                'source/Enum'
                'source/en-US'
                'source/Examples'
                # 'source/Examples/Resources'
                # 'source/Examples/Resources/Folder'
                'source/Modules'
                # 'source/Modules/Folder.Common'
                'source/Private'
                'source/Public'
                'source/WikiSource'
                'tests'
                'tests/QA'
                'tests/Unit'
                'tests/Unit/Classes'
                # 'tests/Unit/DSCResources'
                # 'tests/Unit/Modules'
                'tests/Unit/Private'
                'tests/Unit/Public'

                # Files (relative to module root)
                '.github/ISSUE_TEMPLATE/config.yml'
                '.github/ISSUE_TEMPLATE/General.md'
                '.github/ISSUE_TEMPLATE/Problem_with_module.yml'
                '.github/ISSUE_TEMPLATE/Problem_with_resource.yml'
                '.github/ISSUE_TEMPLATE/Resource_proposal.yml'
                '.github/PULL_REQUEST_TEMPLATE.md'
                '.gitattributes'
                '.gitignore'
                '.markdownlint.json'
                'azure-pipelines.yml'
                'build.ps1'
                'build.yaml'
                'CHANGELOG.md'
                'CODE_OF_CONDUCT.md'
                'codecov.yml'
                'CONTRIBUTING.md'
                'SECURITY.md'
                'GitVersion.yml'
                'README.md'
                'RequiredModules.psd1'
                'Resolve-Dependency.ps1'
                'Resolve-Dependency.psd1'
                '.vscode/analyzersettings.psd1'
                '.vscode/settings.json'
                '.vscode/tasks.json'
                '.vscode/extensions.json'
                'source/ModuleDsc.psd1'
                'source/ModuleDsc.psm1'
                # 'source/Modules/Folder.Common/Folder.Common.psm1'
                'source/Classes/1.class1.ps1'
                'source/Classes/2.class2.ps1'
                'source/Classes/3.class11.ps1'
                'source/Classes/4.class12.ps1'
                # 'source/DSCResources/DSC_Folder/DSC_Folder.psm1'
                # 'source/DSCResources/DSC_Folder/DSC_Folder.schema.mof'
                # 'source/DSCResources/DSC_Folder/en-US/DSC_Folder.strings.psd1'
                'source/en-US/about_ModuleDsc.help.txt'
                # 'source/Examples/README.md'
                # 'source/Examples/Resources/Folder/1-DscResourceTemplate_CreateFolderAsSystemConfig.ps1'
                # 'source/Examples/Resources/Folder/2-DscResourceTemplate_CreateFolderAsUserConfig.ps1'
                # 'source/Examples/Resources/Folder/3-DscResourceTemplate_RemoveFolderConfig.ps1'
                'source/Private/Get-PrivateFunction.ps1'
                'source/Public/Get-Something.ps1'
                'tests/QA/module.tests.ps1'
                'tests/Unit/Classes/class1.tests.ps1'
                'tests/Unit/Classes/class11.tests.ps1'
                'tests/Unit/Classes/class12.tests.ps1'
                'tests/Unit/Classes/class2.tests.ps1'
                # 'tests/Unit/DSCResources/DSC_Folder.tests.ps1'
                # 'tests/Unit/Modules/Folder.Common.tests.ps1'
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
                ModuleType           = 'CompleteSample'

                # Template properties
                ModuleName           = $mockModuleName
                MainGitBranch        = 'main'
                ModuleAuthor         = 'SamplerTestUser'
                ModuleDescription    = 'Module description'
                ModuleVersion        = '1.0.0'
                CustomRepo           = 'PSGallery'
                GitHubOwner          = 'AccountName'
                UseGitVersion        = $true
                UseCodeCovIo         = $true
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
