$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch{$false}) }
    ).BaseName

Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe DSC_ClassFolder {
        BeforeAll {
        }

        Context 'Type creation' {
            It 'Has created a type named DSC_ClassFolder' {
                'DSC_ClassFolder' -as [Type] | Should -BeOfType [Type]
            }
        }

        Context 'Constructors' {
            It 'Has a default constructor' {
                $instance = [DSC_ClassFolder]::new()
                $instance | Should -Not -BeNullOrEmpty
                $instance.GetType().Name | Should -Be 'DSC_ClassFolder'
             }
        }
    }

    Describe 'Helpers methods' {
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
                $script:convertHashtable = $script:instance.ConvertToHashtable()
            }

            It 'Should be a Hashtable' {
                $script:convertHashtable | Should -BeOfType [hashtable]
            }

            It 'Shoulb be the same value of key' {
                $script:instance.psobject.Properties.Name | ForEach-Object {
                    $script:convertHashtable.ContainsKey($_) | Should -BeTrue
                    $script:convertHashtable.$_ | Should -Be $instance.$_
                }
            }
        }

        Context 'When a folder has a specific attribute with TestFileAttribute method' {
            It 'Should set the folder to the specific attribute' {
                $testFileAttributeResult = $script:instance.TestFileAttribute($script:mockFolderObject,$mockAttribute)
                $testFileAttributeResult | Should -BeTrue
            }
        }

        Context 'When a folder does not have a specific attribute with TestFileAttribute method' {
            It 'Should set the folder to the specific attribute' {
                $testFileAttributeResult = $script:instance.TestFileAttribute($script:mockFolderObject,'Hidden')
                $testFileAttributeResult | Should -BeFalse
            }
        }

        Context 'When a folder should have a specific attribute with SetFileAttribute method' {
            It 'Should set the folder to the specific attribute' {
                $script:instance.Hidden = $true
                { $script:instance.SetFileAttribute($script:mockFolderObject,'Hidden') } | Should -Not -Throw

                $script:instance.TestFileAttribute($script:mockFolderObject,'Hidden') | Should -BeTrue
            }
        }

        Context 'When a folder does not have a specific attribute with SetFileAttribute method' {
            It 'Should return $false' {
                $script:instance.Hidden = $false
                { $script:instance.SetFileAttribute($script:mockFolderObject,'Hidden') } | Should -Not -Throw

                $script:instance.TestFileAttribute($script:mockFolderObject,'Hidden') | Should -BeFalse
            }
        }
    }

    Describe "Testing Get Method" -Tag 'Get' {
        BeforeAll {
            $script:mockFolderObjectPath = Join-Path -Path $TestDrive -ChildPath 'FolderTest'
            $script:mockFolderObject = New-Item -Path $script:mockFolderObjectPath -ItemType 'Directory' -Force
        }

        BeforeEach {
            $script:instance = [DSC_ClassFolder]::New()
            $script:instance.Path = $script:mockFolderObjectPath
            $script:instance.Ensure = [Ensure]::Present
            $script:instance.ReadOnly = $false
            #$script:instance.Hidden = $false
        }

        Context "When the configuration is absent" {
            BeforeAll {
                Mock -CommandName Get-Item -MockWith {
                    return $null
                } -Verifiable
            }

            It 'Should return the state as absent' {
                $script:instance.Get().Ensure | Should -Be 'Absent'
                Assert-MockCalled Get-Item -Exactly -Times 1 -Scope It
            }

            It 'Should return the same values as present in properties' {
                $getMethodResourceResult = $script:instance.Get()

                $getMethodResourceResult.Path | Should -Be $script:instance.Path
                $getMethodResourceResult.ReadOnly | Should -Be $script:instance.ReadOnly
            }

            It 'Should return $false or $null respectively for the rest of the properties' {
                $getMethodResourceResult = $script:instance.Get()

                $getMethodResourceResult.Hidden | Should -Be $false
                $getMethodResourceResult.Shared | Should -Be $false
                $getMethodResourceResult.SharedName | Should -BeNullOrEmpty
            }
        }

        Context "When the configuration is present" {
            BeforeAll {
                Mock -CommandName Get-Item -MockWith {
                    return $script:mockFolderObject
                }

                $testCase = @(
                    @{
                        Shared = $false
                    },
                    @{
                        Shared = $true
                    }
                )
            }

            BeforeEach {
                Mock -CommandName Get-SmbShare -MockWith {
                    return @{
                        Path = $Shared
                    }
                }
            }

            It 'Should return the state as present' {
                $script:instance.Get().Ensure | Should -Be 'Present'

                Assert-MockCalled Get-Item -Exactly -Times 1 -Scope It
            }

            It 'Should return the same values as present in properties' {
                $getMethodResourceResult = $script:instance.Get()

                $getMethodResourceResult.Path | Should -Be $script:instance.Path
                $getMethodResourceResult.ReadOnly | Should -Be $script:instance.ReadOnly
            }

            It 'Should return the correct values when Shared is <Shared>' -TestCases $testCase {
                param
                (
                    [Parameter(Mandatory = $true)]
                    [System.Boolean]
                    $Shared
                )

                $getMethodResourceResult = $script:instance.Get()

                $getMethodResourceResult.Shared | Should -Be $Shared
                $getMethodResourceResult.ReadOnly | Should -Be $script:instance.ReadOnly

                Assert-MockCalled Get-Item -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-SmbShare -Exactly -Times 1 -Scope It
            }
        }

    }

    Describe "Testing Test Method" -Tag 'Test' {
        BeforeAll {
            $script:mockFolderObjectPath = Join-Path -Path $TestDrive -ChildPath 'FolderTest'
            $script:mockFolderObject = New-Item -Path $script:mockFolderObjectPath -ItemType 'Directory' -Force
        }


        Context 'When the system is in the desired state' {
            Context 'When the configuration are absent' {
                BeforeEach {
                    $script:instance = [DSC_ClassFolder]::New()
                    $script:instance.Path = $script:mockFolderObjectPath
                    $script:instance.Ensure = [Ensure]::Absent

                    #Override Get() method
                    $script:instance | Add-Member -Force -MemberType ScriptMethod -Name Get `
                        -Value {
                            $mockinstance = [DSC_ClassFolder]::New()
                            $mockinstance.Path = $script:mockFolderObjectPath
                            $mockinstance.Ensure = [Ensure]::Absent

                            return $mockinstance
                        }
                }

                It 'Should return $true' {
                    $script:instance.Test() | Should -BeTrue
                }
            }

            Context 'When the configuration are present' {
                BeforeEach {
                    $script:instance = [DSC_ClassFolder]::New()
                    $script:instance.Path = $script:mockFolderObjectPath
                    $script:instance.Ensure = [Ensure]::Present
                    $script:instance.ReadOnly = $true
                    $script:instance.Hidden = $true

                    $script:instance | Add-Member -Force -MemberType ScriptMethod -Name Get `
                        -Value {
                            $mockinstance = [DSC_ClassFolder]::New()
                            $mockinstance.Path = $script:mockFolderObjectPath
                            $mockinstance.Ensure = [Ensure]::Present
                            $mockinstance.ReadOnly = $true
                            $mockinstance.Hidden = $true
                            $mockinstance.Shared = $true
                            $mockinstance.ShareName = 'TestShare'

                            return $mockinstance
                        }
                }

                It 'Should return $true' {
                    $script:instance.Test() | Should -Be $true
                }
            }
        }

        Context 'When the system is not in the desired state' {
            Context 'When the configuration should be absent' {
                BeforeEach {
                    $script:instance = [DSC_ClassFolder]::New()
                    $script:instance.Path = $script:mockFolderObjectPath
                    $script:instance.Ensure = [Ensure]::Absent

                    #Override Get() method
                    $script:instance | Add-Member -Force -MemberType ScriptMethod -Name Get `
                        -Value {
                            $mockinstance = [DSC_ClassFolder]::New()
                            $mockinstance.Path = $script:mockFolderObjectPath
                            $mockinstance.Ensure = [Ensure]::Present

                            return $mockinstance
                        }
                }
                It 'Should return $false' {
                    $script:instance.Test() | Should -BeFalse
                }
            }

            Context 'When the configuration should be present' {
                BeforeAll {
                    $testCase = @(
                        @{
                            Path      = (Join-Path -Path $TestDrive -ChildPath 'FolderTestReadOnly')
                            ReadOnly  = $true
                            Hidden    = $false
                            Shared    = $false
                            ShareName = $null
                        },
                        @{
                            Path      = (Join-Path -Path $TestDrive -ChildPath 'FolderTestHidden')
                            ReadOnly  = $false
                            Hidden    = $true
                            Shared    = $false
                            ShareName = $null
                        }
                    )
                }

                BeforeEach {
                    $script:instance = [DSC_ClassFolder]::New()
                    $script:instance.Path = $script:mockFolderObjectPath
                    $script:instance.Ensure = [Ensure]::Present

                }

                It 'Should return $false' {
                    #Override Get() method
                    $script:instance | Add-Member -Force -MemberType ScriptMethod -Name Get `
                    -Value {
                        $mockinstance = [DSC_ClassFolder]::New()
                        $mockinstance.Path = $script:mockFolderObjectPath
                        $mockinstance.Ensure = [Ensure]::Absent

                        return $mockinstance
                    }
                    $script:instance.Test() | Should -BeFalse
                }

                It 'Should return $false when ReadOnly is <ReadOnly>, and Hidden is <Hidden>' -TestCases $testCase {
                    param
                    (
                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $Path,

                        [Parameter(Mandatory = $true)]
                        [System.Boolean]
                        $ReadOnly,

                        [Parameter()]
                        [System.Boolean]
                        $Hidden,

                        [Parameter()]
                        [System.Boolean]
                        $Shared,

                        [Parameter()]
                        [System.String]
                        $ShareName
                    )
                    #Override Get() method
                    $script:instance | Add-Member -Force -MemberType ScriptMethod -Name Get `
                        -Value {
                            $mockinstance = [DSC_ClassFolder]::New()
                            $mockinstance.Path = $Path
                            $mockinstance.Ensure = [Ensure]::Present
                            $mockinstance.Hidden = $ReadOnly
                            $mockinstance.ReadOnly = $Hidden
                            $mockinstance.Shared = $Shared
                            $mockinstance.ShareName = $ShareName

                            return $mockinstance
                        }

                    $script:instance.Path = $Path
                    $script:instance.ReadOnly = $false
                    $script:instance.Hidden = $false

                    $script:instance.Test() | Should -BeFalse
                }
            }
        }
    }

    Describe "Testing Set Method" -Tag 'Set' {
        BeforeAll {
            $script:mockFolderObjectPath = Join-Path -Path $TestDrive -ChildPath 'FolderTest'
            $script:mockFolderObject = New-Item -Path $script:mockFolderObjectPath -ItemType 'Directory' -Force

            function Test-SetFileAttributeMethodUsing {
                Param(
                    [System.IO.DirectoryInfo]
                    $Folder,

                    [System.IO.FileAttributes]
                    $Attribute
                )
                return $null
            }
        }

        Context 'When the system is not in the desired state' {
            BeforeAll {
                Mock -CommandName Test-SetFileAttributeMethodUsing
            }

            AfterEach {
                <#
                    Make sure to remove the test folder so that it does
                    not exist for other tests.
                #>
                if ($script:mockFolderObject -and (Test-Path -Path $script:mockFolderObject))
                {
                    Remove-Item -Path $script:mockFolderObject -Force
                }
            }

            Context 'When the configuration should be absent' {
                BeforeAll {
                    $script:instance = [DSC_ClassFolder]::New()
                    $script:instance.Path = $script:mockFolderObjectPath

                    #Override Get() method
                    $script:instance | Add-Member -Force -MemberType ScriptMethod -Name Get `
                        -Value {
                            $mockinstance = [DSC_ClassFolder]::New()
                            $mockinstance.Path = $script:mockFolderObjectPath
                            $mockinstance.Ensure = [Ensure]::Present

                            return $mockinstance
                        }

                    Mock -CommandName Remove-Item -ParameterFilter {
                        $Path -eq $script:instance.Path
                    } -Verifiable
                }

                BeforeEach {
                    $script:instance.Ensure = [Ensure]::Absent
                }

                It 'Should call the correct mocks' {
                    { $script:instance.Set() } | Should -Not -Throw

                    Assert-MockCalled -CommandName Remove-Item -Exactly -Times 1 -Scope 'It'
                }
            }

            Context 'When the configuration should be present' {
                BeforeAll {
                    $script:instance = [DSC_ClassFolder]::New()
                    $script:instance.Path = $script:mockFolderObjectPath

                    #Override Get() method
                    $script:instance | Add-Member -Force -MemberType ScriptMethod -Name Get `
                        -Value {
                            $mockinstance = [DSC_ClassFolder]::New()
                            $mockinstance.Path = $script:mockFolderObjectPath
                            $mockinstance.Ensure = [Ensure]::Absent

                            return $mockinstance
                        }
                    #Override SetFileAttribute method with Test-SetFileAttributeMethodUsing function
                    $script:instance | Add-Member -Force -MemberType ScriptMethod -Name SetFileAttribute `
                        -Value {
                            param
                            (
                                [System.IO.DirectoryInfo]
                                $Folder,

                                [System.IO.FileAttributes]
                                $Attribute
                            )
                            Test-SetFileAttributeMethodUsing -Folder $Folder -Attribute $Attribute
                        }


                    $script:mockFolderObject = New-Item -Path $script:mockFolderObjectPath -ItemType 'Directory' -Force


                    Mock -CommandName Get-Item
                    Mock -CommandName New-Item -ParameterFilter {
                        $Path -eq $script:instance.Path
                    } -MockWith {
                        return $script:mockFolderObject
                    } -Verifiable
                }

                BeforeEach {
                    $script:instance.Ensure = 'Present'
                }

                It 'Should call the correct mocks' {
                    { $script:instance.Set() } | Should -Not -Throw

                    Assert-MockCalled -CommandName Get-Item -Exactly -Times 0 -Scope 'It'
                    Assert-MockCalled -CommandName New-Item -ParameterFilter {
                        $Path -eq $script:instance.Path
                    } -Exactly -Times 1 -Scope 'It'


                    Assert-MockCalled -CommandName Test-SetFileAttributeMethodUsing  -ParameterFilter {
                        $Attribute -eq 'ReadOnly'
                    } -Exactly -Times 1 -Scope 'It'

                    Assert-MockCalled -CommandName Test-SetFileAttributeMethodUsing  -ParameterFilter {
                        $Attribute -eq 'Hidden'
                    } -Exactly -Times 1 -Scope 'It'

                }
            }

            Context 'When the configuration is present but has the wrong properties' {
                BeforeAll {
                    $script:instance = [DSC_ClassFolder]::New()
                    $script:instance.Path = $script:mockFolderObjectPath

                    #Override SetFileAttribute method with Test-SetFileAttributeMethodUsing function
                    $script:instance | Add-Member -Force -MemberType ScriptMethod -Name SetFileAttribute `
                    -Value {
                        param
                        (
                            [System.IO.DirectoryInfo]
                            $Folder,

                            [System.IO.FileAttributes]
                            $Attribute
                        )
                        Test-SetFileAttributeMethodUsing -Folder $Folder -Attribute $Attribute
                    }

                    $script:mockFolderObject = New-Item -Path $script:mockFolderObjectPath -ItemType 'Directory' -Force

                    $testCase = @(
                        @{
                            ReadOnly  = $true
                            Hidden    = $false
                            Shared    = $false
                            ShareName = $null
                        },
                        @{
                            ReadOnly  = $false
                            Hidden    = $true
                            Shared    = $false
                            ShareName = $null
                        },
                        @{
                            ReadOnly  = $false
                            Hidden    = $false
                            Shared    = $true
                            ShareName = 'TestShare'
                        }
                    )

                    Mock -CommandName New-Item
                    Mock -CommandName Get-Item -ParameterFilter {
                        $Path -eq $script:instance.Path
                    } -MockWith {
                        return $script:mockFolderObject
                    } -Verifiable
                }

                BeforeEach {
                    $script:instance.Ensure = 'Present'
                }

                It 'Should call the correct mocks when ReadOnly is <ReadOnly>, and Hidden is <Hidden>' -TestCases $testCase {
                    param
                    (
                        [Parameter(Mandatory = $true)]
                        [System.Boolean]
                        $ReadOnly,

                        [Parameter()]
                        [System.Boolean]
                        $Hidden,

                        [Parameter()]
                        [System.Boolean]
                        $Shared,

                        [Parameter()]
                        [System.String]
                        $ShareName
                    )

                    #Override Get() method
                    $script:instance | Add-Member -Force -MemberType ScriptMethod -Name Get `
                        -Value {
                            $mockinstance = [DSC_ClassFolder]::New()
                            $mockinstance.Path = $script:mockFolderObjectPath
                            $mockinstance.Ensure = [Ensure]::Present
                            $mockinstance.ReadOnly = $ReadOnly
                            $mockinstance.Hidden = $Hidden
                            $mockinstance.Shared = $Shared
                            $mockinstance.ShareName = $ShareName

                            return $mockinstance
                        }

                    $script:instance.ReadOnly = $false
                    $script:instance.Hidden = $false

                    { $script:instance.Set() } | Should -Not -Throw

                    Assert-MockCalled -CommandName New-Item -Exactly -Times 0 -Scope 'It'
                    Assert-MockCalled -CommandName Get-Item -Exactly -Times 1 -Scope 'It'


                    if ($ReadOnly)
                    {
                        Assert-MockCalled -CommandName Test-SetFileAttributeMethodUsing -ParameterFilter {
                            $Attribute -eq 'ReadOnly'
                        } -Exactly -Times 1 -Scope 'It'
                    }

                    if ($Hidden)
                    {
                        Assert-MockCalled -CommandName Test-SetFileAttributeMethodUsing -ParameterFilter {
                            $Attribute -eq 'Hidden'
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }
            }

            Assert-VerifiableMock
        }
    }
}
