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

Describe 'TypeAccelerators Plaster Template' {
    Context 'When adding a suffix.ps1 exporting type accelerators' {
        BeforeAll {
            $mockModuleRootPath = $TestDrive

            $listOfExpectedFilesAndFolders = @(
                # Folders (relative to module root)
                'source'

                # Files (relative to module root)
                'source/suffix.ps1'
            )
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath      = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/TypeAccelerators'
                DestinationPath   = $testdrive
                NoLogo            = $true
                Force             = $true

                # Template properties
                SourceDirectory    = 'source'
                ExportableTypeName = 'MyClass'
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

        It 'Should generate a suffix.ps1 that references the requested exportable type' {
            $suffixContent = Get-Content -Path (Join-Path -Path $mockModuleRootPath -ChildPath 'source/suffix.ps1') -Raw

            $suffixContent | Should -Match ([RegEx]::Escape("'MyClass'"))
        }

        It 'Should brute-force override an existing type accelerator of the same name without throwing' {
            $overrideModuleRoot = Join-Path -Path $TestDrive -ChildPath 'OverrideCheck'

            $invokePlasterParameters = @{
                TemplatePath      = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/TypeAccelerators'
                DestinationPath   = $overrideModuleRoot
                NoLogo            = $true
                Force             = $true

                SourceDirectory    = 'source'
                ExportableTypeName = 'MyClass'
            }

            $null = Invoke-Plaster @invokePlasterParameters

            $typeAcceleratorsClass = [psobject].Assembly.GetType('System.Management.Automation.TypeAccelerators')

            # suffix.ps1 is designed to be merged onto the end of a module's root script,
            # after its Classes are declared, and relies on
            # $MyInvocation.MyCommand.ScriptBlock.Module - which is only populated when the
            # script is loaded as a real module file via Import-Module (not when dot-sourced
            # or run through New-Module -ScriptBlock). Build a throwaway module that declares
            # the same class the scaffolded suffix.ps1 exports, followed by the generated
            # suffix.ps1 content, so it is imported the same way ModuleBuilder's merged
            # output would be.
            $overrideCheckModuleName = 'SamplerTypeAcceleratorOverrideCheck'
            $overrideCheckModulePath = Join-Path -Path $TestDrive -ChildPath "$overrideCheckModuleName\$overrideCheckModuleName.psm1"
            $null = New-Item -Path (Split-Path -Path $overrideCheckModulePath -Parent) -ItemType Directory -Force

            $suffixContent = Get-Content -Path (Join-Path -Path $overrideModuleRoot -ChildPath 'source/suffix.ps1') -Raw
            $classDeclaration = "class MyClass { [string] `$Marker = 'current' }`n`n"
            Set-Content -Path $overrideCheckModulePath -Value ($classDeclaration + $suffixContent)

            $qualifiedAcceleratorName = '{0}.MyClass' -f $overrideCheckModuleName

            # Register an unrelated type under the accelerator name the suffix.ps1 will
            # manage, simulating a stale/colliding registration (for example left behind by
            # a previous -Force re-import of this same module during development).
            $null = $typeAcceleratorsClass::Add($qualifiedAcceleratorName, [System.Int32])

            try
            {
                $overrideCheckModule = $null

                {
                    $overrideCheckModule = Import-Module -Name $overrideCheckModulePath -PassThru -Force
                } | Should -Not -Throw

                ($typeAcceleratorsClass::Get)[$qualifiedAcceleratorName].FullName | Should -Be 'MyClass'
            }
            finally
            {
                if ($overrideCheckModule)
                {
                    Remove-Module -ModuleInfo $overrideCheckModule -ErrorAction 'SilentlyContinue'
                }

                $null = $typeAcceleratorsClass::Remove($qualifiedAcceleratorName)
            }
        }
    }
}
