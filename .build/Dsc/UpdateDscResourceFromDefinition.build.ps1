Param (

    [io.DirectoryInfo]
    $ProjectPath = (property ProjectPath (Join-Path $PSScriptRoot '../..' -Resolve -ErrorAction SilentlyContinue)),

    [string]
    $ProjectName = (property ProjectName (Split-Path -Leaf (Join-Path $PSScriptRoot '../..')) ),

    [string]
    $LineSeparation = (property LineSeparation ('-' * 78)) 
)

task UpdateDscResource {
    $LineSeparation
    "`t`t`t UPDATING DSC SCRIPT RESOURCE SCHEMAS"
    $LineSeparation
    . $PSScriptRoot\Update-DscResourceFromDefinition.ps1

    $SourceFolder = Join-Path -Path $ProjectPath.FullName -ChildPath $ProjectName
    
    if (Test-Path $SourceFolder) {
        Update-DscResourceFromObjectMetadata -SourceFolder $SourceFolder
    }
}

task updateDscSchema UpdateDscResource