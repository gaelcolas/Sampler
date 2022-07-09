BeforeAll {
    $script:moduleName = 'Sampler'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 2)
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    }

    # Re-import the module using force to get any code changes between runs.
    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Module -Name $script:moduleName
}

Describe 'Get-MofSchemaName' {
    Context 'When cannot determine operating system' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPreviousIsWindows = $IsWindows
                $script:mockPreviousIsMacOS = $IsMacOS
                $script:mockPreviousIsLinux = $IsLinux
                $script:IsWindows = $false
                $script:IsMacOS = $false
                $script:IsLinux = $false
            }

            Mock -CommandName Test-Path -MockWith {
                return $true
            }
        }

        AfterAll {
            InModuleScope -ScriptBlock {
                $script:IsWindows = $mockPreviousIsWindows
                $script:IsMacOS = $mockPreviousIsMacOS
                $script:IsLinux = $mockPreviousIsLinux
            }
        }

        It 'Should throw the correct error message' {
            { Sampler\Get-MofSchemaName -Path $TestDrive } | Should -Throw -ExpectedMessage 'Cannot set the temporary path. Unknown operating system.'
        }
    }

    Context 'When schema mof is invalid' -Skip:($IsMacOS -or $IsLinux) {
        BeforeAll {
            InModuleScope -ScriptBlock {
                # Mock Windows PowerShell
                $script:mockPreviousIsWindows = $IsWindows
                $script:IsWindows = $false
            }

            # Mock Windows PowerShell
            Mock -CommandName Test-Path -MockWith {
                return $false
            }

            Mock -CommandName Get-Content -MockWith {
                return @'
[Invalid("1.0.0.0"), FriendlyName("MockResourceName")]
class DSC_MockResourceName : OMI_BaseResource
{
    [Key, Description("Mock description")] String Name;
};
'@
            }

            Mock -CommandName Join-Path -MockWith {
                return (Join-Path -Path $TestDrive -ChildPath $PesterBoundParameters.ChildPath)
            }
        }

        AfterAll {
            InModuleScope -ScriptBlock {
                $script:IsWindows = $mockPreviousIsWindows
            }
        }

        It 'Should return the correct property values' {
            { Sampler\Get-MofSchemaName -Path $TestDrive } | Should -Throw -ExpectedMessage 'Failed to import classes from file*Cim deserializer threw an error when deserializing file*'
        }
    }

    Context 'When running in Windows PowerShell on Windows'-Skip:($IsMacOS -or $IsLinux) {
        BeforeAll {
            InModuleScope -ScriptBlock {
                # Mock Windows PowerShell (on Windows)
                $script:mockPreviousIsWindows = $IsWindows
                $script:IsWindows = $false
            }

            # Mock Windows PowerShell
            Mock -CommandName Test-Path -MockWith {
                return $false
            }

            Mock -CommandName Get-Content -MockWith {
                return @'
[ClassVersion("1.0.0.0"), FriendlyName("MockResourceName")]
class DSC_MockResourceName : OMI_BaseResource
{
    [Key, Description("Mock description")] String Name;
};
'@
            }

            Mock -CommandName Join-Path -MockWith {
                return (Join-Path -Path $TestDrive -ChildPath $PesterBoundParameters.ChildPath)
            }
        }

        AfterAll {
            InModuleScope -ScriptBlock {
                $script:IsWindows = $mockPreviousIsWindows
            }
        }

        It 'Should return the correct property values' {
            $result = Sampler\Get-MofSchemaName -Path $TestDrive

            $result.Name | Should -Be 'DSC_MockResourceName'
            $result.FriendlyName | Should -Be 'MockResourceName'
        }
    }

    Context 'When running in PowerShell on Windows' -Skip:($IsMacOS -or $IsLinux) {
        BeforeAll {
            InModuleScope -ScriptBlock {
                # Mock Windows
                $script:mockPreviousIsWindows = $IsWindows
                $script:IsWindows = $true
            }

            # Mock PowerShell
            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            Mock -CommandName Get-Content -MockWith {
                return @'
[ClassVersion("1.0.0.0"), FriendlyName("MockResourceName")]
class DSC_MockResourceName : OMI_BaseResource
{
    [Key, Description("Mock description")] String Name;
};
'@
            }

            Mock -CommandName Join-Path -MockWith {
                return (Join-Path -Path $TestDrive -ChildPath $PesterBoundParameters.ChildPath)
            }
        }

        AfterAll {
            InModuleScope -ScriptBlock {
                $script:IsWindows = $mockPreviousIsWindows
            }
        }

        It 'Should return the correct property values' {
            $result = Sampler\Get-MofSchemaName -Path $TestDrive

            $result.Name | Should -Be 'DSC_MockResourceName'
            $result.FriendlyName | Should -Be 'MockResourceName'
        }
    }

    Context 'When running in PowerShell on Linux' -Skip:($IsMacOS -or $IsWindows -or $PSVersionTable.PSVersion.Major -eq 5) {
        BeforeAll {
            # Mock PowerShell
            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            Mock -CommandName Get-Content -MockWith {
                return @'
[ClassVersion("1.0.0.0"), FriendlyName("MockResourceName")]
class DSC_MockResourceName : OMI_BaseResource
{
    [Key, Description("Mock description")] String Name;
};
'@
            }

            Mock -CommandName Join-Path -MockWith {
                return (Join-Path -Path $TestDrive -ChildPath $PesterBoundParameters.ChildPath)
            }
        }

        It 'Should return the correct property values' {
            $result = Sampler\Get-MofSchemaName -Path $TestDrive

            $result.Name | Should -Be 'DSC_MockResourceName'
            $result.FriendlyName | Should -Be 'MockResourceName'
        }
    }

    Context 'When running in PowerShell on macOS' -Skip:($IsLinux -or $IsWindows -or $PSVersionTable.PSVersion.Major -eq 5) {
        BeforeAll {
            # Mock PowerShell
            Mock -CommandName Test-Path -MockWith {
                return $true
            }
        }

        It 'Should return the correct property values' {
            { Sampler\Get-MofSchemaName -Path $TestDrive } | Should -Throw -ExpectedMessage 'NotImplemented: Currently there is an issue using the type*Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache*on macOS.*'
        }
    }
}
