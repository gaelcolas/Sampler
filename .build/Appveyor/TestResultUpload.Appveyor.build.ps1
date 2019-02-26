Param (
    [string]
    $OutputDirectory = (property OutputDirectory 'output'),

    [string]
    $ProjectName = (property ProjectName (Split-Path -Leaf $BuildRoot) ),

    [string]
    $PesterOutputFormat = (property PesterOutputFormat 'NUnitXml'),

    [string]
    $APPVEYOR_JOB_ID = $(try {property APPVEYOR_JOB_ID} catch {})
)

# Synopsis: Uploading Unit Test results to AppVeyor
task Upload_Unit_Test_Results_To_AppVeyor -If {(property BuildSystem 'unknown') -eq 'AppVeyor'} {

    if (![io.path]::IsPathRooted($OutputDirectory)) {
        $OutputDirectory = Join-Path -Path $BuildRoot -ChildPath $OutputDirectory
    }

    $TestOutputPath  = [system.io.path]::Combine($OutputDirectory,'testResults','unit',$PesterOutputFormat)
    $TestResultFiles = Get-ChildItem -Path $TestOutputPath -Filter *.xml
    Write-Build Green "  Uploading test results [$($TestResultFiles.Name -join ', ')] to Appveyor"
    $TestResultFiles | Add-TestResultToAppveyor
    Write-Build Green "  Upload Complete"
}