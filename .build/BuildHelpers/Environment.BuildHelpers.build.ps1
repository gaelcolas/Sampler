Param (
    [string]
    $LineSeparation = (property LineSeparation ('-' * 78)) 
)

task SetBuildVariable {
    $LineSeparation
    
    'Set-BuildVariable'
    Set-BuildVariable -variableNamePrefix ''
    <# Creates:
        $ProjectPath
        $BranchName
        $CommitMessage
        $BuildNumber
        $ProjectName
        $PSModuleManifest
        $PSModulePath
    #>
}