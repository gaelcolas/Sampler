BeforeAll {
    $script:moduleName = 'Sampler'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 3)
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

Describe 'Get-OperatingSystemShortName' {
    Context 'When running in Windows PowerShell on Windows' -Skip:($IsMacOS -or $IsLinux) {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPreviousIsWindows = $IsWindows
                $script:mockPreviousIsMacOS = $IsMacOS
                $script:mockPreviousIsLinux = $IsLinux
                $script:IsWindows = $false
                $script:IsMacOS = $false
                $script:IsLinux = $false

                $script:previousPSVersionTable = $PSVersionTable.Clone()

                $script:PSVersionTable = @{
                    PSVersion = @{
                        Major = 5
                    }
                }
            }
        }

        AfterAll {
            InModuleScope -ScriptBlock {
                $script:IsWindows = $mockPreviousIsWindows
                $script:IsMacOS = $mockPreviousIsMacOS
                $script:IsLinux = $mockPreviousIsLinux

                $script:PSVersionTable = $script:previousPSVersionTable.Clone()
            }
        }

        It 'Should return the correct operating system short name' {
            $result = Sampler\Get-OperatingSystemShortName

            $result | Should -Be 'Windows'
        }
    }

    Context 'When running in PowerShell on Windows' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPreviousIsWindows = $IsWindows
                $script:mockPreviousIsMacOS = $IsMacOS
                $script:mockPreviousIsLinux = $IsLinux
                $script:IsWindows = $true
                $script:IsMacOS = $false
                $script:IsLinux = $false
            }
        }

        AfterAll {
            InModuleScope -ScriptBlock {
                $script:IsWindows = $mockPreviousIsWindows
                $script:IsMacOS = $mockPreviousIsMacOS
                $script:IsLinux = $mockPreviousIsLinux
            }
        }

        It 'Should return the correct operating system short name' {
            $result = Sampler\Get-OperatingSystemShortName

            $result | Should -Be 'Windows'
        }
    }

    Context 'When running in PowerShell on macOS' -Skip:($PSVersionTable.PSVersion.Major -eq 5) {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPreviousIsWindows = $IsWindows
                $script:mockPreviousIsMacOS = $IsMacOS
                $script:mockPreviousIsLinux = $IsLinux
                $script:IsWindows = $false
                $script:IsMacOS = $true
                $script:IsLinux = $false
            }
        }

        AfterAll {
            InModuleScope -ScriptBlock {
                $script:IsWindows = $mockPreviousIsWindows
                $script:IsMacOS = $mockPreviousIsMacOS
                $script:IsLinux = $mockPreviousIsLinux
            }
        }

        It 'Should return the correct operating system short name' {
            $result = Sampler\Get-OperatingSystemShortName

            $result | Should -Be 'MacOS'
        }
    }

    Context 'When running in PowerShell on Linux' -Skip:($PSVersionTable.PSVersion.Major -eq 5) {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPreviousIsWindows = $IsWindows
                $script:mockPreviousIsMacOS = $IsMacOS
                $script:mockPreviousIsLinux = $IsLinux
                $script:IsWindows = $false
                $script:IsMacOS = $false
                $script:IsLinux = $true
            }
        }

        AfterAll {
            InModuleScope -ScriptBlock {
                $script:IsWindows = $mockPreviousIsWindows
                $script:IsMacOS = $mockPreviousIsMacOS
                $script:IsLinux = $mockPreviousIsLinux
            }
        }

        It 'Should return the correct operating system short name' {
            $result = Sampler\Get-OperatingSystemShortName

            $result | Should -Be 'Linux'
        }
    }
}
