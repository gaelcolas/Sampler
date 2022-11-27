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

Describe 'Get-Psm1SchemaName' {
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
        }

        AfterAll {
            InModuleScope -ScriptBlock {
                $script:IsWindows = $mockPreviousIsWindows
                $script:IsMacOS = $mockPreviousIsMacOS
                $script:IsLinux = $mockPreviousIsLinux
            }
        }
    }

    Context 'When schema.psm1 file is invalid' -Skip:($IsMacOS -or $IsLinux) {
        BeforeAll {

            Mock -CommandName Get-Content -MockWith {
                return @'
function MockConfigurationName {
    param (
        [Parameter()]
        [hashtable[]]
        $Parameter1
    )

    Import-DscResource -ModuleName SomeModule
}
'@
            }
        }

        It 'Should not return anything' {
            Sampler\Get-Psm1SchemaName -Path $TestDrive -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Should throw' {
            { Sampler\Get-Psm1SchemaName -Path $TestDrive -ErrorAction Stop } | Should -Throw
        }
    }

    Context 'When schema.psm1 file contains more than 1 configuration' -Skip:($IsMacOS -or $IsLinux) {
        BeforeAll {

            Mock -CommandName Get-Content -MockWith {
                return @'
configuration MockConfigurationName1 {
    param (
        [Parameter()]
        [hashtable[]]
        $Parameter1
    )

    Import-DscResource -ModuleName SomeModule
}

configuration MockConfigurationName2 {
    param (
        [Parameter()]
        [hashtable[]]
        $Parameter1
    )

    Import-DscResource -ModuleName SomeModule
}
'@
            }
        }

        It 'Should not return anything' {
            Sampler\Get-Psm1SchemaName -Path $TestDrive -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Should throw' {
            { Sampler\Get-Psm1SchemaName -Path $TestDrive -ErrorAction Stop } | Should -Throw
        }
    }

    Context 'When schema.psm1 file is valid' -Skip:($IsMacOS -or $IsLinux) {
        BeforeAll {

            Mock -CommandName Get-Content -MockWith {
                return @'
configuration MockConfigurationName {
    param (
        [Parameter()]
        [hashtable[]]
        $Parameter1
    )

    Import-DscResource -ModuleName SomeModule
}
'@
            }
        }

        It 'Should return the correct name of the configuration' {
            $result = Sampler\Get-Psm1SchemaName -Path $TestDrive

            $result | Should -Be MockConfigurationName
        }
    }

}
