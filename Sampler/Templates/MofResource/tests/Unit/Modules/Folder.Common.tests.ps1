#region HEADER
$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch{$false}) }
    ).BaseName

$script:ParentModule = Get-Module $ProjectName -ListAvailable | Select-Object -First 1
$script:SubModulesFolder = Join-Path -Path $script:ParentModule.ModuleBase -ChildPath 'Modules'
Remove-Module $script:ParentModule -Force -ErrorAction SilentlyContinue

$script:SubModuleName = (Split-Path $PSCommandPath -Leaf) -replace '\.Tests.ps1'
Remove-Module $script:SubModuleName -force -ErrorAction SilentlyContinue
$script:SubmoduleFile = Join-Path $script:SubModulesFolder "$($script:SubModuleName)/$($script:SubModuleName).psm1"

#endregion HEADER

Import-Module $script:SubmoduleFile -Force -ErrorAction Stop

InModuleScope $Script:SubModuleName {

    Describe 'FolderCommon\Test-FileAttribute' -Tag 'Helper' {
        BeforeAll {
            $mockAttribute = 'ReadOnly'
            $script:mockFolderObjectPath = Join-Path -Path $TestDrive -ChildPath 'FolderTest'
            $script:mockFolderObject = New-Item -Path $script:mockFolderObjectPath -ItemType 'Directory' -Force
            $script:mockFolderObject.Attributes = [System.IO.FileAttributes]::$mockAttribute
        }

        Context 'When a folder has a specific attribute' {
            It 'Should return $true' {
                $testFileAttributeResult = Test-FileAttribute -Folder $script:mockFolderObject -Attribute $mockAttribute
                $testFileAttributeResult | Should -Be $true
            }
        }

        Context 'When a folder does not have a specific attribute' {
            It 'Should return $false' {
                $testFileAttributeResult = Test-FileAttribute -Folder $script:mockFolderObject -Attribute 'Hidden'
                $testFileAttributeResult | Should -Be $false
            }
        }
    }

    Describe 'FolderCommon\Set-FileAttribute' -Tag 'Helper' {
        BeforeAll {
            $mockAttribute = 'ReadOnly'
            $script:mockFolderObjectPath = Join-Path -Path $TestDrive -ChildPath 'FolderTest'
            $script:mockFolderObject = New-Item -Path $script:mockFolderObjectPath -ItemType 'Directory' -Force

            $defaultAttributeParameter = @{
                Folder = $script:mockFolderObject
                Attribute = $mockAttribute
            }
    }

        Context 'When a folder should have a specific attribute' {
            It 'Should set the folder to the specific attribute' {
                $setFileAttributeParameter = $defaultAttributeParameter.Clone()
                $setFileAttributeParameter['Enabled'] = $true

                { Set-FileAttribute @setFileAttributeParameter } | Should -Not -Throw

                # Using the helper function that was test above to test the result
                $testFileAttributeResult = Test-FileAttribute @defaultAttributeParameter
                $testFileAttributeResult | Should -Be $true
            }
        }

        Context 'When a folder should not have a specific attribute' {
            It 'Should set the folder to the specific attribute' {
                $setFileAttributeParameter = $defaultAttributeParameter.Clone()
                $setFileAttributeParameter['Enabled'] = $false

                { Set-FileAttribute @setFileAttributeParameter } | Should -Not -Throw

                # Using the helper function that was test above to test the result
                $testFileAttributeResult = Test-FileAttribute @defaultAttributeParameter
                $testFileAttributeResult | Should -Be $false
            }
        }
    }
}
