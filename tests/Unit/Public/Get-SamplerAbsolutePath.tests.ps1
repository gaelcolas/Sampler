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

Describe 'Get-SamplerAbsolutePath' {
    Context 'When both Path and RelativeTo is a relative path' {
        BeforeAll {
            Push-Location -StackName 'Get-SamplerAbsolutePath'

            Set-Location -Path $TestDrive
        }

        AfterAll {
            Pop-Location -StackName 'Get-SamplerAbsolutePath'
        }

        It 'Should return the correct expanded path' {
            $result = Get-SamplerAbsolutePath -Path './testResult' -RelativeTo './output'

            if ($PSVersionTable.Version.Major -eq 5 )
            {
                $result -replace '\\','/' | Should -Be ((Join-Path -Path $TestDrive -ChildPath './output/testResult') -replace '\\','/')
            }
            else
            {
                $result -replace '\\','/' | Should -Be ((Join-Path -Path $TestDrive -ChildPath 'output/testResult') -replace '\\','/')
            }

        }
    }

    Context 'When Path is relative and RelativeTo is absolute' {
        It 'Should return the correct expanded path' {
            $result = Get-SamplerAbsolutePath -Path './testResult' -RelativeTo $TestDrive

            if ($PSVersionTable.Version.Major -eq 5 )
            {
                $result -replace '\\','/' | Should -Be ((Join-Path -Path $TestDrive -ChildPath './testResult') -replace '\\','/')
            }
            else
            {
                $result -replace '\\','/' | Should -Be ((Join-Path -Path $TestDrive -ChildPath 'testResult') -replace '\\','/')
            }
        }
    }

    Context 'When Path is absolute and RelativeTo is relative' {
        It 'Should return the correct expanded path' {
            $result = Get-SamplerAbsolutePath -Path "$TestDrive/testResult" -RelativeTo './output'

            $result -replace '\\','/' | Should -Be ((Join-Path -Path $TestDrive -ChildPath 'testResult') -replace '\\','/')
        }
    }

    Context 'When Path is absolute and RelativeTo is rooted' {
        It 'Should return the correct expanded path' {
            $result = Get-SamplerAbsolutePath -Path "$TestDrive/testResult" -RelativeTo '/output'

            $result -replace '\\','/' | Should -Be ((Join-Path -Path $TestDrive -ChildPath 'testResult') -replace '\\','/')
        }
    }

    Context 'When both Path and RelativeTo is rooted' {
        BeforeAll {
            Push-Location -StackName 'Get-SamplerAbsolutePath'

            Set-Location -Path $TestDrive
        }

        AfterAll {
            Pop-Location -StackName 'Get-SamplerAbsolutePath'
        }

        It 'Should return the correct expanded path' {
            $result = Get-SamplerAbsolutePath -Path "/testResult" -RelativeTo '/output'

            $result -replace '\\','/' | Should -Be ((Join-Path -Path $PWD.drive.root -ChildPath 'testResult') -replace '\\','/')
        }
    }
}
