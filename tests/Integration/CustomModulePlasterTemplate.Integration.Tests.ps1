#region HEADER
$script:projectPath = "$PSScriptRoot\..\.." | Convert-Path
$script:projectName = (Get-ChildItem -Path "$script:projectPath\*\*.psd1" | Where-Object -FilterScript {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            {
                Test-ModuleManifest -Path $_.FullName -ErrorAction Stop
            }
            catch
            {
                $false
            })
    }).BaseName

$script:moduleName = Get-Module -Name $script:projectName -ListAvailable | Select-Object -First 1
Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

$importedModule = Import-Module $script:moduleName -Force -PassThru -ErrorAction 'Stop'

#endregion HEADER

Import-Module -Name "$PSScriptRoot\IntegrationTestHelpers.psm1"

Install-TreeCommand

Describe 'Custom Module Plaster Template' {
    Context 'When creating a new module project with all features but without a license' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'

            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath      = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
                DestinationPath   = $TestDrive
                SourceDirectory   = 'source'
                NoLogo            = $true
                Force             = $true

                # Template
                ModuleType        = 'CustomModule'

                # Template properties
                ModuleName        = $mockModuleName
                ModuleAuthor      = 'SamplerTestUser'
                ModuleDescription = 'Module description'
                ModuleVersion     = '1.0.0'
                CustomRepo        = 'PSGallery'
                License           = 'false'
                Features          = 'All'
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should have the expected folder and file structure' {
            $modulePaths = Get-ChildItem -Path $mockModuleRootPath -Recurse -Force

            # Make the path relative to module root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockModuleRootPath)

            # Change to slash when testing on Windows.
            $relativeModulePaths = ($relativeModulePaths -replace '\\', '/').TrimStart('/')

            # Folders (relative to module root)

            '.github' | Should -BeIn $relativeModulePaths
            '.vscode' | Should -BeIn $relativeModulePaths
            'output' | Should -BeIn $relativeModulePaths
            'output/RequiredModules' | Should -BeIn $relativeModulePaths
            'source' | Should -BeIn $relativeModulePaths
            'source/Classes' | Should -BeIn $relativeModulePaths
            'source/DSCResources' | Should -BeIn $relativeModulePaths
            'source/DSCResources/DSC_Folder' | Should -BeIn $relativeModulePaths
            'source/DSCResources/DSC_Folder/en-US' | Should -BeIn $relativeModulePaths
            'source/Enums' | Should -BeIn $relativeModulePaths
            'source/en-US' | Should -BeIn $relativeModulePaths
            'source/Examples' | Should -BeIn $relativeModulePaths
            'source/Examples/Resources' | Should -BeIn $relativeModulePaths
            'source/Examples/Resources/Folder' | Should -BeIn $relativeModulePaths
            'source/Private' | Should -BeIn $relativeModulePaths
            'source/Public' | Should -BeIn $relativeModulePaths
            'tests' | Should -BeIn $relativeModulePaths
            'tests/QA' | Should -BeIn $relativeModulePaths
            'tests/Unit' | Should -BeIn $relativeModulePaths
            'tests/Unit/Classes' | Should -BeIn $relativeModulePaths
            'tests/Unit/DSCResources' | Should -BeIn $relativeModulePaths
            'tests/Unit/Private' | Should -BeIn $relativeModulePaths
            'tests/Unit/Public' | Should -BeIn $relativeModulePaths

            # Files (relative to module root)

            '.gitattributes' | Should -BeIn $relativeModulePaths
            '.gitignore' | Should -BeIn $relativeModulePaths
            '.kitchen.yml' | Should -BeIn $relativeModulePaths
            '.markdownlint.json' | Should -BeIn $relativeModulePaths
            'azure-pipelines.yml' | Should -BeIn $relativeModulePaths
            'build.ps1' | Should -BeIn $relativeModulePaths
            'build.yaml' | Should -BeIn $relativeModulePaths
            'CHANGELOG.md' | Should -BeIn $relativeModulePaths
            'CODE_OF_CONDUCT.md' | Should -BeIn $relativeModulePaths
            'CONTRIBUTING.md' | Should -BeIn $relativeModulePaths
            'GitVersion.yml' | Should -BeIn $relativeModulePaths
            'README.md' | Should -BeIn $relativeModulePaths
            'RequiredModules.psd1' | Should -BeIn $relativeModulePaths
            'Resolve-Dependency.ps1' | Should -BeIn $relativeModulePaths
            'Resolve-Dependency.psd1' | Should -BeIn $relativeModulePaths
            '.vscode/analyzersettings.psd1' | Should -BeIn $relativeModulePaths
            '.vscode/settings.json' | Should -BeIn $relativeModulePaths
            '.vscode/tasks.json' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psd1' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psm1' | Should -BeIn $relativeModulePaths
            'source/Classes/1.class1.ps1' | Should -BeIn $relativeModulePaths
            'source/Classes/2.class2.ps1' | Should -BeIn $relativeModulePaths
            'source/Classes/3.class11.ps1' | Should -BeIn $relativeModulePaths
            'source/Classes/4.class12.ps1' | Should -BeIn $relativeModulePaths
            'source/DSCResources/DSC_Folder/DSC_Folder.psm1' | Should -BeIn $relativeModulePaths
            'source/DSCResources/DSC_Folder/DSC_Folder.schema.mof' | Should -BeIn $relativeModulePaths
            'source/DSCResources/DSC_Folder/en-US/DSC_Folder.psd1' | Should -BeIn $relativeModulePaths
            'source/en-US/about_ModuleDsc.help.txt' | Should -BeIn $relativeModulePaths
            'source/Examples/Resources/Folder/1-DscResourceTemplate_CreateFolderAsSystemConfig.ps1' | Should -BeIn $relativeModulePaths
            'source/Examples/Resources/Folder/2-DscResourceTemplate_CreateFolderAsUserConfig.ps1' | Should -BeIn $relativeModulePaths
            'source/Examples/Resources/Folder/3-DscResourceTemplate_RemoveFolderConfig.ps1' | Should -BeIn $relativeModulePaths
            'source/Private/Get-PrivateFunction.ps1' | Should -BeIn $relativeModulePaths
            'source/Public/Get-Something.ps1' | Should -BeIn $relativeModulePaths
            'tests/QA/module.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Classes/class1.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Classes/class11.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Classes/class12.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Classes/class2.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/DSCResources/DSC_Folder.Tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Private/Get-PrivateFunction.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Public/Get-Something.tests.ps1' | Should -BeIn $relativeModulePaths

            $relativeModulePaths | Should -HaveCount 64
        } -ErrorVariable itBlockError

        # Check if previous It-block failed. If so output the module directory tree.
        if ( $itBlockError.Count -ne 0 )
        {
            $treeOutput = Get-DirectoryTree -Path $mockModuleRootPath

            Write-Verbose -Message ($treeOutput | Out-String) -Verbose
        }
    }

    Context 'When creating a new module project with license MIT and all features' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'

            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath      = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
                DestinationPath   = $TestDrive
                SourceDirectory   = 'source'
                NoLogo            = $true
                Force             = $true

                # Template
                ModuleType        = 'CustomModule'

                # Template properties
                ModuleName        = $mockModuleName
                ModuleAuthor      = 'SamplerTestUser'
                ModuleDescription = 'Module description'
                ModuleVersion     = '1.0.0'
                CustomRepo        = 'PSGallery'
                License           = 'true'
                LicenseType       = 'MIT'
                Features          = 'All'
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should have the expected folder and file structure' {
            $modulePaths = Get-ChildItem -Path $mockModuleRootPath -Recurse -Force

            # Make the path relative to module root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockModuleRootPath)

            # Change to slash when testing on Windows.
            $relativeModulePaths = ($relativeModulePaths -replace '\\', '/').TrimStart('/')

            # Folders (relative to module root)

            '.github' | Should -BeIn $relativeModulePaths
            '.vscode' | Should -BeIn $relativeModulePaths
            'output' | Should -BeIn $relativeModulePaths
            'output/RequiredModules' | Should -BeIn $relativeModulePaths
            'source' | Should -BeIn $relativeModulePaths
            'source/Classes' | Should -BeIn $relativeModulePaths
            'source/DSCResources' | Should -BeIn $relativeModulePaths
            'source/DSCResources/DSC_Folder' | Should -BeIn $relativeModulePaths
            'source/DSCResources/DSC_Folder/en-US' | Should -BeIn $relativeModulePaths
            'source/Enums' | Should -BeIn $relativeModulePaths
            'source/en-US' | Should -BeIn $relativeModulePaths
            'source/Examples' | Should -BeIn $relativeModulePaths
            'source/Examples/Resources' | Should -BeIn $relativeModulePaths
            'source/Examples/Resources/Folder' | Should -BeIn $relativeModulePaths
            'source/Private' | Should -BeIn $relativeModulePaths
            'source/Public' | Should -BeIn $relativeModulePaths
            'tests' | Should -BeIn $relativeModulePaths
            'tests/QA' | Should -BeIn $relativeModulePaths
            'tests/Unit' | Should -BeIn $relativeModulePaths
            'tests/Unit/Classes' | Should -BeIn $relativeModulePaths
            'tests/Unit/DSCResources' | Should -BeIn $relativeModulePaths
            'tests/Unit/Private' | Should -BeIn $relativeModulePaths
            'tests/Unit/Public' | Should -BeIn $relativeModulePaths

            # Files (relative to module root)

            '.gitattributes' | Should -BeIn $relativeModulePaths
            '.gitignore' | Should -BeIn $relativeModulePaths
            '.kitchen.yml' | Should -BeIn $relativeModulePaths
            '.markdownlint.json' | Should -BeIn $relativeModulePaths
            'azure-pipelines.yml' | Should -BeIn $relativeModulePaths
            'build.ps1' | Should -BeIn $relativeModulePaths
            'build.yaml' | Should -BeIn $relativeModulePaths
            'CHANGELOG.md' | Should -BeIn $relativeModulePaths
            'CODE_OF_CONDUCT.md' | Should -BeIn $relativeModulePaths
            'CONTRIBUTING.md' | Should -BeIn $relativeModulePaths
            'GitVersion.yml' | Should -BeIn $relativeModulePaths
            'LICENSE' | Should -BeIn $relativeModulePaths
            'README.md' | Should -BeIn $relativeModulePaths
            'RequiredModules.psd1' | Should -BeIn $relativeModulePaths
            'Resolve-Dependency.ps1' | Should -BeIn $relativeModulePaths
            'Resolve-Dependency.psd1' | Should -BeIn $relativeModulePaths
            '.vscode/analyzersettings.psd1' | Should -BeIn $relativeModulePaths
            '.vscode/settings.json' | Should -BeIn $relativeModulePaths
            '.vscode/tasks.json' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psd1' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psm1' | Should -BeIn $relativeModulePaths
            'source/Classes/1.class1.ps1' | Should -BeIn $relativeModulePaths
            'source/Classes/2.class2.ps1' | Should -BeIn $relativeModulePaths
            'source/Classes/3.class11.ps1' | Should -BeIn $relativeModulePaths
            'source/Classes/4.class12.ps1' | Should -BeIn $relativeModulePaths
            'source/DSCResources/DSC_Folder/DSC_Folder.psm1' | Should -BeIn $relativeModulePaths
            'source/DSCResources/DSC_Folder/DSC_Folder.schema.mof' | Should -BeIn $relativeModulePaths
            'source/DSCResources/DSC_Folder/en-US/DSC_Folder.psd1' | Should -BeIn $relativeModulePaths
            'source/en-US/about_ModuleDsc.help.txt' | Should -BeIn $relativeModulePaths
            'source/Examples/Resources/Folder/1-DscResourceTemplate_CreateFolderAsSystemConfig.ps1' | Should -BeIn $relativeModulePaths
            'source/Examples/Resources/Folder/2-DscResourceTemplate_CreateFolderAsUserConfig.ps1' | Should -BeIn $relativeModulePaths
            'source/Examples/Resources/Folder/3-DscResourceTemplate_RemoveFolderConfig.ps1' | Should -BeIn $relativeModulePaths
            'source/Private/Get-PrivateFunction.ps1' | Should -BeIn $relativeModulePaths
            'source/Public/Get-Something.ps1' | Should -BeIn $relativeModulePaths
            'tests/QA/module.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Classes/class1.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Classes/class11.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Classes/class12.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Classes/class2.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/DSCResources/DSC_Folder.Tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Private/Get-PrivateFunction.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Public/Get-Something.tests.ps1' | Should -BeIn $relativeModulePaths

            $relativeModulePaths | Should -HaveCount 65
        } -ErrorVariable itBlockError

        # Check if previous It-block failed. If so output the module directory tree.
        if ( $itBlockError.Count -ne 0 )
        {
            $treeOutput = Get-DirectoryTree -Path $mockModuleRootPath

            Write-Verbose -Message ($treeOutput | Out-String) -Verbose
        }
    }

    Context 'When creating a new module project with license Apache and all features' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'

            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath      = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
                DestinationPath   = $TestDrive
                SourceDirectory   = 'source'
                NoLogo            = $true
                Force             = $true

                # Template
                ModuleType        = 'CustomModule'

                # Template properties
                ModuleName        = $mockModuleName
                ModuleAuthor      = 'SamplerTestUser'
                ModuleDescription = 'Module description'
                ModuleVersion     = '1.0.0'
                CustomRepo        = 'PSGallery'
                License           = 'true'
                LicenseType       = 'Apache'
                Features          = 'All'
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should have the expected folder and file structure' {
            $modulePaths = Get-ChildItem -Path $mockModuleRootPath -Recurse -Force

            # Make the path relative to module root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockModuleRootPath)

            # Change to slash when testing on Windows.
            $relativeModulePaths = ($relativeModulePaths -replace '\\', '/').TrimStart('/')

            # Folders (relative to module root)

            '.github' | Should -BeIn $relativeModulePaths
            '.vscode' | Should -BeIn $relativeModulePaths
            'output' | Should -BeIn $relativeModulePaths
            'output/RequiredModules' | Should -BeIn $relativeModulePaths
            'source' | Should -BeIn $relativeModulePaths
            'source/Classes' | Should -BeIn $relativeModulePaths
            'source/DSCResources' | Should -BeIn $relativeModulePaths
            'source/DSCResources/DSC_Folder' | Should -BeIn $relativeModulePaths
            'source/DSCResources/DSC_Folder/en-US' | Should -BeIn $relativeModulePaths
            'source/Enums' | Should -BeIn $relativeModulePaths
            'source/en-US' | Should -BeIn $relativeModulePaths
            'source/Examples' | Should -BeIn $relativeModulePaths
            'source/Examples/Resources' | Should -BeIn $relativeModulePaths
            'source/Examples/Resources/Folder' | Should -BeIn $relativeModulePaths
            'source/Private' | Should -BeIn $relativeModulePaths
            'source/Public' | Should -BeIn $relativeModulePaths
            'tests' | Should -BeIn $relativeModulePaths
            'tests/QA' | Should -BeIn $relativeModulePaths
            'tests/Unit' | Should -BeIn $relativeModulePaths
            'tests/Unit/Classes' | Should -BeIn $relativeModulePaths
            'tests/Unit/DSCResources' | Should -BeIn $relativeModulePaths
            'tests/Unit/Private' | Should -BeIn $relativeModulePaths
            'tests/Unit/Public' | Should -BeIn $relativeModulePaths

            # Files (relative to module root)

            '.gitattributes' | Should -BeIn $relativeModulePaths
            '.gitignore' | Should -BeIn $relativeModulePaths
            '.kitchen.yml' | Should -BeIn $relativeModulePaths
            '.markdownlint.json' | Should -BeIn $relativeModulePaths
            'azure-pipelines.yml' | Should -BeIn $relativeModulePaths
            'build.ps1' | Should -BeIn $relativeModulePaths
            'build.yaml' | Should -BeIn $relativeModulePaths
            'CHANGELOG.md' | Should -BeIn $relativeModulePaths
            'CODE_OF_CONDUCT.md' | Should -BeIn $relativeModulePaths
            'CONTRIBUTING.md' | Should -BeIn $relativeModulePaths
            'GitVersion.yml' | Should -BeIn $relativeModulePaths
            'LICENSE' | Should -BeIn $relativeModulePaths
            'README.md' | Should -BeIn $relativeModulePaths
            'RequiredModules.psd1' | Should -BeIn $relativeModulePaths
            'Resolve-Dependency.ps1' | Should -BeIn $relativeModulePaths
            'Resolve-Dependency.psd1' | Should -BeIn $relativeModulePaths
            '.vscode/analyzersettings.psd1' | Should -BeIn $relativeModulePaths
            '.vscode/settings.json' | Should -BeIn $relativeModulePaths
            '.vscode/tasks.json' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psd1' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psm1' | Should -BeIn $relativeModulePaths
            'source/Classes/1.class1.ps1' | Should -BeIn $relativeModulePaths
            'source/Classes/2.class2.ps1' | Should -BeIn $relativeModulePaths
            'source/Classes/3.class11.ps1' | Should -BeIn $relativeModulePaths
            'source/Classes/4.class12.ps1' | Should -BeIn $relativeModulePaths
            'source/DSCResources/DSC_Folder/DSC_Folder.psm1' | Should -BeIn $relativeModulePaths
            'source/DSCResources/DSC_Folder/DSC_Folder.schema.mof' | Should -BeIn $relativeModulePaths
            'source/DSCResources/DSC_Folder/en-US/DSC_Folder.psd1' | Should -BeIn $relativeModulePaths
            'source/en-US/about_ModuleDsc.help.txt' | Should -BeIn $relativeModulePaths
            'source/Examples/Resources/Folder/1-DscResourceTemplate_CreateFolderAsSystemConfig.ps1' | Should -BeIn $relativeModulePaths
            'source/Examples/Resources/Folder/2-DscResourceTemplate_CreateFolderAsUserConfig.ps1' | Should -BeIn $relativeModulePaths
            'source/Examples/Resources/Folder/3-DscResourceTemplate_RemoveFolderConfig.ps1' | Should -BeIn $relativeModulePaths
            'source/Private/Get-PrivateFunction.ps1' | Should -BeIn $relativeModulePaths
            'source/Public/Get-Something.ps1' | Should -BeIn $relativeModulePaths
            'tests/QA/module.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Classes/class1.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Classes/class11.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Classes/class12.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Classes/class2.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/DSCResources/DSC_Folder.Tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Private/Get-PrivateFunction.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Public/Get-Something.tests.ps1' | Should -BeIn $relativeModulePaths

            $relativeModulePaths | Should -HaveCount 65
        } -ErrorVariable itBlockError

        # Check if previous It-block failed. If so output the module directory tree.
        if ( $itBlockError.Count -ne 0 )
        {
            $treeOutput = Get-DirectoryTree -Path $mockModuleRootPath

            Write-Verbose -Message ($treeOutput | Out-String) -Verbose
        }
    }

    Context 'When creating a new module project with all features but with the license type ''None''' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'

            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath      = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
                DestinationPath   = $TestDrive
                SourceDirectory   = 'source'
                NoLogo            = $true
                Force             = $true

                # Template
                ModuleType        = 'CustomModule'

                # Template properties
                ModuleName        = $mockModuleName
                ModuleAuthor      = 'SamplerTestUser'
                ModuleDescription = 'Module description'
                ModuleVersion     = '1.0.0'
                CustomRepo        = 'PSGallery'
                License           = 'true'
                LicenseType       = 'Apache'
                Features          = 'All'
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should have the expected folder and file structure' {
            $modulePaths = Get-ChildItem -Path $mockModuleRootPath -Recurse -Force

            # Make the path relative to module root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockModuleRootPath)

            # Change to slash when testing on Windows.
            $relativeModulePaths = ($relativeModulePaths -replace '\\', '/').TrimStart('/')

            # Folders (relative to module root)

            '.github' | Should -BeIn $relativeModulePaths
            '.vscode' | Should -BeIn $relativeModulePaths
            'output' | Should -BeIn $relativeModulePaths
            'output/RequiredModules' | Should -BeIn $relativeModulePaths
            'source' | Should -BeIn $relativeModulePaths
            'source/Classes' | Should -BeIn $relativeModulePaths
            'source/DSCResources' | Should -BeIn $relativeModulePaths
            'source/DSCResources/DSC_Folder' | Should -BeIn $relativeModulePaths
            'source/DSCResources/DSC_Folder/en-US' | Should -BeIn $relativeModulePaths
            'source/Enums' | Should -BeIn $relativeModulePaths
            'source/en-US' | Should -BeIn $relativeModulePaths
            'source/Examples' | Should -BeIn $relativeModulePaths
            'source/Examples/Resources' | Should -BeIn $relativeModulePaths
            'source/Examples/Resources/Folder' | Should -BeIn $relativeModulePaths
            'source/Private' | Should -BeIn $relativeModulePaths
            'source/Public' | Should -BeIn $relativeModulePaths
            'tests' | Should -BeIn $relativeModulePaths
            'tests/QA' | Should -BeIn $relativeModulePaths
            'tests/Unit' | Should -BeIn $relativeModulePaths
            'tests/Unit/Classes' | Should -BeIn $relativeModulePaths
            'tests/Unit/DSCResources' | Should -BeIn $relativeModulePaths
            'tests/Unit/Private' | Should -BeIn $relativeModulePaths
            'tests/Unit/Public' | Should -BeIn $relativeModulePaths

            # Files (relative to module root)

            '.gitattributes' | Should -BeIn $relativeModulePaths
            '.gitignore' | Should -BeIn $relativeModulePaths
            '.kitchen.yml' | Should -BeIn $relativeModulePaths
            '.markdownlint.json' | Should -BeIn $relativeModulePaths
            'azure-pipelines.yml' | Should -BeIn $relativeModulePaths
            'build.ps1' | Should -BeIn $relativeModulePaths
            'build.yaml' | Should -BeIn $relativeModulePaths
            'CHANGELOG.md' | Should -BeIn $relativeModulePaths
            'CODE_OF_CONDUCT.md' | Should -BeIn $relativeModulePaths
            'CONTRIBUTING.md' | Should -BeIn $relativeModulePaths
            'GitVersion.yml' | Should -BeIn $relativeModulePaths
            'LICENSE' | Should -BeIn $relativeModulePaths
            'README.md' | Should -BeIn $relativeModulePaths
            'RequiredModules.psd1' | Should -BeIn $relativeModulePaths
            'Resolve-Dependency.ps1' | Should -BeIn $relativeModulePaths
            'Resolve-Dependency.psd1' | Should -BeIn $relativeModulePaths
            '.vscode/analyzersettings.psd1' | Should -BeIn $relativeModulePaths
            '.vscode/settings.json' | Should -BeIn $relativeModulePaths
            '.vscode/tasks.json' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psd1' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psm1' | Should -BeIn $relativeModulePaths
            'source/Classes/1.class1.ps1' | Should -BeIn $relativeModulePaths
            'source/Classes/2.class2.ps1' | Should -BeIn $relativeModulePaths
            'source/Classes/3.class11.ps1' | Should -BeIn $relativeModulePaths
            'source/Classes/4.class12.ps1' | Should -BeIn $relativeModulePaths
            'source/DSCResources/DSC_Folder/DSC_Folder.psm1' | Should -BeIn $relativeModulePaths
            'source/DSCResources/DSC_Folder/DSC_Folder.schema.mof' | Should -BeIn $relativeModulePaths
            'source/DSCResources/DSC_Folder/en-US/DSC_Folder.psd1' | Should -BeIn $relativeModulePaths
            'source/en-US/about_ModuleDsc.help.txt' | Should -BeIn $relativeModulePaths
            'source/Examples/Resources/Folder/1-DscResourceTemplate_CreateFolderAsSystemConfig.ps1' | Should -BeIn $relativeModulePaths
            'source/Examples/Resources/Folder/2-DscResourceTemplate_CreateFolderAsUserConfig.ps1' | Should -BeIn $relativeModulePaths
            'source/Examples/Resources/Folder/3-DscResourceTemplate_RemoveFolderConfig.ps1' | Should -BeIn $relativeModulePaths
            'source/Private/Get-PrivateFunction.ps1' | Should -BeIn $relativeModulePaths
            'source/Public/Get-Something.ps1' | Should -BeIn $relativeModulePaths
            'tests/QA/module.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Classes/class1.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Classes/class11.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Classes/class12.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Classes/class2.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/DSCResources/DSC_Folder.Tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Private/Get-PrivateFunction.tests.ps1' | Should -BeIn $relativeModulePaths
            'tests/Unit/Public/Get-Something.tests.ps1' | Should -BeIn $relativeModulePaths

            $relativeModulePaths | Should -HaveCount 65
        } -ErrorVariable itBlockError

        # Check if previous It-block failed. If so output the module directory tree.
        if ( $itBlockError.Count -ne 0 )
        {
            $treeOutput = Get-DirectoryTree -Path $mockModuleRootPath

            Write-Verbose -Message ($treeOutput | Out-String) -Verbose
        }
    }

    Context 'When creating a new module project with only the feature ''Enums''' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'

            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath      = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
                DestinationPath   = $TestDrive
                SourceDirectory   = 'source'
                NoLogo            = $true
                Force             = $true

                # Template
                ModuleType        = 'CustomModule'

                # Template properties
                ModuleName        = $mockModuleName
                ModuleAuthor      = 'SamplerTestUser'
                ModuleDescription = 'Module description'
                ModuleVersion     = '1.0.0'
                CustomRepo        = 'PSGallery'
                License           = 'false'
                Features          = 'Enums'
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should have the expected folder and file structure' {
            $modulePaths = Get-ChildItem -Path $mockModuleRootPath -Recurse -Force

            # Make the path relative to module root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockModuleRootPath)

            # Change to slash when testing on Windows.
            $relativeModulePaths = ($relativeModulePaths -replace '\\', '/').TrimStart('/')

            # Folders (relative to module root)

            'source' | Should -BeIn $relativeModulePaths
            'source/Enums' | Should -BeIn $relativeModulePaths
            'source/en-US' | Should -BeIn $relativeModulePaths
            'source/Examples' | Should -BeIn $relativeModulePaths
            'source/Private' | Should -BeIn $relativeModulePaths
            'source/Public' | Should -BeIn $relativeModulePaths

            # Files (relative to module root)

            'README.md' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psd1' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psm1' | Should -BeIn $relativeModulePaths
            'source/en-US/about_ModuleDsc.help.txt' | Should -BeIn $relativeModulePaths

            $relativeModulePaths | Should -HaveCount 10
        } -ErrorVariable itBlockError

        # Check if previous It-block failed. If so output the module directory tree.
        if ( $itBlockError.Count -ne 0 )
        {
            $treeOutput = Get-DirectoryTree -Path $mockModuleRootPath

            Write-Verbose -Message ($treeOutput | Out-String) -Verbose
        }
    }

    Context 'When creating a new module project with only the feature ''Classes''' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'

            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath      = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
                DestinationPath   = $TestDrive
                SourceDirectory   = 'source'
                NoLogo            = $true
                Force             = $true

                # Template
                ModuleType        = 'CustomModule'

                # Template properties
                ModuleName        = $mockModuleName
                ModuleAuthor      = 'SamplerTestUser'
                ModuleDescription = 'Module description'
                ModuleVersion     = '1.0.0'
                CustomRepo        = 'PSGallery'
                License           = 'false'
                Features          = 'Classes' # All,Enums,Classes,DSCResources,SampleScripts,git,Gherkin,UnitTests,ModuleQuality,Build,AppVeyor,TestKitchen
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should have the expected folder and file structure' {
            $modulePaths = Get-ChildItem -Path $mockModuleRootPath -Recurse -Force

            # Make the path relative to module root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockModuleRootPath)

            # Change to slash when testing on Windows.
            $relativeModulePaths = ($relativeModulePaths -replace '\\', '/').TrimStart('/')

            # Folders (relative to module root)

            'source' | Should -BeIn $relativeModulePaths
            'source/Classes' | Should -BeIn $relativeModulePaths
            'source/en-US' | Should -BeIn $relativeModulePaths
            'source/Examples' | Should -BeIn $relativeModulePaths
            'source/Private' | Should -BeIn $relativeModulePaths
            'source/Public' | Should -BeIn $relativeModulePaths

            # Files (relative to module root)

            'README.md' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psd1' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psm1' | Should -BeIn $relativeModulePaths
            'source/en-US/about_ModuleDsc.help.txt' | Should -BeIn $relativeModulePaths

            $relativeModulePaths | Should -HaveCount 10
        } -ErrorVariable itBlockError

        # Check if previous It-block failed. If so output the module directory tree.
        if ( $itBlockError.Count -ne 0 )
        {
            $treeOutput = Get-DirectoryTree -Path $mockModuleRootPath

            Write-Verbose -Message ($treeOutput | Out-String) -Verbose
        }
    }

    Context 'When creating a new module project with only the feature ''DSCResources''' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'

            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath      = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
                DestinationPath   = $TestDrive
                SourceDirectory   = 'source'
                NoLogo            = $true
                Force             = $true

                # Template
                ModuleType        = 'CustomModule'

                # Template properties
                ModuleName        = $mockModuleName
                ModuleAuthor      = 'SamplerTestUser'
                ModuleDescription = 'Module description'
                ModuleVersion     = '1.0.0'
                CustomRepo        = 'PSGallery'
                License           = 'false'
                Features          = 'DSCResources' # All,Enums,Classes,DSCResources,SampleScripts,git,Gherkin,UnitTests,ModuleQuality,Build,AppVeyor,TestKitchen
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should have the expected folder and file structure' {
            $modulePaths = Get-ChildItem -Path $mockModuleRootPath -Recurse -Force

            # Make the path relative to module root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockModuleRootPath)

            # Change to slash when testing on Windows.
            $relativeModulePaths = ($relativeModulePaths -replace '\\', '/').TrimStart('/')

            # Folders (relative to module root)

            'source' | Should -BeIn $relativeModulePaths
            'source/DSCResources' | Should -BeIn $relativeModulePaths
            'source/en-US' | Should -BeIn $relativeModulePaths
            'source/Examples' | Should -BeIn $relativeModulePaths
            'source/Private' | Should -BeIn $relativeModulePaths
            'source/Public' | Should -BeIn $relativeModulePaths

            # Files (relative to module root)

            'README.md' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psd1' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psm1' | Should -BeIn $relativeModulePaths
            'source/en-US/about_ModuleDsc.help.txt' | Should -BeIn $relativeModulePaths

            $relativeModulePaths | Should -HaveCount 10
        } -ErrorVariable itBlockError

        # Check if previous It-block failed. If so output the module directory tree.
        if ( $itBlockError.Count -ne 0 )
        {
            $treeOutput = Get-DirectoryTree -Path $mockModuleRootPath

            Write-Verbose -Message ($treeOutput | Out-String) -Verbose
        }
    }

    Context 'When creating a new module project with only the feature ''SampleScripts''' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'

            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath      = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
                DestinationPath   = $TestDrive
                SourceDirectory   = 'source'
                NoLogo            = $true
                Force             = $true

                # Template
                ModuleType        = 'CustomModule'

                # Template properties
                ModuleName        = $mockModuleName
                ModuleAuthor      = 'SamplerTestUser'
                ModuleDescription = 'Module description'
                ModuleVersion     = '1.0.0'
                CustomRepo        = 'PSGallery'
                License           = 'false'
                Features          = 'SampleScripts' # All,Enums,Classes,DSCResources,SampleScripts,git,Gherkin,UnitTests,ModuleQuality,Build,AppVeyor,TestKitchen
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should have the expected folder and file structure' {
            $modulePaths = Get-ChildItem -Path $mockModuleRootPath -Recurse -Force

            # Make the path relative to module root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockModuleRootPath)

            # Change to slash when testing on Windows.
            $relativeModulePaths = ($relativeModulePaths -replace '\\', '/').TrimStart('/')

            # Folders (relative to module root)

            'source' | Should -BeIn $relativeModulePaths
            'source/en-US' | Should -BeIn $relativeModulePaths
            'source/Examples' | Should -BeIn $relativeModulePaths
            'source/Private' | Should -BeIn $relativeModulePaths
            'source/Public' | Should -BeIn $relativeModulePaths

            # Files (relative to module root)

            'README.md' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psd1' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psm1' | Should -BeIn $relativeModulePaths
            'source/en-US/about_ModuleDsc.help.txt' | Should -BeIn $relativeModulePaths
            'source/Private/Get-PrivateFunction.ps1' | Should -BeIn $relativeModulePaths
            'source/Public/Get-Something.ps1' | Should -BeIn $relativeModulePaths

            $relativeModulePaths | Should -HaveCount 11
        } -ErrorVariable itBlockError

        # Check if previous It-block failed. If so output the module directory tree.
        if ( $itBlockError.Count -ne 0 )
        {
            $treeOutput = Get-DirectoryTree -Path $mockModuleRootPath

            Write-Verbose -Message ($treeOutput | Out-String) -Verbose
        }
    }

    Context 'When creating a new module project with only the feature ''git''' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'

            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath      = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
                DestinationPath   = $TestDrive
                SourceDirectory   = 'source'
                NoLogo            = $true
                Force             = $true

                # Template
                ModuleType        = 'CustomModule'

                # Template properties
                ModuleName        = $mockModuleName
                ModuleAuthor      = 'SamplerTestUser'
                ModuleDescription = 'Module description'
                ModuleVersion     = '1.0.0'
                CustomRepo        = 'PSGallery'
                License           = 'false'
                Features          = 'git' # All,Enums,Classes,DSCResources,SampleScripts,git,Gherkin,UnitTests,ModuleQuality,Build,AppVeyor,TestKitchen
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should have the expected folder and file structure' {
            $modulePaths = Get-ChildItem -Path $mockModuleRootPath -Recurse -Force

            # Make the path relative to module root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockModuleRootPath)

            # Change to slash when testing on Windows.
            $relativeModulePaths = ($relativeModulePaths -replace '\\', '/').TrimStart('/')

            # Folders (relative to module root)

            'source' | Should -BeIn $relativeModulePaths
            'source/en-US' | Should -BeIn $relativeModulePaths
            'source/Examples' | Should -BeIn $relativeModulePaths
            'source/Private' | Should -BeIn $relativeModulePaths
            'source/Public' | Should -BeIn $relativeModulePaths

            # Files (relative to module root)

            '.gitattributes' | Should -BeIn $relativeModulePaths
            '.gitignore' | Should -BeIn $relativeModulePaths
            'CHANGELOG.md' | Should -BeIn $relativeModulePaths
            'CODE_OF_CONDUCT.md' | Should -BeIn $relativeModulePaths
            'GitVersion.yml' | Should -BeIn $relativeModulePaths
            'README.md' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psd1' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psm1' | Should -BeIn $relativeModulePaths
            'source/en-US/about_ModuleDsc.help.txt' | Should -BeIn $relativeModulePaths

            $relativeModulePaths | Should -HaveCount 14
        } -ErrorVariable itBlockError

        # Check if previous It-block failed. If so output the module directory tree.
        if ( $itBlockError.Count -ne 0 )
        {
            $treeOutput = Get-DirectoryTree -Path $mockModuleRootPath

            Write-Verbose -Message ($treeOutput | Out-String) -Verbose
        }
    }

    Context 'When creating a new module project with only the feature ''Gherkin''' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'

            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath      = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
                DestinationPath   = $TestDrive
                SourceDirectory   = 'source'
                NoLogo            = $true
                Force             = $true

                # Template
                ModuleType        = 'CustomModule'

                # Template properties
                ModuleName        = $mockModuleName
                ModuleAuthor      = 'SamplerTestUser'
                ModuleDescription = 'Module description'
                ModuleVersion     = '1.0.0'
                CustomRepo        = 'PSGallery'
                License           = 'false'
                Features          = 'Gherkin' # All,Enums,Classes,DSCResources,SampleScripts,git,Gherkin,UnitTests,ModuleQuality,Build,AppVeyor,TestKitchen
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should have the expected folder and file structure' {
            $modulePaths = Get-ChildItem -Path $mockModuleRootPath -Recurse -Force

            # Make the path relative to module root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockModuleRootPath)

            # Change to slash when testing on Windows.
            $relativeModulePaths = ($relativeModulePaths -replace '\\', '/').TrimStart('/')

            # Folders (relative to module root)

            'source' | Should -BeIn $relativeModulePaths
            'source/en-US' | Should -BeIn $relativeModulePaths
            'source/Examples' | Should -BeIn $relativeModulePaths
            'source/Private' | Should -BeIn $relativeModulePaths
            'source/Public' | Should -BeIn $relativeModulePaths
            'specs' | Should -BeIn $relativeModulePaths
            'specs/steps' | Should -BeIn $relativeModulePaths

            # Files (relative to module root)

            'README.md' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psd1' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psm1' | Should -BeIn $relativeModulePaths
            'source/en-US/about_ModuleDsc.help.txt' | Should -BeIn $relativeModulePaths

            $relativeModulePaths | Should -HaveCount 11
        } -ErrorVariable itBlockError

        # Check if previous It-block failed. If so output the module directory tree.
        if ( $itBlockError.Count -ne 0 )
        {
            $treeOutput = Get-DirectoryTree -Path $mockModuleRootPath

            Write-Verbose -Message ($treeOutput | Out-String) -Verbose
        }
    }

    Context 'When creating a new module project with only the feature ''UnitTests''' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'

            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath      = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
                DestinationPath   = $TestDrive
                SourceDirectory   = 'source'
                NoLogo            = $true
                Force             = $true

                # Template
                ModuleType        = 'CustomModule'

                # Template properties
                ModuleName        = $mockModuleName
                ModuleAuthor      = 'SamplerTestUser'
                ModuleDescription = 'Module description'
                ModuleVersion     = '1.0.0'
                CustomRepo        = 'PSGallery'
                License           = 'false'
                Features          = 'UnitTests' # All,Enums,Classes,DSCResources,SampleScripts,git,Gherkin,UnitTests,ModuleQuality,Build,AppVeyor,TestKitchen
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should have the expected folder and file structure' {
            $modulePaths = Get-ChildItem -Path $mockModuleRootPath -Recurse -Force

            # Make the path relative to module root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockModuleRootPath)

            # Change to slash when testing on Windows.
            $relativeModulePaths = ($relativeModulePaths -replace '\\', '/').TrimStart('/')

            # Folders (relative to module root)

            'source' | Should -BeIn $relativeModulePaths
            'source/en-US' | Should -BeIn $relativeModulePaths
            'source/Examples' | Should -BeIn $relativeModulePaths
            'source/Private' | Should -BeIn $relativeModulePaths
            'source/Public' | Should -BeIn $relativeModulePaths

            # Files (relative to module root)

            'README.md' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psd1' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psm1' | Should -BeIn $relativeModulePaths
            'source/en-US/about_ModuleDsc.help.txt' | Should -BeIn $relativeModulePaths

            $relativeModulePaths | Should -HaveCount 10
        } -ErrorVariable itBlockError

        # Check if previous It-block failed. If so output the module directory tree.
        if ( $itBlockError.Count -ne 0 )
        {
            $treeOutput = Get-DirectoryTree -Path $mockModuleRootPath

            Write-Verbose -Message ($treeOutput | Out-String) -Verbose
        }
    }

    Context 'When creating a new module project with only the feature ''ModuleQuality''' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'

            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath      = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
                DestinationPath   = $TestDrive
                SourceDirectory   = 'source'
                NoLogo            = $true
                Force             = $true

                # Template
                ModuleType        = 'CustomModule'

                # Template properties
                ModuleName        = $mockModuleName
                ModuleAuthor      = 'SamplerTestUser'
                ModuleDescription = 'Module description'
                ModuleVersion     = '1.0.0'
                CustomRepo        = 'PSGallery'
                License           = 'false'
                Features          = 'ModuleQuality' # All,Enums,Classes,DSCResources,SampleScripts,git,Gherkin,UnitTests,ModuleQuality,Build,AppVeyor,TestKitchen
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should have the expected folder and file structure' {
            $modulePaths = Get-ChildItem -Path $mockModuleRootPath -Recurse -Force

            # Make the path relative to module root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockModuleRootPath)

            # Change to slash when testing on Windows.
            $relativeModulePaths = ($relativeModulePaths -replace '\\', '/').TrimStart('/')

            # Folders (relative to module root)

            'source' | Should -BeIn $relativeModulePaths
            'source/en-US' | Should -BeIn $relativeModulePaths
            'source/Examples' | Should -BeIn $relativeModulePaths
            'source/Private' | Should -BeIn $relativeModulePaths
            'source/Public' | Should -BeIn $relativeModulePaths
            'tests' | Should -BeIn $relativeModulePaths
            'tests/QA' | Should -BeIn $relativeModulePaths

            # Files (relative to module root)

            'README.md' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psd1' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psm1' | Should -BeIn $relativeModulePaths
            'source/en-US/about_ModuleDsc.help.txt' | Should -BeIn $relativeModulePaths
            'tests/QA/module.tests.ps1' | Should -BeIn $relativeModulePaths

            $relativeModulePaths | Should -HaveCount 12
        } -ErrorVariable itBlockError

        # Check if previous It-block failed. If so output the module directory tree.
        if ( $itBlockError.Count -ne 0 )
        {
            $treeOutput = Get-DirectoryTree -Path $mockModuleRootPath

            Write-Verbose -Message ($treeOutput | Out-String) -Verbose
        }
    }

    Context 'When creating a new module project with only the feature ''Build''' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'

            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath      = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
                DestinationPath   = $TestDrive
                SourceDirectory   = 'source'
                NoLogo            = $true
                Force             = $true

                # Template
                ModuleType        = 'CustomModule'

                # Template properties
                ModuleName        = $mockModuleName
                ModuleAuthor      = 'SamplerTestUser'
                ModuleDescription = 'Module description'
                ModuleVersion     = '1.0.0'
                CustomRepo        = 'PSGallery'
                License           = 'false'
                Features          = 'Build' # All,Enums,Classes,DSCResources,SampleScripts,git,Gherkin,UnitTests,ModuleQuality,Build,AppVeyor,TestKitchen
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should have the expected folder and file structure' {
            $modulePaths = Get-ChildItem -Path $mockModuleRootPath -Recurse -Force

            # Make the path relative to module root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockModuleRootPath)

            # Change to slash when testing on Windows.
            $relativeModulePaths = ($relativeModulePaths -replace '\\', '/').TrimStart('/')

            # Folders (relative to module root)

            'source' | Should -BeIn $relativeModulePaths
            'source/en-US' | Should -BeIn $relativeModulePaths
            'source/Examples' | Should -BeIn $relativeModulePaths
            'source/Private' | Should -BeIn $relativeModulePaths
            'source/Public' | Should -BeIn $relativeModulePaths

            # Files (relative to module root)

            'build.ps1' | Should -BeIn $relativeModulePaths
            'build.yaml' | Should -BeIn $relativeModulePaths
            'README.md' | Should -BeIn $relativeModulePaths
            'RequiredModules.psd1' | Should -BeIn $relativeModulePaths
            'Resolve-Dependency.ps1' | Should -BeIn $relativeModulePaths
            'Resolve-Dependency.psd1' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psd1' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psm1' | Should -BeIn $relativeModulePaths
            'source/en-US/about_ModuleDsc.help.txt' | Should -BeIn $relativeModulePaths

            $relativeModulePaths | Should -HaveCount 14
        } -ErrorVariable itBlockError

        # Check if previous It-block failed. If so output the module directory tree.
        if ( $itBlockError.Count -ne 0 )
        {
            $treeOutput = Get-DirectoryTree -Path $mockModuleRootPath

            Write-Verbose -Message ($treeOutput | Out-String) -Verbose
        }
    }

    Context 'When creating a new module project with only the feature ''AppVeyor''' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'

            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath      = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
                DestinationPath   = $TestDrive
                SourceDirectory   = 'source'
                NoLogo            = $true
                Force             = $true

                # Template
                ModuleType        = 'CustomModule'

                # Template properties
                ModuleName        = $mockModuleName
                ModuleAuthor      = 'SamplerTestUser'
                ModuleDescription = 'Module description'
                ModuleVersion     = '1.0.0'
                CustomRepo        = 'PSGallery'
                License           = 'false'
                Features          = 'AppVeyor' # All,Enums,Classes,DSCResources,SampleScripts,git,Gherkin,UnitTests,ModuleQuality,Build,AppVeyor,TestKitchen
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should have the expected folder and file structure' {
            $modulePaths = Get-ChildItem -Path $mockModuleRootPath -Recurse -Force

            # Make the path relative to module root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockModuleRootPath)

            # Change to slash when testing on Windows.
            $relativeModulePaths = ($relativeModulePaths -replace '\\', '/').TrimStart('/')

            # Folders (relative to module root)

            'source' | Should -BeIn $relativeModulePaths
            'source/en-US' | Should -BeIn $relativeModulePaths
            'source/Examples' | Should -BeIn $relativeModulePaths
            'source/Private' | Should -BeIn $relativeModulePaths
            'source/Public' | Should -BeIn $relativeModulePaths

            # Files (relative to module root)

            'appveyor.yml' | Should -BeIn $relativeModulePaths
            'README.md' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psd1' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psm1' | Should -BeIn $relativeModulePaths
            'source/en-US/about_ModuleDsc.help.txt' | Should -BeIn $relativeModulePaths

            $relativeModulePaths | Should -HaveCount 10
        } -ErrorVariable itBlockError

        # Check if previous It-block failed. If so output the module directory tree.
        if ( $itBlockError.Count -ne 0 )
        {
            $treeOutput = Get-DirectoryTree -Path $mockModuleRootPath

            Write-Verbose -Message ($treeOutput | Out-String) -Verbose
        }
    }

    Context 'When creating a new module project with only the feature ''TestKitchen''' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'

            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath      = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
                DestinationPath   = $TestDrive
                SourceDirectory   = 'source'
                NoLogo            = $true
                Force             = $true

                # Template
                ModuleType        = 'CustomModule'

                # Template properties
                ModuleName        = $mockModuleName
                ModuleAuthor      = 'SamplerTestUser'
                ModuleDescription = 'Module description'
                ModuleVersion     = '1.0.0'
                CustomRepo        = 'PSGallery'
                License           = 'false'
                Features          = 'TestKitchen' # All,Enums,Classes,DSCResources,SampleScripts,git,Gherkin,UnitTests,ModuleQuality,Build,AppVeyor,TestKitchen
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should have the expected folder and file structure' {
            $modulePaths = Get-ChildItem -Path $mockModuleRootPath -Recurse -Force

            # Make the path relative to module root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockModuleRootPath)

            # Change to slash when testing on Windows.
            $relativeModulePaths = ($relativeModulePaths -replace '\\', '/').TrimStart('/')

            # Folders (relative to module root)

            'source' | Should -BeIn $relativeModulePaths
            'source/en-US' | Should -BeIn $relativeModulePaths
            'source/Examples' | Should -BeIn $relativeModulePaths
            'source/Private' | Should -BeIn $relativeModulePaths
            'source/Public' | Should -BeIn $relativeModulePaths
            'tests' | Should -BeIn $relativeModulePaths

            # Files (relative to module root)

            '.kitchen.yml' | Should -BeIn $relativeModulePaths
            'README.md' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psd1' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psm1' | Should -BeIn $relativeModulePaths
            'source/en-US/about_ModuleDsc.help.txt' | Should -BeIn $relativeModulePaths

            $relativeModulePaths | Should -HaveCount 11
        } -ErrorVariable itBlockError

        # Check if previous It-block failed. If so output the module directory tree.
        if ( $itBlockError.Count -ne 0 )
        {
            $treeOutput = Get-DirectoryTree -Path $mockModuleRootPath

            Write-Verbose -Message ($treeOutput | Out-String) -Verbose
        }
    }
}
