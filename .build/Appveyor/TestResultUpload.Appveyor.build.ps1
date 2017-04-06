Param (
    [io.DirectoryInfo]
    $ProjectPath = (property ProjectPath (Join-Path $PSScriptRoot '../..' -Resolve -ErrorAction SilentlyContinue)),

    [string]
    $BuildOutput = (property BuildOutput 'C:\BuildOutput'),

    [string]
    $ProjectName = (property ProjectName (Split-Path -Leaf (Join-Path $PSScriptRoot '../..')) ),

    [string]
    $PesterOutputFormat = (property PesterOutputFormat 'NUnitXml'),

    [string]
    $BuildSystem = $(try {property BuildSystem} catch {'unknown'}),

    [string]
    $APPVEYOR_JOB_ID = $(try {property APPVEYOR_JOB_ID} catch {})
)

task UploadUnitTestResultsToAppVeyor -If ($BuildSystem -eq 'AppVeyor') {
    
    if (![io.path]::IsPathRooted($BuildOutput)) {
        $BuildOutput = Join-Path -Path $ProjectPath.FullName -ChildPath $BuildOutput
    }

    $TestOutputPath  = [system.io.path]::Combine($BuildOutput,'testResults','unit',$PesterOutputFormat)
    $TestResultFiles = Get-ChildItem -Path $TestOutputPath -Filter *.xml
    $TestResultFiles | Add-TestResultToAppveyor
}

task BuildSys {
    $BuildSystem
    Gci Env:\ | ? { $_.Name -in @('APPVEYOR_BUILD_FOLDER','BuildSystem','ProjectPath','BranchName','CommitMessage','BuildNumber','ProjectName','PSModuleManifest','PSModulePath') -or
                    $_.Name -match 'appveyor' }

}