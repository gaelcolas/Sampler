Param (
    [string]
    $VariableNamePrefix =  $(try {property VariableNamePrefix} catch {''}),

    [switch]
    $ForceEnvironmentVariables = $(try {property ForceEnvironmentVariables} catch {$false})
)

# Synopsis: Using Build Helpers to Set default environment variables
task Set_Build_Environment_Variables {
    $BH_Params = @{
        variableNamePrefix = $VariableNamePrefix
        ErrorVariable      = 'err'
        ErrorAction        = 'SilentlyContinue'
        Force              = $ForceEnvironmentVariables
        Verbose            = $verbose
    }

    Set-BuildEnvironment @BH_Params
    foreach ($e in $err) {
        Write-Build Red $e
    }
}