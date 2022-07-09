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

Describe 'Convert-SamplerHashtableToString' {
    It 'Should convert the hashtable with a single value to the expected string' {
        $result = Sampler\Convert-SamplerHashtableToString -Hashtable @{
            a = 1
        }

        $result | Should -Be 'a=1'
    }

    It 'Should convert the hashtable with two values to the expected string' {
        $result = Sampler\Convert-SamplerHashtableToString -Hashtable @{
            a = 1
            b = 2
        }

        $result | Should -Be 'a=1; b=2'
    }

    It 'Should convert the hashtable with a single child hashtable to the expected string' {
        $result = Sampler\Convert-SamplerHashtableToString -Hashtable @{
            d = @{
                dd = 'abcd'
            }
        }

        $result | Should -Be 'd={dd=abcd}'
    }

    It 'Should convert the hashtable with multiple values and levels to the expected string' {
        $result = Sampler\Convert-SamplerHashtableToString -Hashtable @{
            a = 1
            b = 2
            c = 3
            d = @{
                dd = @{
                    ddd = 'abcd'
                }
            }
        }

        $result | Should -Be 'a=1; b=2; c=3; d={dd={ddd=abcd}}'
    }
}
