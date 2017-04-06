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
    
    'Set-BuildEnvironment'
    Set-BuildEnvironment -variableNamePrefix $VariableNamePrefix -ErrorVariable err -ErrorAction SilentlyContinue -Force:$ForceEnvironmentVariables -Verbose
    foreach ($e in $err) {
        Write-Host $e
    }
    Gci Env:\ | ? { $_.Name -in @('APPVEYOR_BUILD_FOLDER','BuildSystem','ProjectPath','BranchName','CommitMessage','BuildNumber','ProjectName','PSModuleManifest','PSModulePath') -or
                    $_.Name -match 'appveyor' }

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