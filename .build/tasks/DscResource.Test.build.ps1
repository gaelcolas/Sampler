param
(
    # Project path
    [Parameter()]
    [System.String]
    $ProjectPath = (property ProjectPath $BuildRoot),

    [Parameter()]
    # Base directory of all output (default to 'output')
    [System.String]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [System.String]
    $BuiltModuleSubdirectory = (property BuiltModuleSubdirectory ''),

    [Parameter()]
    [System.String]
    $ProjectName = (property ProjectName ''),

    [Parameter()]
    [System.String]
    $DscTestOutputFolder = (property DscTestOutputFolder 'testResults'),

    [Parameter()]
    [System.String]
    $DscTestOutputFormat = (property DscTestOutputFormat ''),

    [Parameter()]
    [System.String[]]
    $DscTestScript = (property DscTestScript ''),

    [Parameter()]
    [System.String[]]
    $DscTestTag = (property DscTestTag @()),

    [Parameter()]
    [System.String[]]
    $DscTestExcludeTag = (property DscTestExcludeTag @()),

    # Build Configuration object
    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)


# Synopsis: Deprecated HQRM task
task DscResource_Tests_Stop_On_Fail {
    Write-Warning -Message "THIS TASK IS DEPRECATED! Please use Invoke_HQRM_Tests_Stop_On_Fail from the module DscResource.Test..."

    throw  "THIS TASK IS DEPRECATED! Please use Invoke_HQRM_Tests_Stop_On_Fail from the module DscResource.Test..."
}
