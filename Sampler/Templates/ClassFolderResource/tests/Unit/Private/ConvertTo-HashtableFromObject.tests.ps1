$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch{$false}) }
    ).BaseName

Import-Module $ProjectName

InModuleScope $ProjectName {

    Describe 'Helper function ConvertTo-HashtableFromObject' {
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

        Context 'When instance of class is convert to hashtable' {
            BeforeEach {

            }
            It 'Should not Throw' {
                {$script:convertHashtable = $script:instance | ConvertTo-HashtableFromObject} | Should -Not -Throw
            }

            It 'Should be a Hashtable' {
                $script:convertHashtable | Should -BeOfType [hashtable]
            }

            It 'Should have the same count of properties' {
                $script:convertHashtable.keys.count | Should -Be $script:instance.psobject.Properties.Name.count
            }
            It 'Should be the same value of key' {
                $script:instance.psobject.Properties.Name | ForEach-Object {
                    $script:convertHashtable.ContainsKey($_) | Should -BeTrue
                    $script:convertHashtable.$_ | Should -Be $instance.$_
                }
            }
        }
    }
}
