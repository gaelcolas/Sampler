$here = $PSScriptRoot

$ProjectPath = "$here\..\..\.." | Convert-Path
$ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch{$false}) }
    ).BaseName


Describe 'Plaster Templates creates a complete Module scaffolding' {
    try {
        $module = Import-Module Sampler -PassThru
        $ModuleName = 'testMod'
        $testPath = "TestDrive:\"
        $TemplatePath = Join-Path $module.ModuleBase 'Templates/Sampler'
        $PlasterParams = @{
            NoLogo            = $true
            TemplatePath      = $TemplatePath
            DestinationPath   = $testPath
            ModuleType        = 'CompleteModule'
            ModuleAuthor      = 'gaelcolas'
            ModuleDescription = 'testing template'
            moduleName        = $ModuleName
            ModuleVersion     = '0.0.1'
            SourceDirectory   = 'Source'
            CustomRepo        = 'Modules'
        }
        Invoke-plaster @PlasterParams
    }
    catch {
        Write-Warning "ERROR: $_"
    }


    $FileList = @(
        @{fileName = "TestDrive:\$ModuleName\tests\Unit\Classes\class1.tests.ps1" }
        ,@{fileName = "TestDrive:\$ModuleName\tests\Unit\Classes\class11.tests.ps1"}
        ,@{fileName = "TestDrive:\$ModuleName\tests\Unit\Classes\class12.tests.ps1"}
        ,@{fileName = "TestDrive:\$ModuleName\tests\Unit\Classes\class2.tests.ps1"}
        ,@{fileName = "TestDrive:\$ModuleName\tests\Unit\Private\Get-PrivateFunction.tests.ps1"}
        ,@{fileName = "TestDrive:\$ModuleName\tests\Unit\Public\Get-Something.tests.ps1"}
        ,@{fileName = "TestDrive:\$ModuleName\tests\QA\module.tests.ps1"}
        ,@{fileName = "TestDrive:\$ModuleName\Source\Public\Get-Something.ps1"}
        ,@{fileName = "TestDrive:\$ModuleName\Source\Private\Get-PrivateFunction.ps1"}
        ,@{fileName = "TestDrive:\$ModuleName\Source\Classes\1.class1.ps1"}
        ,@{fileName = "TestDrive:\$ModuleName\Source\Classes\2.class2.ps1"}
        ,@{fileName = "TestDrive:\$ModuleName\Source\Classes\3.class11.ps1"}
        ,@{fileName = "TestDrive:\$ModuleName\Source\Classes\4.class12.ps1"}
        ,@{fileName = "TestDrive:\$ModuleName\.gitignore"}
        ,@{fileName = "TestDrive:\$ModuleName\.gitattributes"}
        ,@{fileName = "TestDrive:\$ModuleName\.kitchen.yml"}
        ,@{fileName = "TestDrive:\$ModuleName\build.ps1"}
        ,@{fileName = "TestDrive:\$ModuleName\RequiredModules.psd1"}
        ,@{fileName = "TestDrive:\$ModuleName\Resolve-Dependency.ps1"}
        ,@{fileName = "TestDrive:\$ModuleName\Resolve-Dependency.psd1"}
        ,@{fileName = "TestDrive:\$ModuleName\build.yaml"}
        ,@{fileName = "TestDrive:\$ModuleName\Source\Build.psd1"}
        ,@{fileName = "TestDrive:\$ModuleName\azure-pipelines.yml"}
        ,@{fileName = "TestDrive:\$ModuleName\Source\$ModuleName.psd1"}
        ,@{fileName = "TestDrive:\$ModuleName\README.md"}
        ,@{fileName = "TestDrive:\$ModuleName\Source\en-US\about_$ModuleName.help.txt"}
        ,@{fileName = "TestDrive:\$ModuleName\.vscode\"}
        ,@{fileName = "TestDrive:\$ModuleName\.github\"}
        ,@{fileName = "TestDrive:\$ModuleName\CONTRIBUTING.md"}
        ,@{fileName = "TestDrive:\$ModuleName\CHANGELOG.md"}
        ,@{fileName = "TestDrive:\$ModuleName\CODE_OF_CONDUCT.md"}
        ,@{fileName = "TestDrive:\$ModuleName\.markdownlint.json"}
        ,@{fileName = "TestDrive:\$ModuleName\GitVersion.yml"}
    )

    It 'Should have created file <fileName>' -TestCases $FileList {
        param($fileName)

        # Careful on Linux PS7+, FS is case sensitive
        Test-Path $fileName -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}
