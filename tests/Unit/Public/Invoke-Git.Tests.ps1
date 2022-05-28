BeforeAll {
    $script:moduleName = 'Sampler'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 2)
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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

Describe 'Invoke-Git' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Stub to be able to mock git executable.
            function script:git
            {
                param
                (
                    [Parameter(Mandatory = $true)]
                    [System.String[]]
                    $Argument
                )

                throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:LASTEXITCODE = 0
        }
    }

    AfterAll {
        InModuleScope -ScriptBlock {
            Remove-Item 'function:git'
        }
    }

    Context 'When successfully calling git' {
        BeforeAll {
            Mock -CommandName 'git'
        }

        It 'Should call git with one expected argument' {
            { Sampler\Invoke-Git -Argument @('log') } | Should -Not -Throw

            Should -Invoke -CommandName 'git' -ParameterFilter {
                $Argument -eq 'log'
            } -Exactly -Times 1 -Scope It
        }

        It 'Should call git with two expected arguments' {
            { Sampler\Invoke-Git -Argument @('describe', '--contains') } | Should -Not -Throw

            Should -Invoke -CommandName 'git' -ParameterFilter {
                $Argument -contains 'describe' -and
                $Argument -contains '--contains'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When git returns an error' {
        BeforeAll {
            Mock -CommandName 'git'

            InModuleScope -ScriptBlock {
                $script:LASTEXITCODE = 1
            }
        }

        AfterAll {
            InModuleScope -ScriptBlock {
                $script:LASTEXITCODE = 0
            }
        }

        It 'Should throw the correct error' {
            { Sampler\Invoke-Git -Argument @('log') } | Should -Throw -ExpectedMessage 'git returned exit code 1 indicated failure.'

            Should -Invoke -CommandName 'git' -ParameterFilter {
                $Argument -eq 'log'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When git does not exist' {
        It 'Should throw an error' {
            { Sampler\Invoke-Git -Argument @('log') } | Should -Throw -ExpectedMessage 'git: StubNotImplemented'
        }
    }
}
