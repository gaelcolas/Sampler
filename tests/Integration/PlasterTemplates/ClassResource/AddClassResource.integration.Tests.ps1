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

Describe 'DSC Composite resource Plaster Template' {
    Context 'When creating a new composite' {
        BeforeAll {
            $mockResourceName  = 'MyDscClassResource'
            $mockModuleRootPath = $TestDrive

            $listOfExpectedFilesAndFolders = @(
                # Folders (relative to module root)
                'source'
                'source/Classes'
                'source/Enum'

                # Files (relative to module root)
                'source/Enum/1.Ensure.ps1'
                'source/Classes/Reason.ps1'
                'source/Classes/DSC_MyDscClassResource.ps1'
            )
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath      = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/ClassResource'
                DestinationPath   = $testdrive
                NoLogo            = $true
                Force             = $true

                # Template properties
                ResourceName     = $mockResourceName
                SourceDirectory   = 'source'
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
