$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch{$false}) }
    ).BaseName

Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Helper function Set-FileAttribute' {
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

        Context 'When a folder should have a specific attribute with SetFileAttribute function' {
            It 'Should set the folder to the specific attribute' {
                $script:instance.Hidden = $true
                { Set-FileAttribute -Folder $script:mockFolderObject -Attribute 'Hidden' -Enabled $script:instance.Hidden } | Should -Not -Throw

                Test-FileAttribute -Folder $script:mockFolderObject -Attribute 'Hidden' | Should -BeTrue
            }
        }

        Context 'When a folder does not have a specific attribute with SetFileAttribute function' {
            It 'Should return $false' {
                $script:instance.Hidden = $false
                { Set-FileAttribute -Folder $script:mockFolderObject -Attribute 'Hidden' -Enabled $script:instance.Hidden } | Should -Not -Throw

                Test-FileAttribute -Folder $script:mockFolderObject -Attribute 'Hidden' | Should -BeFalse
            }
        }
    }
}
