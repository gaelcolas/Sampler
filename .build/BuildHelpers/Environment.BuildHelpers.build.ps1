Param (
    [string]
    $LineSeparation = (property LineSeparation ('-' * 78)),

    [string]
    $VariableNamePrefix =  $(try {property VariableNamePrefix} catch {''}),

    [switch]
    $ForceEnvironmentVariables = $(try {property ForceEnvironmentVariables} catch {$false})
)

task SetBuildEnvironment {
    $LineSeparation
    "`t`t`t BUILD HELPERS INIT"
    $LineSeparation
    $BH_Params = @{
        variableNamePrefix = $VariableNamePrefix
        ErrorVariable      = 'err'
        ErrorAction        = 'SilentlyContinue'
        Force              = $ForceEnvironmentVariables
        Verbose            = $verbose
    }
    Set-BuildEnvironment @BH_Params
    foreach ($e in $err) {
        Write-Host $e
    }
}