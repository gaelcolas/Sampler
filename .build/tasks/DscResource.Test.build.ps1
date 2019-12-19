Param (
    # Project path
    [Parameter()]
    [string]
    $ProjectPath = (property ProjectPath $BuildRoot),

    [Parameter()]
    # Base directory of all output (default to 'output')
    [string]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [string]
    $ProjectName = (property ProjectName $(
            (Get-ChildItem $BuildRoot\*\*.psd1 | Where-Object {
                    ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                    $(try {
                            Test-ModuleManifest $_.FullName -ErrorAction Stop
                        }
                        catch {
                            $false
                        }) }
            ).BaseName
        )
    ),

    [Parameter()]
    [string]
    $ModuleVersion = (property ModuleVersion $(
            try {
                (gitversion | ConvertFrom-Json -ErrorAction Stop).InformationalVersion
            }
            catch {
                Write-Verbose "Error attempting to use GitVersion $($_)"
                ''
            }
        )),

    [Parameter()]
    [string]
    $DscTestOutputFolder = (property DscTestOutputFolder 'testResults'),

    [Parameter()]
    [string]
    $DscTestOutputFormat = (property DscTestOutputFormat ''),

    [Parameter()]
    [string[]]
    $DscTestScript = (property DscTestScript ''),

    [Parameter()]
    [string[]]
    $DscTestTag = (property DscTestTag @()),

    [Parameter()]
    [string[]]
    $DscTestExcludeTag = (property DscTestExcludeTag @()),

    # Build Configuration object
    [Parameter()]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Making sure the Module meets some quality standard (help, tests)
task Invoke_DscResource_tests {
    if (!(Split-Path -isAbsolute $OutputDirectory))
    {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory
        Write-Build Yellow "Absolute path to Output Directory is $OutputDirectory"
    }

    if (!(Split-Path -isAbsolute $DscTestOutputFolder))
    {
        $DscTestOutputFolder = Join-Path $OutputDirectory $DscTestOutputFolder
    }

    if (!(Test-Path $DscTestOutputFolder))
    {
        Write-Build Yellow "Creating folder $DscTestOutputFolder"
        $null = New-Item -ItemType Directory -force $DscTestOutputFolder -ErrorAction Stop
    }

    $DscTestScript = $DscTestScript.Where{ ![string]::IsNullOrEmpty($_) }
    $DscTestTag = $DscTestTag.Where{ ![string]::IsNullOrEmpty($_) }
    $DscTestExcludeTag = $DscTestExcludeTag.Where{ ![string]::IsNullOrEmpty($_) }

    $DefaultDscTestParams = @{
        OutputFormat = 'NUnitXML'
        OutputFile   = $DscTestOutputFullPath
        PassThru     = $true
        # ProjectPath  = $ProjectPath
    }

    # Build.ps1 parameters should be top priority
    # BuildInfo values should come next
    # Otherwise we should set some defaults
    Import-Module Pester,DscResource.Test -ErrorAction Stop
    $DscTestCmd = Get-Command Invoke-DscResourceTest
    foreach ($ParamName in $DscTestCmd.Parameters.Keys)
    {
        $TaskParamName = "DscTest$ParamName"
        if (!(Get-Variable -Name $TaskParamName -ValueOnly -ErrorAction SilentlyContinue) -and ($DscTestBuildConfig = $BuildInfo.DscTest))
        {
            # The Variable is set to '' so we should try to use the Config'd one if exists
            if ($ParamValue = $DscTestBuildConfig.($ParamName))
            {
                Write-Build DarkGray "Using $TaskParamName from Build Config"
                Set-Variable -Name $TaskParamName -Value $ParamValue
            } # or use a default if available
            elseif ($DefaultDscTestParams.ContainsKey($ParamName))
            {
                Write-Build DarkGray "Using $TaskParamName from Defaults"
                Set-Variable -Name $TaskParamName -Value $DefaultDscTestParams.($ParamName)
            }
        }
        else
        {
            Write-Build DarkGray "Using $TaskParamName from Build Invocation Parameters"
        }
    }


    "`tProject Path  = $ProjectPath"
    "`tProject Name  = $ProjectName"
    "`tTest Scripts  = $($DscTestScript -join ', ')"
    "`tTags          = $($DscTestTag -join ', ')"
    "`tExclude Tags  = $($DscTestExcludeTag -join ', ')"
    "`tModuleVersion = $ModuleVersion"
    "`tBuildModuleOutput = $BuildModuleOutput"



    if ([String]::IsNullOrEmpty($ModuleVersion))
    {
        $ModuleInfo = Import-PowerShellDataFile "$BuildModuleOutput/$ProjectName/*/$ProjectName.psd1" -ErrorAction Stop
        if ($PreReleaseTag = $ModuleInfo.PrivateData.PSData.Prerelease)
        {
            $ModuleVersion = $ModuleInfo.ModuleVersion + "-" + $PreReleaseTag
        }
        else
        {
            $ModuleVersion = $ModuleInfo.ModuleVersion
        }
    }
    else
    {
        $ModuleVersion, $BuildMetadata = $ModuleVersion -split '\+', 2
        $ModuleVersionFolder, $PreReleaseTag = $ModuleVersion -split '\-', 2
    }

    $os = if ($isWindows -or $PSVersionTable.PSVersion.Major -le 5)
    {
        'Windows'
    }
    elseif ($isMacOS)
    {
        'MacOS'
    }
    else
    {
        'Linux'
    }

    $PSVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion
    $DscTestOutputFileFileName = "DscTest_{0}_v{1}.{2}.{3}.xml" -f $ProjectName, $ModuleVersion, $os, $PSVersion
    $DscTestOutputFullPath = Join-Path $DscTestOutputFolder "$($DscTestOutputFormat)_$DscTestOutputFileFileName"



    $DscTestParams = @{
        OutputFormat = $DscTestOutputFormat
        OutputFile   = $DscTestOutputFullPath
        PassThru     = $true
    }

    if ($DscTestModule)
    {
        $DscTestParams.Add('Module', $DscTestModule)
    }
    elseif ($DscTestFullyQualifiedModule)
    {
        $DscTestParams.Add('FullyQualifiedModule', $DscTestFullyQualifiedModule)
    }
    else
    {
        $DscTestParams.Add('ProjectPath', $ProjectPath)
    }

    if ($DscTestExcludeTag.count -gt 0)
    {
        $DscTestParams.Add('ExcludeTag', $DscTestExcludeTag)
    }

    if ($DscTestTag.Count -gt 0)
    {
        $DscTestParams.Add('Tag', $DscTestTag)
    }

    # Test folders is specified, override invoke-DscResourceTest internal default
    if ($DscTestScript.count -gt 0)
    {
        $DscTestParams.Add('Script', @())
        Write-Build DarkGray " Adding DscTestScript to params"
        foreach ($TestFolder in $DscTestScript)
        {
            if (!(Split-Path -isAbsolute $TestFolder))
            {
                $TestFolder = Join-Path $ProjectPath $TestFolder
            }

            Write-Build DarkGray "      ... $TestFolder"
            # The Absolute path to this folder exists, adding to the list of DscTest scripts to run
            if (Test-Path $TestFolder)
            {
                $DscTestParams.Script += $TestFolder
            }
        }
    }

    foreach ($ParamName in $DscTestCmd.Parameters.keys)
    {
        $ParamValueFromScope = (Get-Variable "DscTest$ParamName" -ValueOnly -ErrorAction SilentlyContinue)
        if (!$DscTestParams.ContainsKey($ParamName) -and $ParamValueFromScope)
        {
            $DscTestParams.Add($ParamName, $ParamValueFromScope)
        }
    }
    Write-Verbose -Message ($DscTestParams | ConvertTo-Json)
    $script:TestResults = Invoke-DscResourceTest @DscTestParams
    $DscTestResultObjectCliXml = Join-Path $DscTestOutputFolder "DscTestObject_$DscTestOutputFileFileName"
    $null = $script:TestResults | Export-CliXml -Path $DscTestResultObjectCliXml -Force

}

# Synopsis: This task ensures the build job fails if the test aren't successful.
task Fail_Build_if_DscResource_Tests_failed {
    "Asserting that no test failed"

    if (!(Split-Path -isAbsolute $OutputDirectory)) {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory
        Write-Build Yellow "Absolute path to Output Directory is $OutputDirectory"
    }

    if (!(Split-Path -isAbsolute $DscTestOutputFolder)) {
        $DscTestOutputFolder = Join-Path $OutputDirectory $DscTestOutputFolder
    }

    $os = if ($isWindows -or $PSVersionTable.PSVersion.Major -le 5) {
        'Windows'
    }
    elseif ($isMacOS) {
        'MacOS'
    }
    else {
        'Linux'
    }

    if ([String]::IsNullOrEmpty($ModuleVersion)) {
        $ModuleInfo = Import-PowerShellDataFile "$OutputDirectory/$ProjectName/*/$ProjectName.psd1" -ErrorAction Stop
        if ($PreReleaseTag = $ModuleInfo.PrivateData.PSData.Prerelease) {
            $ModuleVersion = $ModuleInfo.ModuleVersion + "-" + $PreReleaseTag
        }
        else {
            $ModuleVersion = $ModuleInfo.ModuleVersion
        }
    }
    else {
        $ModuleVersion, $BuildMetadata = $ModuleVersion -split '\+', 2
        $ModuleVersionFolder, $PreReleaseTag = $ModuleVersion -split '\-', 2
    }

    $PSVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion
    $DscTestOutputFileFileName = "DscTest_{0}_v{1}.{2}.{3}.xml" -f $ProjectName, $ModuleVersion, $os, $PSVersion
    $DscTestResultObjectClixml = Join-Path $DscTestOutputFolder "DscTestObject_$DscTestOutputFileFileName"
    Write-Build White "`tDscTest Output Object = $DscTestResultObjectClixml"


    if (-Not (Test-Path $DscTestResultObjectClixml)) {
        Throw "No command were tested. $DscTestResultObjectClixml not found"
    }
    else {
        $DscTestObject = Import-Clixml -Path $DscTestResultObjectClixml -ErrorAction Stop
        assert ($DscTestObject.FailedCount -eq 0) ('Failed {0} tests. Aborting Build' -f $DscTestObject.FailedCount)
    }

}

# Synopsis: Uploading Unit Test results to AppVeyor
task Upload_DscResourceTest_Results_To_AppVeyor -If { (property BuildSystem 'unknown') -eq 'AppVeyor' } {

    if (!(Split-Path -isAbsolute $OutputDirectory)) {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory
        Write-Build Yellow "Absolute path to Output Directory is $OutputDirectory"
    }

    if (!(Split-Path -isAbsolute $DscTestOutputFolder)) {
        $DscTestOutputFolder = Join-Path $OutputDirectory $DscTestOutputFolder
    }

    if (!(Test-Path $DscTestOutputFolder)) {
        Write-Build Yellow "Creating folder $DscTestOutputFolder"
        $null = New-Item -ItemType Directory -force $DscTestOutputFolder -ErrorAction Stop
    }

    $os = if ($isWindows -or $PSVersionTable.PSVersion.Major -le 5) {
        'Windows'
    }
    elseif ($isMacOS) {
        'MacOS'
    }
    else {
        'Linux'
    }

    if ([String]::IsNullOrEmpty($ModuleVersion)) {
        $ModuleInfo = Import-PowerShellDataFile "$OutputDirectory/$ProjectName/*/$ProjectName.psd1" -ErrorAction Stop
        if ($PreReleaseTag = $ModuleInfo.PrivateData.PSData.Prerelease) {
            $ModuleVersion = $ModuleInfo.ModuleVersion + "-" + $PreReleaseTag
        }
        else {
            $ModuleVersion = $ModuleInfo.ModuleVersion
        }
    }
    else {
        $ModuleVersion, $BuildMetadata = $ModuleVersion -split '\+', 2
        $ModuleVersionFolder, $PreReleaseTag = $ModuleVersion -split '\-', 2
    }

    $PSVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion
    $DscTestOutputFileFileName = "DscResource.Test_{0}_v{1}.{2}.{3}.xml" -f $ProjectName, $ModuleVersion, $os, $PSVersion
    $DscTestOutputFullPath = Join-Path $DscTestOutputFolder "$($DscTestOutputFormat)_$DscTestOutputFileFileName"

    $TestResultFile = Get-Item $DscTestOutputFullPath -ErrorAction Ignore
    if ($TestResultFile) {
        Write-Build Green "  Uploading test results $TestResultFile to Appveyor"
        $TestResultFile | Add-TestResultToAppveyor
        Write-Build Green "  Upload Complete"
    }
}

# Synopsis: Meta task that runs Quality Tests, and fails if they're not successful
task DscResource_Tests_Stop_On_Fail Invoke_DscResource_tests, Upload_DscResourceTest_Results_To_AppVeyor, Fail_Build_if_DscResource_Tests_failed
