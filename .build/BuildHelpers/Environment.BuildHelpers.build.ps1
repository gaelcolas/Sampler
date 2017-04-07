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
    $PSModulePath = $Env:PSModulePath #waiting on RamblingCookieMonster/BuildHelpers#30
    'Set-BuildEnvironment'
    Set-BuildEnvironment -variableNamePrefix $VariableNamePrefix -ErrorVariable err -ErrorAction SilentlyContinue -Force:$ForceEnvironmentVariables -Verbose

    gci Env:\ | ? {$_.Name -in @('BuildSystemn','ProjectPath','PSModuleManifest')}
    $LineSeparation
    gci Env:\ | ? Name -Match 'Appveyor'
    $LineSeparation
    gci Env:\ | ? Value -Match 'Appveyor'
    
    $Env:PSModulePath = $Env:PSModulePath  ####

    foreach ($e in $err) {
        Write-Host $e
    }
}