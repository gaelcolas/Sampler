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

Describe 'Copilot Plaster Template' {
    Context 'When scaffolding without optional features' {
        BeforeAll {
            $mockDestinationPath = Join-Path -Path $TestDrive -ChildPath 'copilot-basic'

            $null = New-Item -ItemType Directory -Path $mockDestinationPath -Force

            $listOfExpectedFilesAndFolders = @(
                # Folders
                '.github'
                '.github/instructions'
                '.github/skills'
                '.github/skills/validate-changes'

                # Files
                '.github/copilot-instructions.md'
                '.github/instructions/ai-instruction-authoring.instructions.md'
                '.github/instructions/public-functions.instructions.md'
                '.github/instructions/private-functions.instructions.md'
                '.github/instructions/test-writing.instructions.md'
                '.github/instructions/build-tasks.instructions.md'
                '.github/skills/validate-changes/SKILL.md'
            )

            $listOfAbsentFiles = @(
                '.github/instructions/classes-and-type-accelerators.instructions.md'
                '.github/instructions/build-task-files.instructions.md'
                '.github/instructions/wiki-publishing.instructions.md'
            )
        }

        It 'Should scaffold Copilot files without throwing' {
            $invokePlasterParameters = @{
                TemplatePath        = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Copilot'
                DestinationPath     = $mockDestinationPath
                NoLogo              = $true
                Force               = $true
                ModuleName          = 'TestModule'
                SourceDirectory     = 'source'
                HasClasses          = 'false'
                HasCustomBuildTasks = 'false'
                HasWikiSource       = 'false'
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should have the expected folder and file structure' {
            $modulePaths = Get-ChildItem -Path $mockDestinationPath -Recurse -Force

            # Make the path relative to destination root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockDestinationPath)

            # Change to slash when testing on Windows.
            $relativeModulePaths = ($relativeModulePaths -replace '\\', '/').TrimStart('/')

            # Check files and folders for discrepancies.
            $missingFilesOrFolders   = $listOfExpectedFilesAndFolders.Where{ $_ -notin $relativeModulePaths }
            $unexpectedFilesOrFolders = $relativeModulePaths.Where{ $_ -notin $listOfExpectedFilesAndFolders }
            $treeStructureIsOk = ($missingFilesOrFolders.Count -eq 0 -and $unexpectedFilesOrFolders.Count -eq 0)

            # Format the report to be used in Because.
            $report = ":`r`n  Missing:`r`n`t$($missingFilesOrFolders -join "`r`n`t")`r`n  Unexpected:`r`n`t$($unexpectedFilesOrFolders -join "`r`n`t")`r`n."

            if (-not $treeStructureIsOk)
            {
                $treeOutput = Get-DirectoryTree -Path $mockDestinationPath
                Write-Verbose -Message ($treeOutput | Out-String) -Verbose
            }

            $treeStructureIsOk | Should -BeTrue -Because $report
        }

        It 'Should not scaffold optional files when all optional features are disabled' {
            foreach ($absentFile in $listOfAbsentFiles)
            {
                $fullPath = Join-Path -Path $mockDestinationPath -ChildPath ($absentFile -replace '/', [System.IO.Path]::DirectorySeparatorChar)
                $fullPath | Should -Not -Exist -Because "Optional file '$absentFile' should not exist when the feature is disabled"
            }
        }

        It 'Should substitute the module name in copilot-instructions.md' {
            $filePath = Join-Path -Path $mockDestinationPath -ChildPath '.github'
            $filePath = Join-Path -Path $filePath -ChildPath 'copilot-instructions.md'
            $content  = Get-Content -Path $filePath -Raw
            $content | Should -Match 'TestModule'
        }

        It 'Should substitute the source directory in public-functions.instructions.md' {
            $filePath = Join-Path -Path $mockDestinationPath -ChildPath '.github'
            $filePath = Join-Path -Path $filePath -ChildPath 'instructions'
            $filePath = Join-Path -Path $filePath -ChildPath 'public-functions.instructions.md'
            $content  = Get-Content -Path $filePath -Raw
            $content | Should -Match 'source/Public'
        }
    }

    Context 'When scaffolding with HasClasses enabled' {
        BeforeAll {
            $mockDestinationPath = Join-Path -Path $TestDrive -ChildPath 'copilot-classes'

            $null = New-Item -ItemType Directory -Path $mockDestinationPath -Force
        }

        It 'Should scaffold with HasClasses without throwing' {
            $invokePlasterParameters = @{
                TemplatePath        = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Copilot'
                DestinationPath     = $mockDestinationPath
                NoLogo              = $true
                Force               = $true
                ModuleName          = 'TestModule'
                SourceDirectory     = 'source'
                HasClasses          = 'true'
                HasCustomBuildTasks = 'false'
                HasWikiSource       = 'false'
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should create the classes instructions file' {
            $filePath = Join-Path -Path $mockDestinationPath -ChildPath '.github'
            $filePath = Join-Path -Path $filePath -ChildPath 'instructions'
            $filePath = Join-Path -Path $filePath -ChildPath 'classes-and-type-accelerators.instructions.md'
            $filePath | Should -Exist
        }

        It 'Should substitute the source directory in the classes instructions file' {
            $filePath = Join-Path -Path $mockDestinationPath -ChildPath '.github'
            $filePath = Join-Path -Path $filePath -ChildPath 'instructions'
            $filePath = Join-Path -Path $filePath -ChildPath 'classes-and-type-accelerators.instructions.md'
            $content  = Get-Content -Path $filePath -Raw
            $content | Should -Match 'source'
        }
    }

    Context 'When scaffolding with HasCustomBuildTasks enabled' {
        BeforeAll {
            $mockDestinationPath = Join-Path -Path $TestDrive -ChildPath 'copilot-buildtasks'

            $null = New-Item -ItemType Directory -Path $mockDestinationPath -Force
        }

        It 'Should scaffold with HasCustomBuildTasks without throwing' {
            $invokePlasterParameters = @{
                TemplatePath        = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Copilot'
                DestinationPath     = $mockDestinationPath
                NoLogo              = $true
                Force               = $true
                ModuleName          = 'TestModule'
                SourceDirectory     = 'source'
                HasClasses          = 'false'
                HasCustomBuildTasks = 'true'
                HasWikiSource       = 'false'
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should create the build-task-files instructions file' {
            $filePath = Join-Path -Path $mockDestinationPath -ChildPath '.github'
            $filePath = Join-Path -Path $filePath -ChildPath 'instructions'
            $filePath = Join-Path -Path $filePath -ChildPath 'build-task-files.instructions.md'
            $filePath | Should -Exist
        }
    }

    Context 'When scaffolding with HasWikiSource enabled' {
        BeforeAll {
            $mockDestinationPath = Join-Path -Path $TestDrive -ChildPath 'copilot-wiki'

            $null = New-Item -ItemType Directory -Path $mockDestinationPath -Force
        }

        It 'Should scaffold with HasWikiSource without throwing' {
            $invokePlasterParameters = @{
                TemplatePath        = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Copilot'
                DestinationPath     = $mockDestinationPath
                NoLogo              = $true
                Force               = $true
                ModuleName          = 'TestModule'
                SourceDirectory     = 'source'
                HasClasses          = 'false'
                HasCustomBuildTasks = 'false'
                HasWikiSource       = 'true'
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should create the wiki-publishing instructions file' {
            $filePath = Join-Path -Path $mockDestinationPath -ChildPath '.github'
            $filePath = Join-Path -Path $filePath -ChildPath 'instructions'
            $filePath = Join-Path -Path $filePath -ChildPath 'wiki-publishing.instructions.md'
            $filePath | Should -Exist
        }

        It 'Should substitute the source directory in the wiki-publishing instructions file' {
            $filePath = Join-Path -Path $mockDestinationPath -ChildPath '.github'
            $filePath = Join-Path -Path $filePath -ChildPath 'instructions'
            $filePath = Join-Path -Path $filePath -ChildPath 'wiki-publishing.instructions.md'
            $content  = Get-Content -Path $filePath -Raw
            $content | Should -Match 'source/WikiSource'
        }
    }
}
