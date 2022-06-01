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

Describe 'Get-ClassBasedResourceName' {
    BeforeAll {
        $classScriptFilePath = Join-Path -Path $TestDrive -ChildPath 'MockClassBasedResource.ps1'

        $mockScript = @'
[DscResource()]
class MockResourceName
{
    [DscProperty(Key)]
    [System.String]
    $Name

    [DscProperty()]
    [System.String]
    $Parameter1

    [DnsRecordA] Get()
    {
        return @{
            Name = $Name
            Parameter1 = $Parameter1
        }
    }

    [void] Set()
    {
    }

    [System.Boolean] Test()
    {
        return $true
    }
}
'@
        $mockScript | Out-File -FilePath $classScriptFilePath -Encoding 'UTF8' -Force
    }

    It 'Should return the correct resource name' {

        $result = Sampler\Get-ClassBasedResourceName -Path $classScriptFilePath

        $result | Should -Be 'MockResourceName'
    }
}
