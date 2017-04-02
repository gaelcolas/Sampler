Param (
    [string]
    $LineSeparation = (property LineSeparation ('-' * 78)),

    [string]
    $VariableNamePrefix =  $(try {property VariableNamePrefix} catch {''}),

    [switch]
    $ForceEnvironmentVariables = $(try {property ForceEnvironmentVariables} catch {$false})
)

task SetBuildEnvironment -if {(Get-Command Set-BuildEnvironment).Parameters.variableNamePrefix} { #Until PR pushed to gallery
    $LineSeparation
    
    'Set-BuildEnvironment'
    Set-BuildEnvironment -variableNamePrefix $VariableNamePrefix -ErrorVariable err -ErrorAction SilentlyContinue -Force:$ForceEnvironmentVariables
    foreach ($e in $err) {
        Write-Host $e
    }
    
    <# Creates:
        $BuildSystem
        $ProjectPath
        $BranchName
        $CommitMessage
        $BuildNumber
        $ProjectName
        $PSModuleManifest
        $PSModulePath
    #>
}