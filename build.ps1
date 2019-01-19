[CmdletBinding()]
param(

    [Parameter(Position = 0)]
    [string[]]$Tasks = '.',

    $BuildConfig = './Build.psd1',

    # A Specific folder to build into
    $OutputDirectory = './output',

    $BuildOutput = 'output',

    $RequiredModulesDirectory = './output/modules',

    [switch]$ResolveDependency
)

Process {

    if ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {
        # Only run this within InvokeBuild (Look at the Begin block at the bottom of this script)
        return
    }

    Push-Location -Path $PSScriptRoot -StackName BeforeBuild

    try {
        Write-Host -ForeGroundColor magenta "[build] Parsing defined tasks"

        $BuildInfo = Import-PowerShellDataFile -Path $BuildConfig
        if ($BuildInfo.TaskHeader) { Set-BuildHeader ([scriptblock]::Create($BuildInfo.TaskHeader)) }

        # Loading Build Tasks defined in the .build/ folder
        Get-ChildItem -Path ".build/" -Recurse -Include *.ps1 | Foreach-Object {
            "Importing file $($_.BaseName)" | Write-Verbose
            . $_.FullName
        }

        task . Clean,
        Set_Build_Environment_Variables, {
            "Doing blank task"
            #Build-Module -SourcePath $BuildConfig
        }
    }
    finally {
        Write-Host -ForeGroundColor magenta "[build] Executing requested workflow: $($Tasks -join ', ')"
        Pop-Location -StackName BeforeBuild
    }


    # Defining the Default task 'workflow' when invoked without -tasks parameter
    # task .  Clean,
    #     Set_Build_Environment_Variables,
    #     Pester_Quality_Tests_Stop_On_Fail,
    #     Copy_Source_To_Module_BuildOutput,
    #     Merge_Source_Files_To_PSM1,
    #     Clean_Empty_Folders_from_Build_Output,
    #     Update_Module_Manifest,
    #     Run_Unit_Tests,
    #     Upload_Unit_Test_Results_To_AppVeyor,
    #     Fail_Build_if_Unit_Test_Failed,
    #     Fail_if_Last_Code_Converage_is_Under_Threshold,
    #     IntegrationTests,
    #     Deploy_with_PSDeploy


}

Begin {
    if ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {
        Write-Host -foregroundColor Green "[pre-build] Starting Build Init"
        Push-Location $PSScriptRoot -StackName BuildModule
    }

    if ($RequiredModulesDirectory -in @('CurrentUser', 'AllUsers')) {
        Write-Host -foregroundColor Green "[pre-build] Required Modules will be installed, not saved."
        # Install modules instead of saving them
    }
    else {
        if (![io.path]::IsPathRooted($RequiredModulesDirectory)) {
            $RequiredModulesDirectory = Join-Path -Path $PSScriptRoot -ChildPath $RequiredModulesDirectory
        }

        # Create the output/modules folder if not exists, or resolve the Absolute path otherwise
        if (!($RequiredModulesDirectory = (Resolve-Path $RequiredModulesDirectory -ErrorAction SilentlyContinue).Path)) {
            Write-Host -foregroundColor Green "[pre-build] Creating required modules directory $RequiredModulesDirectory."
            $RequiredModulesDirectory = (mkdir -Force $RequiredModulesDirectory).FullName
        }

        # Prepending $PSDependTarget folder to PSModulePath
        if ((($Env:PSModulePath -split ';') -notcontains $RequiredModulesDirectory)) {
            Write-Host -foregroundColor Green "[pre-build] Prepending '$RequiredModulesDirectory' folder to PSModulePath"
            $Env:PSModulePath = $RequiredModulesDirectory + ';' + $Env:PSModulePath
        }
    }

    if ($ResolveDependency) {
        Write-Host -foregroundColor Green "[pre-build] Resolving dependencies."
        if (Test-Path $BuildConfig) {
            Write-Host -foregroundColor Green "[pre-build] Importing Build Info from '$BuildConfig'."
            $BuildInfo = Import-PowerShellDataFile -Path $BuildConfig
        }
        else {
            Write-Warning "No config file found in $BuildConfig"
            $BuildInfo = @{}
        }

        $ResolveDependencyParams = $BuildInfo.'Resolve-Dependency'

        Write-Host -foregroundColor Green "[pre-build] Starting bootstrap process."
        .\Resolve-Dependency.ps1 @ResolveDependencyParams
    }

    if ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {
        Write-Verbose "Bootstrap completed. Handing back to InvokeBuild."
        if ($PSboundParameters.ContainsKey('ResolveDependency')) {
            Write-Verbose "Dependency already resolved. Removing task"
            $null = $PSboundParameters.Remove('ResolveDependency')
        }
        Write-Host -foregroundColor Green "[build] Starting build with InvokeBuild."
        Invoke-Build @PSBoundParameters -Task $Tasks $MyInvocation.MyCommand.Path
        Pop-Location -StackName BuildModule
        return
    }
}
