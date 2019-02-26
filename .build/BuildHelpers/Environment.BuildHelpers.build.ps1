Param (
    [string]
    $VariableNamePrefix =  (property VariableNamePrefix ''),

    [switch]
    $ForceEnvironmentVariables = (property ForceEnvironmentVariables $false)
)

# Synopsis: Using Build Helpers to Set Normalized environment variables
task Set_Build_Environment_Variables {
    $BH_Params = @{
        variableNamePrefix = $VariableNamePrefix
        ErrorVariable      = 'err'
        ErrorAction        = 'SilentlyContinue'
        Force              = $ForceEnvironmentVariables
    }

    Set-BuildEnvironment @BH_Params
    foreach ($e in $err) {
        Write-Build Magenta $e
    }
}