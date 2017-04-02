Param (
    [string]
    $BuildSystem = $(try {property BuildSystem} catch {'unknown'}),

    [string]
    $APPVEYOR_JOB_ID = $(try {property APPVEYOR_JOB_ID} catch {}),

    [string]
    $BuildOutput = (property BuildOutput 'C:\BuildOutput'),

    [string]
    $TestOutputPath = (property TestOutputPath 'NUnit')
)

task UploadUnitTestResultsToAppVeyor -If ($BuildSystem -eq 'AppVeyor' -or $env:APPVEYOR_JOB_ID) {

    $TestResultFiles = Get-ChildItem -Path ([io.Path]::Combine($BuildOutput,$TestOutputPath)) -Filter *.xml
    $TestResultFiles | Add-TestResultToAppveyor -verbose
    #foreach ($file in $TestResultFiles) {
    #    (New-Object 'System.Net.WebClient').UploadFile(
    #        "https://ci.appveyor.com/api/testresults/nunit/$APPVEYOR_JOB_ID",
    #        "$ProjectRoot\$file" )
    #}
}

task DoSomethingBeforeFailing {
    '-'*78
    '-'*78
    '-'*78
    '-'*78
    'DO Something'
}

task BuildSys {
    Write-Host $BuildSystem
}