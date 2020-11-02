$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch{$false}) }
    ).BaseName

Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe DSC_ClassFolder {
        Context 'Constructors' {
            It 'Should not throw an exception when instanciate it' {
                {[DSC_ClassFolder]::new()} | Should -Not -Throw
            }

            It 'Has a default or empty constructor' {
                $instance = [DSC_ClassFolder]::new()
                $instance | Should -Not -BeNullOrEmpty
                $instance.GetType().Name | Should -Be 'DSC_ClassFolder'
            }
        }

        Context 'Type creation' {
            It 'Should be type named DSC_ClassFolder' {
                $instance = [DSC_ClassFolder]::new()
                $instance.GetType().Name | Should -Be 'DSC_ClassFolder'
            }
        }
    }

    Describe "Testing Get Method" -Tag 'Get' {
        BeforeAll {
            $script:mockFolderObjectPath = Join-Path -Path $TestDrive -ChildPath 'FolderTest'
            $script:mockFolderObject = New-Item -Path $script:mockFolderObjectPath -ItemType 'Directory' -Force
        }

        BeforeEach {
            $script:instanceDesiredState = [DSC_ClassFolder]::New()
            $script:instanceDesiredState.Path = $script:mockFolderObjectPath
            $script:instanceDesiredState.Ensure = [Ensure]::Present
            $script:instanceDesiredState.ReadOnly = $false
        }

        Context "When the configuration is absent" {
            BeforeAll {
                Mock -CommandName Get-Item -MockWith {
                    return $null
                } -Verifiable
            }

            It 'Should return the state as absent' {
                $script:instanceDesiredState.Get().Ensure | Should -Be 'Absent'
                Assert-MockCalled Get-Item -Exactly -Times 1 -Scope It
            }

            It 'Should return the same values as present in properties' {
                $getMethodResourceResult = $script:instanceDesiredState.Get()

                $getMethodResourceResult.Path | Should -Be $script:instanceDesiredState.Path
                $getMethodResourceResult.ReadOnly | Should -Be $script:instanceDesiredState.ReadOnly
            }

            It 'Should return $false or $null respectively for the rest of the properties' {
                $getMethodResourceResult = $script:instanceDesiredState.Get()

                $getMethodResourceResult.Hidden | Should -Be $false
                $getMethodResourceResult.Shared | Should -Be $false
                $getMethodResourceResult.SharedName | Should -BeNullOrEmpty
            }

            It 'Should return Reason because the folder is absent' {
                $getMethodResourceResult = $script:instanceDesiredState.Get()

                $getMethodResourceResult.Reasons.Code | Should -Contain 'DSC_ClassFolder:DSC_ClassFolder:Ensure'
            }
        }

        Context "When the configuration is present" {
            BeforeAll {
                Mock -CommandName Get-Item -MockWith {
                    return $script:mockFolderObject
                }
            }

            BeforeEach {
                Mock -CommandName Get-SmbShare -MockWith {
                    return @{
                        Path = $Shared
                    }
                }
            }

            $testCase = @(
                @{
                    Shared = $false
                },
                @{
                    Shared = $true
                }
            )

            It 'Should return the state as present' {
                $script:instanceDesiredState.Get().Ensure | Should -Be 'Present'

                Assert-MockCalled Get-Item -Exactly -Times 1 -Scope It
            }

            It 'Should return the same values as present in properties' {
                $getMethodResourceResult = $script:instanceDesiredState.Get()

                $getMethodResourceResult.Path | Should -Be $script:instanceDesiredState.Path
                $getMethodResourceResult.ReadOnly | Should -Be $script:instanceDesiredState.ReadOnly
            }

            It 'Should return the correct values when Shared is <Shared>' -TestCases $testCase {
                param
                (
                    [System.Boolean]
                    $Shared
                )

                $getMethodResourceResult = $script:instanceDesiredState.Get()

                $getMethodResourceResult.Shared | Should -Be $Shared
                $getMethodResourceResult.ReadOnly | Should -Be $script:instanceDesiredState.ReadOnly

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
                    $script:instanceDesiredState = [DSC_ClassFolder]::New()
                    $script:instanceDesiredState.Path = $script:mockFolderObjectPath
                    $script:instanceDesiredState.Ensure = [Ensure]::Absent

                    #Override Get() method
                    $script:instanceDesiredState | Add-Member -Force -MemberType ScriptMethod -Name Get `
                        -Value {
                            $mockInstanceCurrentState = [DSC_ClassFolder]::New()
                            $mockInstanceCurrentState.Path = $script:mockFolderObjectPath
                            $mockInstanceCurrentState.Ensure = [Ensure]::Absent

                            return $mockInstanceCurrentState
                        }
                }

                It 'Should return $true' {
                    $script:instanceDesiredState.Test() | Should -BeTrue
                }
            }

            Context 'When the configuration are present' {
                BeforeEach {
                    $script:instanceDesiredState = [DSC_ClassFolder]::New()
                    $script:instanceDesiredState.Path = $script:mockFolderObjectPath
                    $script:instanceDesiredState.Ensure = [Ensure]::Present
                    $script:instanceDesiredState.ReadOnly = $true
                    $script:instanceDesiredState.Hidden = $true

                    $script:instanceDesiredState | Add-Member -Force -MemberType ScriptMethod -Name Get `
                        -Value {
                            $mockInstanceCurrentState = [DSC_ClassFolder]::New()
                            $mockInstanceCurrentState.Path = $script:mockFolderObjectPath
                            $mockInstanceCurrentState.Ensure = [Ensure]::Present
                            $mockInstanceCurrentState.ReadOnly = $true
                            $mockInstanceCurrentState.Hidden = $true
                            $mockInstanceCurrentState.Shared = $true
                            $mockInstanceCurrentState.ShareName = 'TestShare'

                            return $mockInstanceCurrentState
                        }
                }

                It 'Should return $true' {
                    $script:instanceDesiredState.Test() | Should -Be $true
                }
            }
        }

        Context 'When the system is not in the desired state' {
            Context 'When the configuration should be absent' {
                BeforeEach {
                    $script:instanceDesiredState = [DSC_ClassFolder]::New()
                    $script:instanceDesiredState.Path = $script:mockFolderObjectPath
                    $script:instanceDesiredState.Ensure = [Ensure]::Absent

                    #Override Get() method
                    $script:instanceDesiredState | Add-Member -Force -MemberType ScriptMethod -Name Get `
                        -Value {
                            $mockInstanceCurrentState = [DSC_ClassFolder]::New()
                            $mockInstanceCurrentState.Path = $script:mockFolderObjectPath
                            $mockInstanceCurrentState.Ensure = [Ensure]::Present
                            $mockInstanceCurrentState.Reasons += [Reason]@{
                                Code = '{0}:{0}:Ensure' -f $this.GetType()
                                Phrase = ''
                            }

                            return $mockInstanceCurrentState
                        }
                }
                It 'Should return $false' {
                    $script:instanceDesiredState.Test() | Should -BeFalse
                }
            }

            Context 'When the configuration should be present' {
                BeforeEach {
                    $script:instanceDesiredState = [DSC_ClassFolder]::New()
                    $script:instanceDesiredState.Path = $script:mockFolderObjectPath
                    $script:instanceDesiredState.Ensure = [Ensure]::Present

                }

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

                It 'Should return $false' {
                    #Override Get() method
                    $script:instanceDesiredState | Add-Member -Force -MemberType ScriptMethod -Name Get `
                    -Value {
                        $mockInstanceCurrentState = [DSC_ClassFolder]::New()
                        $mockInstanceCurrentState.Path = $script:mockFolderObjectPath
                        $mockInstanceCurrentState.Ensure = [Ensure]::Absent
                        $mockInstanceCurrentState.Reasons += [Reason]@{
                            Code = '{0}:{0}:Ensure' -f $this.GetType()
                            Phrase = ''
                        }

                        return $mockInstanceCurrentState
                    }
                    $script:instanceDesiredState.Test() | Should -BeFalse
                }

                It 'Should return $false when ReadOnly is <ReadOnly>, and Hidden is <Hidden>' -TestCases $testCase {
                    param
                    (
                        [System.String]
                        $Path,

                        [System.Boolean]
                        $ReadOnly,

                        [System.Boolean]
                        $Hidden,

                        [System.Boolean]
                        $Shared,

                        [System.String]
                        $ShareName
                    )
                    #Override Get() method
                    $script:instanceDesiredState | Add-Member -Force -MemberType ScriptMethod -Name Get `
                        -Value {
                            $mockInstanceCurrentState = [DSC_ClassFolder]::New()
                            $mockInstanceCurrentState.Path = $Path
                            $mockInstanceCurrentState.Ensure = [Ensure]::Present
                            $mockInstanceCurrentState.ReadOnly = $ReadOnly
                            $mockInstanceCurrentState.Hidden = $Hidden
                            $mockInstanceCurrentState.Shared = $Shared
                            $mockInstanceCurrentState.ShareName = $ShareName

                            if ($this.ReadOnly -ne $ReadOnly)
                            {
                                $mockInstanceCurrentState.Reasons += [Reason]@{
                                    Code = '{0}:{0}:ReadOnly' -f $this.GetType()
                                    Phrase = ''
                                }
                            }
                            if ($this.Hidden -ne $Hidden)
                            {
                                $mockInstanceCurrentState.Reasons += [Reason]@{
                                    Code = '{0}:{0}:Hidden' -f $this.GetType()
                                    Phrase = ''
                                }
                            }

                            return $mockInstanceCurrentState
                        }

                    $script:instanceDesiredState.Path = $Path
                    $script:instanceDesiredState.ReadOnly = $false
                    $script:instanceDesiredState.Hidden = $false

                    $script:instanceDesiredState.Test() | Should -BeFalse
                }
            }
        }
    }

    Describe "Testing Set Method" -Tag 'Set' {
        BeforeAll {
            $script:mockFolderObjectPath = Join-Path -Path $TestDrive -ChildPath 'FolderTest'
            $script:mockFolderObject = New-Item -Path $script:mockFolderObjectPath -ItemType 'Directory' -Force
        }

        Context 'When the system is not in the desired state' {
            BeforeAll {
                Mock -CommandName Set-FileAttribute
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
                    $script:instanceDesiredState = [DSC_ClassFolder]::New()
                    $script:instanceDesiredState.Path = $script:mockFolderObjectPath

                    #Override Get() method
                    $script:instanceDesiredState | Add-Member -Force -MemberType ScriptMethod -Name Get `
                        -Value {
                            $mockInstanceCurrentState = [DSC_ClassFolder]::New()
                            $mockInstanceCurrentState.Path = $script:mockFolderObjectPath
                            $mockInstanceCurrentState.Ensure = [Ensure]::Present
                            $mockInstanceCurrentState.Reasons += [Reason]@{
                                Code = '{0}:{0}:Ensure' -f $this.GetType()
                                Phrase = ''
                            }

                            return $mockInstanceCurrentState
                        }

                    Mock -CommandName Remove-Item -ParameterFilter {
                        $Path -eq $script:instanceDesiredState.Path
                    } -Verifiable
                }

                BeforeEach {
                    $script:instanceDesiredState.Ensure = [Ensure]::Absent
                }

                It 'Should call the correct mocks' {
                    { $script:instanceDesiredState.Set() } | Should -Not -Throw

                    Assert-MockCalled -CommandName Remove-Item -Exactly -Times 1 -Scope 'It'
                }
            }

            Context 'When the configuration should be present' {
                BeforeAll {
                    $script:instanceDesiredState = [DSC_ClassFolder]::New()
                    $script:instanceDesiredState.Path = $script:mockFolderObjectPath

                    #Override Get() method
                    $script:instanceDesiredState | Add-Member -Force -MemberType ScriptMethod -Name Get `
                        -Value {
                            $mockInstanceCurrentState = [DSC_ClassFolder]::New()
                            $mockInstanceCurrentState.Path = $script:mockFolderObjectPath
                            $mockInstanceCurrentState.Ensure = [Ensure]::Absent
                            $mockInstanceCurrentState.Reasons += [Reason]@{
                                Code = '{0}:{0}:Ensure' -f $this.GetType()
                                Phrase = ''
                            }

                            return $mockInstanceCurrentState
                        }

                    $script:mockFolderObject = New-Item -Path $script:mockFolderObjectPath -ItemType 'Directory' -Force


                    Mock -CommandName Get-Item
                    Mock -CommandName New-Item -ParameterFilter {
                        $Path -eq $script:instanceDesiredState.Path
                    } -MockWith {
                        return $script:mockFolderObject
                    } -Verifiable
                }

                BeforeEach {
                    $script:instanceDesiredState.Ensure = 'Present'
                }

                It 'Should call the correct mocks' {
                    { $script:instanceDesiredState.Set() } | Should -Not -Throw

                    Assert-MockCalled -CommandName Get-Item -Exactly -Times 0 -Scope 'It'
                    Assert-MockCalled -CommandName New-Item -ParameterFilter {
                        $Path -eq $script:instanceDesiredState.Path
                    } -Exactly -Times 1 -Scope 'It'


                    Assert-MockCalled -CommandName Set-FileAttribute  -ParameterFilter {
                        $Attribute -eq 'ReadOnly'
                    } -Exactly -Times 1 -Scope 'It'

                    Assert-MockCalled -CommandName Set-FileAttribute  -ParameterFilter {
                        $Attribute -eq 'Hidden'
                    } -Exactly -Times 1 -Scope 'It'

                }
            }

            Context 'When the configuration is present but has the wrong properties' {
                BeforeAll {
                    $script:instanceDesiredState = [DSC_ClassFolder]::New()
                    $script:instanceDesiredState.Path = $script:mockFolderObjectPath
                    $script:mockFolderObject = New-Item -Path $script:mockFolderObjectPath -ItemType 'Directory' -Force

                    Mock -CommandName New-Item
                    Mock -CommandName Get-Item -ParameterFilter {
                        $Path -eq $script:instanceDesiredState.Path
                    } -MockWith {
                        return $script:mockFolderObject
                    } -Verifiable
                }

                BeforeEach {
                    $script:instanceDesiredState.Ensure = 'Present'
                }

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

                It 'Should call the correct mocks when ReadOnly is <ReadOnly>, and Hidden is <Hidden>' -TestCases $testCase {
                    param
                    (
                        [System.Boolean]
                        $ReadOnly,

                        [System.Boolean]
                        $Hidden,

                        [System.Boolean]
                        $Shared,

                        [System.String]
                        $ShareName
                    )

                    #Override Get() method
                    $script:instanceDesiredState | Add-Member -Force -MemberType ScriptMethod -Name Get `
                        -Value {
                            $mockInstanceCurrentState = [DSC_ClassFolder]::New()
                            $mockInstanceCurrentState.Path = $script:mockFolderObjectPath
                            $mockInstanceCurrentState.Ensure = [Ensure]::Present
                            $mockInstanceCurrentState.ReadOnly = $ReadOnly
                            $mockInstanceCurrentState.Hidden = $Hidden
                            $mockInstanceCurrentState.Shared = $Shared
                            $mockInstanceCurrentState.ShareName = $ShareName
                            if ($this.ReadOnly -ne $ReadOnly)
                            {
                                $mockInstanceCurrentState.Reasons += [Reason]@{
                                    Code = '{0}:{0}:ReadOnly' -f $this.GetType()
                                    Phrase = ''
                                }
                            }
                            if ($this.Hidden -ne $Hidden)
                            {
                                $mockInstanceCurrentState.Reasons += [Reason]@{
                                    Code = '{0}:{0}:Hidden' -f $this.GetType()
                                    Phrase = ''
                                }
                            }

                            return $mockInstanceCurrentState
                        }

                    $script:instanceDesiredState.ReadOnly = $false
                    $script:instanceDesiredState.Hidden = $false

                    { $script:instanceDesiredState.Set() } | Should -Not -Throw

                    Assert-MockCalled -CommandName New-Item -Exactly -Times 0 -Scope 'It'
                    Assert-MockCalled -CommandName Get-Item -Exactly -Times 1 -Scope 'It'


                    if ($ReadOnly)
                    {
                        Assert-MockCalled -CommandName Set-FileAttribute -ParameterFilter {
                            $Attribute -eq 'ReadOnly'
                        } -Exactly -Times 1 -Scope 'It'
                    }

                    if ($Hidden)
                    {
                        Assert-MockCalled -CommandName Set-FileAttribute -ParameterFilter {
                            $Attribute -eq 'Hidden'
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }
            }

            Assert-VerifiableMock
        }
    }
}
