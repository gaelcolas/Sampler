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

Describe 'DSC Community Plaster Template' {
    Context 'When creating a new module project' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'
            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName

            $listOfExpectedFilesAndFolders = @(
                # Folders (relative to module root)

                '.github'
                '.vscode'
                'source'
                'source/en-US'
                'source/WikiSource'
                'tests'
                'output'
                'output/RequiredModules'

                # Files (relative to module root)

                '.gitattributes'
                '.github/ISSUE_TEMPLATE'
                '.github/PULL_REQUEST_TEMPLATE.md'
                '.github/ISSUE_TEMPLATE/General.md'
                '.github/ISSUE_TEMPLATE/Problem_with_resource.md'
                '.github/ISSUE_TEMPLATE/Resource_proposal.md'
                '.gitignore'
                '.markdownlint.json'
                'azure-pipelines.yml'
                'build.ps1'
                'build.yaml'
                'CHANGELOG.md'
                'CODE_OF_CONDUCT.md'
                'SECURITY.md'
                'LICENSE'
                'codecov.yml'
                'CONTRIBUTING.md'
                'GitVersion.yml'
                'RequiredModules.psd1'
                'Resolve-Dependency.ps1'
                'Resolve-Dependency.psd1'
                '.vscode/analyzersettings.psd1'
                '.vscode/settings.json'
                '.vscode/tasks.json'
                'source/en-US/about_ModuleDsc.help.txt'
            )
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath    = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
                DestinationPath = $TestDrive
                SourceDirectory = 'source'
                NoLogo          = $true
                Force           = $true

                # Template
                ModuleType      = 'dsccommunity'

                # Template properties
                ModuleName      = $mockModuleName
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
