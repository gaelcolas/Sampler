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

Describe 'DSC Community Plaster Template' {
    Context 'When creating a new module project' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'
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
            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName

            $modulePaths = Get-ChildItem -Path $mockModuleRootPath -Recurse

            # Make the path relative to module root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockModuleRootPath)

            # Change to slash when testing on Windows.
            $relativeModulePaths = ($relativeModulePaths -replace '\\', '/').TrimStart('/')

            # Folders (relative to module root)

            '.vscode' | Should -BeIn $relativeModulePaths
            'source' | Should -BeIn $relativeModulePaths
            'source/en-US' | Should -BeIn $relativeModulePaths
            'tests' | Should -BeIn $relativeModulePaths
            'output' | Should -BeIn $relativeModulePaths
            'output/RequiredModules' | Should -BeIn $relativeModulePaths

            # Files (relative to module root)

            '.gitattributes' | Should -BeIn $relativeModulePaths
            '.gitignore' | Should -BeIn $relativeModulePaths
            '.markdownlint.json' | Should -BeIn $relativeModulePaths
            'azure-pipelines.yml' | Should -BeIn $relativeModulePaths
            'build.ps1' | Should -BeIn $relativeModulePaths
            'build.yaml' | Should -BeIn $relativeModulePaths
            'CODE_OF_CONDUCT.md' | Should -BeIn $relativeModulePaths
            'CONTRIBUTING.md' | Should -BeIn $relativeModulePaths
            'GitVersion.yml' | Should -BeIn $relativeModulePaths
            'RequiredModules.psd1' | Should -BeIn $relativeModulePaths
            'Resolve-Dependency.ps1' | Should -BeIn $relativeModulePaths
            'Resolve-Dependency.psd1' | Should -BeIn $relativeModulePaths
            '.vscode/analyzersettings.psd1' | Should -BeIn $relativeModulePaths
            '.vscode/settings.json' | Should -BeIn $relativeModulePaths
            '.vscode/tasks.json' | Should -BeIn $relativeModulePaths
            'source/en-US/about_ModuleDsc.help.txt' | Should -BeIn $relativeModulePaths

            $relativeModulePaths | Should -HaveCount 22
        } -ErrorVariable itBlockError

        # Check if previous It-block failed. If so output the module directory tree.
        if ( $itBlockError.Count -ne 0 )
        {
            Write-Verbose -Message (tree /f $mockModuleRootPath | Out-String) -Verbose
        }
    }
}
