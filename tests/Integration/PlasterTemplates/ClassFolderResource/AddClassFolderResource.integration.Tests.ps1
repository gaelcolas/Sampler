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

Describe 'DSC Composite resource Plaster Template' {
    Context 'When creating a new composite' {
        BeforeAll {
            $mockModuleRootPath = $TestDrive

            $listOfExpectedFilesAndFolders = @(
                # Folders (relative to module root)
                'source'
                'source/Enum'
                'source/Classes'
                'source/Private'
                'source/en-US'
                'tests'
                'tests/Unit'
                'tests/Unit/Classes'
                'tests/Unit/Private'

                # Files (relative to module root)
                'source/Enum/1.Ensure.ps1'
                'source/Classes/Reason.ps1'
                'source/Classes/DSC_ClassFolder.ps1'
                'source/Private/ConvertTo-HashtableFromObject.ps1'
                'source/Private/Set-FileAttribute.ps1'
                'source/Private/Test-FileAttribute.ps1'
                'source/en-US/DSC_ClassFolder.strings.psd1'

                'tests/Unit/Classes/DSC_ClassFolder.tests.ps1'
                'tests/Unit/Private/ConvertTo-HashtableFromObject.tests.ps1'
                'tests/Unit/Private/Set-FileAttribute.tests.ps1'
                'tests/Unit/Private/Test-FileAttribute.tests.ps1'
            )
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath      = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/ClassFolderResource'
                DestinationPath   = $testdrive
                NoLogo            = $true
                Force             = $true

                # Template properties
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
