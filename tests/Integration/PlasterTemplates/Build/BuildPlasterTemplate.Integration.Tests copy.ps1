#region HEADER
$script:projectPath = "$PSScriptRoot\..\..\..\.." | Convert-Path
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

Import-Module -Name "$PSScriptRoot\..\..\IntegrationTestHelpers.psm1"

Install-TreeCommand

Describe 'Build Pipeline Plaster Template' {
    Context 'When creating a new pipeline project' {
        BeforeAll {
            $mockProjectName = 'BuildPipeline'
            $mockProjectRootPath = Join-Path -Path $TestDrive -ChildPath $mockProjectName

            $listOfExpectedFilesAndFolders = @(
                # Folders (relative to module root)

                '.github'
                '.vscode'
                'source'
                'tests'
                'source/WikiSource'
                'output'
                'output/RequiredModules'

                # Files (relative to module root)
                '.gitattributes'
                '.github/ISSUE_TEMPLATE'
                '.github/PULL_REQUEST_TEMPLATE.md'
                '.github/ISSUE_TEMPLATE/config.yml'
                '.github/ISSUE_TEMPLATE/General.md'
                '.github/ISSUE_TEMPLATE/Problem_with_module.yml'
                '.gitignore'
                'azure-pipelines.yml'
                'build.ps1'
                'build.yaml'
                'CHANGELOG.md'
                'CODE_OF_CONDUCT.md'
                'CONTRIBUTING.md'
                'GitVersion.yml'
                'LICENSE'
                'README.md'
                'RequiredModules.psd1'
                'Resolve-Dependency.ps1'
                'Resolve-Dependency.psd1'
                'SECURITY.md'
                '.vscode/analyzersettings.psd1'
                '.vscode/settings.json'
                '.vscode/tasks.json'
            )
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath    = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Build'
                DestinationPath = $TestDrive
                SourceDirectory = 'source'
                NoLogo          = $true
                Force           = $true

                # Template properties
                ProjectName        = $mockProjectName
                ModuleDescription = 'Mock Project Description'
                CustomRepo        = 'PSGallery'
                MainGitBranch     = 'main'
                Features          = 'All'
                License           = 'true'
                LicenseType       = 'MIT'
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should have the expected folder and file structure' {
            $modulePaths = Get-ChildItem -Path $mockProjectRootPath -Recurse -Force

            # Make the path relative to module root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockProjectRootPath)

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
                $treeOutput = Get-DirectoryTree -Path $mockProjectRootPath
                Write-Verbose -Message ($treeOutput | Out-String) -Verbose
            }

            $TreeStructureIsOk | Should -BeTrue -Because $report
        }
    }
}
