$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch{$false}) }
    ).BaseName

Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Helper function Test-FileAttribute' {
        BeforeAll {
            $mockAttribute = 'ReadOnly'
            $script:mockFolderObjectPath = Join-Path -Path $TestDrive -ChildPath 'FolderTest'
            $script:mockFolderObject = New-Item -Path $script:mockFolderObjectPath -ItemType 'Directory' -Force
            $script:mockFolderObject.Attributes = [System.IO.FileAttributes]::$mockAttribute
        }

        BeforeEach{
            $script:instance = [DSC_ClassFolder]::new()
            $script:instance.Path = $script:mockFolderObjectPath
            $script:instance.Ensure = [Ensure]::Present
        }

        Context 'When a folder has a specific attribute with Test-FileAttribute function' {
            It 'Should set the folder to the specific attribute' {
                $testFileAttributeResult = Test-FileAttribute -Folder $script:mockFolderObject -Attribute $mockAttribute
                $testFileAttributeResult | Should -BeTrue
            }
        }

        Context 'When a folder does not have a specific attribute with Test-FileAttribute function' {
            It 'Should set the folder to the specific attribute' {
                $testFileAttributeResult = Test-FileAttribute -Folder $script:mockFolderObject -Attribute 'Hidden'
                $testFileAttributeResult | Should -BeFalse
            }
        }
    }
}
