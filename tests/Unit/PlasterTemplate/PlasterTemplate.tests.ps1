$here = $PSScriptRoot
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

$ProjectPath = "$here\..\..\.." | Convert-Path
$ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch{$false}) }
    ).BaseName


Describe 'Plaster Templates creates a complete Module scaffolding' {
    Import-Module Sampler
    $ModuleName = 'testMod'
    $testPath = "TestDrive:\"
    $TemplatePath = Join-Path (Get-Module Sampler).ModuleBase 'PlasterTemplate'
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
    }
    Invoke-plaster @PlasterParams

    $FileList = @(
         @{fileName = "testDrive:\$ModuleName\tests\Unit\Classes\class1.tests.ps1"}
        ,@{fileName = "testDrive:\$ModuleName\tests\Unit\Classes\class11.tests.ps1"}
        ,@{fileName = "testDrive:\$ModuleName\tests\Unit\Classes\class12.tests.ps1"}
        ,@{fileName = "testDrive:\$ModuleName\tests\Unit\Classes\class2.tests.ps1"}
        ,@{fileName = "testDrive:\$ModuleName\tests\Unit\Private\Get-PrivateFunction.tests.ps1"}
        ,@{fileName = "testDrive:\$ModuleName\tests\Unit\Public\Get-Something.tests.ps1"}
        ,@{fileName = "testDrive:\$ModuleName\tests\QA\module.tests.ps1"}
        ,@{fileName = "testDrive:\$ModuleName\Source\Public\Get-Something.ps1"}
        ,@{fileName = "testDrive:\$ModuleName\Source\Private\Get-PrivateFunction.ps1"}
        ,@{fileName = "testDrive:\$ModuleName\Source\Classes\1.class1.ps1"}
        ,@{fileName = "testDrive:\$ModuleName\Source\Classes\2.class2.ps1"}
        ,@{fileName = "testDrive:\$ModuleName\Source\Classes\3.class11.ps1"}
        ,@{fileName = "testDrive:\$ModuleName\Source\Classes\4.class12.ps1"}
        ,@{fileName = "testDrive:\$ModuleName\.gitignore"}
        ,@{fileName = "testDrive:\$ModuleName\.gitattributes"}
        ,@{fileName = "testDrive:\$ModuleName\.kitchen.yml"}
        ,@{fileName = "testDrive:\$ModuleName\Deploy.PSDeploy.ps1"}
        ,@{fileName = "testDrive:\$ModuleName\build.ps1"}
        ,@{fileName = "testDrive:\$ModuleName\RequiredModules.psd1"}
        ,@{fileName = "testDrive:\$ModuleName\Resolve-Dependency.ps1"}
        ,@{fileName = "testDrive:\$ModuleName\Resolve-Dependency.psd1"}
        ,@{fileName = "testDrive:\$ModuleName\build.yaml"}
        ,@{fileName = "testDrive:\$ModuleName\Source\Build.psd1"}
        ,@{fileName = "testDrive:\$ModuleName\azure-pipelines.yml"}
        ,@{fileName = "testDrive:\$ModuleName\Source\$ModuleName.psd1"}
        ,@{fileName = "testDrive:\$ModuleName\README.md"}
        ,@{fileName = "testDrive:\$ModuleName\Source\en-US\about_$ModuleName.help.txt"}
        ,@{fileName = "testDrive:\$ModuleName\.vscode\"}
        ,@{fileName = "testDrive:\$ModuleName\.github\"}
        ,@{fileName = "testDrive:\$ModuleName\CONTRIBUTING.md"}
        ,@{fileName = "testDrive:\$ModuleName\CODE_OF_CONDUCT.md"}
        ,@{fileName = "testDrive:\$ModuleName\.markdownlint.json"}
        ,@{fileName = "testDrive:\$ModuleName\GitVersion.yml"}
    )
    It 'Should have created file <fileName>' -TestCases $FileList {
        param($fileName)

        Test-Path $fileName | Should -Be $true
    }

}
