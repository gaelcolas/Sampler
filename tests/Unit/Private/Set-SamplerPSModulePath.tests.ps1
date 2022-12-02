BeforeAll {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\SetSamplerTaskVariableTestHelpers.psm1') -Force

    if (-not (Get-Variable -Name IsWindows -ErrorAction SilentlyContinue))
    {
        $IsWindows = Test-IsWindows
    }

    $script:moduleName = 'Sampler'

    #if we are running within the build process, store the paths in environment variables for later use
    #when debugging the tests outside of the build process
    if ($invokeBuildModule)
    {
        $env:SamplerRequiredModulesPath = $requiredModulesPath
        $env:SamplerBuildModuleOutput = $buildModuleOutput

        $inModuleScopeParameters = @{
            requiredModulesPath = $requiredModulesPath
            buildModuleOutput   = $buildModuleOutput
        }
    }
    else
    {
        $inModuleScopeParameters = @{
            requiredModulesPath = $env:SamplerRequiredModulesPath
            buildModuleOutput   = $env:SamplerBuildModuleOutput
        }
    }

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 2)
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' > $null
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

Describe 'Set-SamplerPSModulePath' {

    BeforeEach {
        $oldPSModulePath = $env:PSModulePath
    }

    AfterEach {
        $env:PSModulePath = $oldPSModulePath
    }

    Context 'Testing return values' {

        BeforeAll {
            if ($IsWindows)
            {
                $inModuleScopeParameters.PSModulePath = ('C:\Path1', 'C:\Path2' -join [System.IO.Path]::PathSeparator)
            }
            else
            {
                $inModuleScopeParameters.PSModulePath = ('/Path1', '/Path2' -join [System.IO.Path]::PathSeparator)
            }
        }

        AfterAll {
            $inModuleScopeParameters.Remove('PSModulePath')
        }

        It 'Should return exactly one object when PassThru is specified' {
            InModuleScope -ScriptBlock {
                $result = Set-SamplerPSModulePath -PSModulePath $PSModulePath -BuiltModuleSubdirectory $buildModuleOutput -RequiredModulesDirectory $requiredModulesPath -PassThru
                $result.Count | Should -Be 1
            } -Parameters $inModuleScopeParameters
        }

        It 'Should return an object of type string when PassThru is specified' {
            InModuleScope -ScriptBlock {
                $result = Set-SamplerPSModulePath -PSModulePath $PSModulePath -BuiltModuleSubdirectory $buildModuleOutput -RequiredModulesDirectory $requiredModulesPath -PassThru
                $result | Should -BeOfType [string]
            } -Parameters $inModuleScopeParameters
        }

        It 'Should return nothing when PassThru is not specified' {
            InModuleScope -ScriptBlock {
                $result = Set-SamplerPSModulePath -PSModulePath $PSModulePath -BuiltModuleSubdirectory $buildModuleOutput -RequiredModulesDirectory $requiredModulesPath
                $result | Should -BeNullOrEmpty
            } -Parameters $inModuleScopeParameters
        }

        It 'Should return nothing when PassThru is not specified' {
            InModuleScope -ScriptBlock {
                $result = Set-SamplerPSModulePath -PSModulePath $PSModulePath -BuiltModuleSubdirectory $buildModuleOutput -RequiredModulesDirectory $requiredModulesPath
                $result | Should -BeNullOrEmpty
            } -Parameters $inModuleScopeParameters
        }
    }

    Context 'Testing ShouldProcess' {

        BeforeAll {
            if ($IsWindows)
            {
                $inModuleScopeParameters.PSModulePath = ('C:\Path1', 'C:\Path2' -join [System.IO.Path]::PathSeparator)
            }
            else
            {
                $inModuleScopeParameters.PSModulePath = ('/Path1', '/Path2' -join [System.IO.Path]::PathSeparator)
            }
        }

        AfterAll {
            $inModuleScopeParameters.Remove('PSModulePath')
        }
        It 'Should not alter the PSModulePath when WhatIf is specified' {
            InModuleScope -ScriptBlock {
                $oldPSModulePath = $env:PSModulePath

                Set-SamplerPSModulePath -PSModulePath $PSModulePath -BuiltModuleSubdirectory $buildModuleOutput -RequiredModulesDirectory $requiredModulesPath -WhatIf

                $env:PSModulePath | Should -Be $oldPSModulePath
            } -Parameters $inModuleScopeParameters
        }
    }

    Context 'Setting the PSModulePath by predefined value' {
        BeforeAll {
            if ($IsWindows)
            {
                $inModuleScopeParameters.PSModulePath = ('C:\Path1', 'C:\Path2' -join [System.IO.Path]::PathSeparator)
            }
            else
            {
                $inModuleScopeParameters.PSModulePath = ('/Path1', '/Path2' -join [System.IO.Path]::PathSeparator)
            }
        }

        AfterAll {
            $inModuleScopeParameters.Remove('PSModulePath')
        }

        It 'Should set the PSModulePath to a defined value with BuiltModuleSubdirectory and RequiredModulesDirectory specified' {
            InModuleScope -ScriptBlock {
                $param = @{
                    PSModulePath             = $PSModulePath
                    BuiltModuleSubdirectory  = $buildModuleOutput
                    RequiredModulesDirectory = $requiredModulesPath
                }
                Set-SamplerPSModulePath @param

                $env:PSModulePath | Should -BeExactly ($buildModuleOutput, $requiredModulesPath, $PSModulePath -join [System.IO.Path]::PathSeparator)
            } -Parameters $inModuleScopeParameters
        }

        It 'Should set the PSModulePath to a defined value with RequiredModulesDirectory specified' {
            InModuleScope -ScriptBlock {
                $param = @{
                    PSModulePath             = $PSModulePath
                    RequiredModulesDirectory = $requiredModulesPath
                    WarningAction            = 'SilentlyContinue'
                }
                Set-SamplerPSModulePath @param

                $env:PSModulePath | Should -BeExactly ($requiredModulesPath, $PSModulePath -join [System.IO.Path]::PathSeparator)
            } -Parameters $inModuleScopeParameters
        }

        It 'Should set the PSModulePath to a defined value with BuiltModuleSubdirectory specified' {
            InModuleScope -ScriptBlock {
                $param = @{
                    PSModulePath            = $PSModulePath
                    BuiltModuleSubdirectory = $buildModuleOutput
                    WarningAction           = 'SilentlyContinue'
                }
                Set-SamplerPSModulePath @param

                $env:PSModulePath | Should -BeExactly ($buildModuleOutput, $PSModulePath -join [System.IO.Path]::PathSeparator)
            } -Parameters $inModuleScopeParameters
        }

        It 'Should set the PSModulePath to a defined value' {
            InModuleScope -ScriptBlock {
                $param = @{
                    PSModulePath  = $PSModulePath
                    WarningAction = 'SilentlyContinue'
                }
                Set-SamplerPSModulePath @param

                $env:PSModulePath | Should -BeExactly $PSModulePath
            } -Parameters $inModuleScopeParameters
        }
    }

    Context 'Setting the PSModulePath using SetSystemDefault' -Skip:(-not $isWindows) {

        It 'Should set the PSModulePath to system default when SetSystemDefault is specified' {
            InModuleScope -ScriptBlock {

                $systemPSModulePath = Get-SystemPSModulePath

                $param = @{
                    SetSystemDefault = $true
                    WarningAction    = 'SilentlyContinue'
                }
                Set-SamplerPSModulePath @param

                $env:PSModulePath | Should -BeExactly $systemPSModulePath
            }
        }

        It 'Should set the PSModulePath to system default when SetSystemDefault is specified with BuiltModuleSubdirectory and RequiredModulesDirectory' -Skip:(-not $isWindows) {
            InModuleScope -ScriptBlock {

                $systemPSModulePath = Get-SystemPSModulePath

                $param = @{
                    SetSystemDefault         = $true
                    BuiltModuleSubdirectory  = $buildModuleOutput
                    RequiredModulesDirectory = $requiredModulesPath
                }
                Set-SamplerPSModulePath @param

                $env:PSModulePath | Should -BeExactly ($buildModuleOutput, $requiredModulesPath, $systemPSModulePath -join [System.IO.Path]::PathSeparator)
            } -Parameters $inModuleScopeParameters
        }

        It 'Should set the PSModulePath to system default when SetSystemDefault is specified with RequiredModulesDirectory' -Skip:(-not $isWindows) {
            InModuleScope -ScriptBlock {

                $systemPSModulePath = Get-SystemPSModulePath

                $param = @{
                    SetSystemDefault         = $true
                    RequiredModulesDirectory = $requiredModulesPath
                    WarningAction            = 'SilentlyContinue'
                }
                Set-SamplerPSModulePath @param

                $env:PSModulePath | Should -BeExactly ($requiredModulesPath, $systemPSModulePath -join [System.IO.Path]::PathSeparator)

            } -Parameters $inModuleScopeParameters
        }

        It 'Should set the PSModulePath to system default when SetSystemDefault is specified with BuiltModuleSubdirectory' -Skip:(-not $isWindows) {
            InModuleScope -ScriptBlock {

                $systemPSModulePath = Get-SystemPSModulePath

                $param = @{
                    SetSystemDefault        = $true
                    BuiltModuleSubdirectory = $buildModuleOutput
                    WarningAction           = 'SilentlyContinue'
                }
                Set-SamplerPSModulePath @param

                $env:PSModulePath | Should -BeExactly ($buildModuleOutput, $systemPSModulePath -join [System.IO.Path]::PathSeparator)

            } -Parameters $inModuleScopeParameters
        }

        It 'Should set the PSModulePath to system default when SetSystemDefault is specified with BuiltModuleSubdirectory' -Skip:(-not $isWindows) {
            InModuleScope -ScriptBlock {

                $systemPSModulePath = Get-SystemPSModulePath

                $param = @{
                    SetSystemDefault        = $true
                    BuiltModuleSubdirectory = $buildModuleOutput
                    WarningAction           = 'SilentlyContinue'
                }
                Set-SamplerPSModulePath @param

                $env:PSModulePath | Should -BeExactly ($buildModuleOutput, $systemPSModulePath -join [System.IO.Path]::PathSeparator)

            } -Parameters $inModuleScopeParameters
        }

        It 'Should set the PSModulePath to system default when SetSystemDefault is specified with BuiltModuleSubdirectory and RequiredModulesDirectory and RemoveProgramFiles is specified' -Skip:(-not $isWindows) {
            InModuleScope -ScriptBlock {

                if ((Get-SystemPSModulePath) -notlike '*Program Files*')
                {
                    Set-ItResult -Skipped -Because "'*Program Files*' is not part of machine's PSModulePath"
                }

                $param = @{
                    SetSystemDefault         = $true
                    BuiltModuleSubdirectory  = $buildModuleOutput
                    RequiredModulesDirectory = $requiredModulesPath
                    RemoveProgramFiles       = $true
                }
                Set-SamplerPSModulePath @param

                $env:PSModulePath | Should -Not -Match '.+Program Files.(Windows)?PowerShell.(7.)?Modules'

            } -Parameters $inModuleScopeParameters
        }

        It 'Should set the PSModulePath to system default when SetSystemDefault is specified with BuiltModuleSubdirectory and RequiredModulesDirectory and ProgramFiles path should be present' -Skip:(-not $isWindows) {
            InModuleScope -ScriptBlock {

                if ((Get-SystemPSModulePath) -notlike '*Program Files*')
                {
                    Set-ItResult -Skipped -Because "'*Program Files*' is not part of machine's PSModulePath"
                }

                $param = @{
                    SetSystemDefault         = $true
                    BuiltModuleSubdirectory  = $buildModuleOutput
                    RequiredModulesDirectory = $requiredModulesPath
                }
                Set-SamplerPSModulePath @param

                $env:PSModulePath | Should -Match '.+Program Files.(Windows)?PowerShell.(7.)?Modules'

            } -Parameters $inModuleScopeParameters
        }

        It 'Should set the PSModulePath to system default when SetSystemDefault is specified with BuiltModuleSubdirectory and RequiredModulesDirectory and RemoveWindows is specified' -Skip:(-not $isWindows) {
            InModuleScope -ScriptBlock {

                $param = @{
                    SetSystemDefault         = $true
                    BuiltModuleSubdirectory  = $buildModuleOutput
                    RequiredModulesDirectory = $requiredModulesPath
                    RemoveWindows            = $true
                    WarningAction            = 'SilentlyContinue'
                }
                Set-SamplerPSModulePath @param

                $env:PSModulePath | Should -Not -BeLike '*Windows\System32*'

            } -Parameters $inModuleScopeParameters
        }

        It 'Should set the PSModulePath to system default when SetSystemDefault is specified with BuiltModuleSubdirectory and RequiredModulesDirectory and Windows path present' -Skip:(-not $isWindows) {

            InModuleScope -ScriptBlock {

                $param = @{
                    SetSystemDefault         = $true
                    BuiltModuleSubdirectory  = $buildModuleOutput
                    RequiredModulesDirectory = $requiredModulesPath
                }
                Set-SamplerPSModulePath @param

                $env:PSModulePath | Should -BeLike '*Windows\System32*'

            } -Parameters $inModuleScopeParameters
        }
    }

    Context "Setting the PSModulePath using the current user's PSModulePath" {

        It "Should set the PSModulePath to user's PSModulePath with BuiltModuleSubdirectory and RequiredModulesDirectory specified" {
            InModuleScope -ScriptBlock {

                $userPSModulePath = Get-UserPSModulePath

                $param = @{
                    BuiltModuleSubdirectory  = $buildModuleOutput
                    RequiredModulesDirectory = $requiredModulesPath
                }
                Set-SamplerPSModulePath @param

                $env:PSModulePath | Should -BeExactly (Remove-DuplicateElementsInPath -Path ($buildModuleOutput, $requiredModulesPath, $userPSModulePath -join [System.IO.Path]::PathSeparator))
            } -Parameters $inModuleScopeParameters
        }

        It "Should set the PSModulePath to user's PSModulePath with BuiltModuleSubdirectory specified" {
            InModuleScope -ScriptBlock {

                $userPSModulePath = Get-UserPSModulePath

                $param = @{
                    BuiltModuleSubdirectory = $buildModuleOutput
                    WarningAction           = 'SilentlyContinue'
                }
                Set-SamplerPSModulePath @param

                $env:PSModulePath | Should -BeExactly (Remove-DuplicateElementsInPath -Path ($buildModuleOutput, $userPSModulePath -join [System.IO.Path]::PathSeparator))

            } -Parameters $inModuleScopeParameters
        }

        It "Should set the PSModulePath to user's PSModulePath with RequiredModulesDirectory specified" {
            InModuleScope -ScriptBlock {

                $userPSModulePath = Get-UserPSModulePath

                $param = @{
                    RequiredModulesDirectory = $requiredModulesPath
                    WarningAction            = 'SilentlyContinue'
                }
                Set-SamplerPSModulePath @param

                $envPSModulePath = $env:PSModulePath -split [System.IO.Path]::PathSeparator
                $userPSModulePath = (Remove-DuplicateElementsInPath -Path "$userPSModulePath") -split [System.IO.Path]::PathSeparator

                Compare-Object -ReferenceObject $envPSModulePath -DifferenceObject $userPSModulePath | Should -BeNullOrEmpty
                $env:PSModulePath | Should -BeLike "*$requiredModulesPath*"

            } -Parameters $inModuleScopeParameters
        }

    }
}
