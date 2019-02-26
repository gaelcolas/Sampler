[CmdletBinding()]
param(

    [Parameter(Position = 0)]
    [string[]]$Tasks = '.',

    $BuildConfig = './Build.psd1',

    # A Specific folder to build the artfeacts into.
    $OutputDirectory = 'output',

    # Can be a path (relative to $PSScriptRoot or absolute) to tell Resolve-Dependency & PSDepend where to save the required modules,
    # or use CurrentUser, AllUsers to target where to install missing dependencies
    # You can override the value for PSDepend in the Build.psd1 build manifest
    # This defaults to $OutputDirectory/modules (by default: ./output/modules)
    $RequiredModulesDirectory = $(Join-path $OutputDirectory 'RequiredModules'),

    [switch]$ResolveDependency
)

# The BEGIN block (at the end of this file) handles the Bootstrap of the Environment before Invoke-Build can run the tasks

Process {

    if ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {
        # Only run this within InvokeBuild (Look at the Begin block at the bottom of this script)
        return
    }

    # Execute the Build Process from the .build.ps1 path.
    Push-Location -Path $PSScriptRoot -StackName BeforeBuild

    try {
        Write-Host -ForeGroundColor magenta "[build] Parsing defined tasks"

        # The Build Configuration may be absent or invalid
        try {
            $BuildInfo = Import-PowerShellDataFile -Path $BuildConfig
        }
        catch {
            $BuildInfo = @{}
        }

        if ($BuildInfo.TaskHeader) {
            Set-BuildHeader ([scriptblock]::Create($BuildInfo.TaskHeader))
        }

        # Loading Build Tasks defined in the .build/ folder
        Get-ChildItem -Path ".build/" -Recurse -Include *.ps1 | Foreach-Object {
            "Importing file $($_.BaseName)" | Write-Verbose
            . $_.FullName
        }

        # Synopsis: Empty task, useful to test the bootstrap process
        task noop {}

        # Define
        task .  Clean,
        Set_Build_Environment_Variables,
        Build_Module_ModuleBuilder,
        Pester_Tests_Stop_On_Fail,
        Pester_if_Code_Coverage_Under_Threshold


        # Allow the BuildInfo to override the default Workflow (sequence of tasks)
        foreach ($Workflow in $BuildInfo.BuildWorkflow.keys) {
            Write-Verbose "Creating Build Workflow '$Workflow' with tasks $($BuildInfo.BuildWorkflow.($Workflow) -join ', ')"
            task $Workflow $BuildInfo.BuildWorkflow.($Workflow)
        }

        Write-Host -ForeGroundColor magenta "[build] Executing requested workflow: $($Tasks -join ', ')"

        #     Upload_Unit_Test_Results_To_AppVeyor,
        #     Fail_Build_if_Unit_Test_Failed,
        #     Fail_if_Last_Code_Converage_is_Under_Threshold,
        #     IntegrationTests,
        #     Deploy_with_PSDeploy

    }
    finally {
        Pop-Location -StackName BeforeBuild
    }
}

Begin {
    # Bootstrapping the environment before using Invoke-Build as task runner

    if ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {
        Write-Host -foregroundColor Green "[pre-build] Starting Build Init"
        Push-Location $PSScriptRoot -StackName BuildModule
    }

    if ($RequiredModulesDirectory -in @('CurrentUser', 'AllUsers')) {
        # Installing modules instead of saving them
        Write-Host -foregroundColor Green "[pre-build] Required Modules will be installed, not saved."
        # Tell Resolve-Dependency to use provided scope as the -PSDependTarget if not overridden in Build.psd1
        $PSDependTarget = $RequiredModulesDirectory
    }
    else {
        if (![io.path]::IsPathRooted($OutputDirectory)) {
            $OutputDirectory = Join-Path -Path $PSScriptRoot -ChildPath $OutputDirectory
        }

        # Resolving the absolute path to save the required modules to
        if (![io.path]::IsPathRooted($RequiredModulesDirectory)) {
            $RequiredModulesDirectory = Join-Path -Path $PSScriptRoot -ChildPath $RequiredModulesDirectory
        }

        # Create the output/modules folder if not exists, or resolve the Absolute path otherwise
        if (Resolve-Path $RequiredModulesDirectory -ErrorAction SilentlyContinue) {
            Write-Debug "[pre-build] Required Modules path already exist at $RequiredModulesDirectory"
            $RequiredModulesPath = Convert-Path $RequiredModulesDirectory
        }
        else {
            Write-Host -foregroundColor Green "[pre-build] Creating required modules directory $RequiredModulesDirectory."
            $RequiredModulesPath = (mkdir -Force $RequiredModulesDirectory).FullName
        }


        # Prepending $RequiredModulesPath folder to PSModulePath to resolve from this folder FIRST
        if ($RequiredModulesDirectory -notin @('CurrentUser', 'AllUsers') -and
            (($Env:PSModulePath -split ';') -notcontains $RequiredModulesDirectory)) {
            Write-Host -foregroundColor Green "[pre-build] Prepending '$RequiredModulesDirectory' folder to PSModulePath"
            $Env:PSModulePath = $RequiredModulesDirectory + ';' + $Env:PSModulePath
        }

        # Prepending $OutputDirectory folder to PSModulePath to resolve built module from this folder
        if (($Env:PSModulePath -split ';') -notcontains $OutputDirectory) {
            Write-Host -foregroundColor Green "[pre-build] Prepending '$OutputDirectory' folder to PSModulePath"
            $Env:PSModulePath = $OutputDirectory + ';' + $Env:PSModulePath
        }


        # Tell Resolve-Dependency to use $RequiredModulesPath as -PSDependTarget if not overridden in Build.psd1
        $PSDependTarget = $RequiredModulesPath
    }

    if ($ResolveDependency) {
        Write-Host -foregroundColor Green "[pre-build] Resolving dependencies."
        try {
            Write-Host -foregroundColor Green "[pre-build] Importing Build Info from '$BuildConfig'."
            $BuildInfo = Import-PowerShellDataFile -Path $BuildConfig
        }
        catch {
            Write-Verbose "Error attempting to import $($BuildConfig): $($_.Exception.Message)."
            # File does not exist or not valid PSD1. Assume no Build Manifest available
            $BuildInfo = @{}
        }

        $ResolveDependencyParams = @{}
        $ResolveDependencyAvailableParams = (get-command .\Resolve-Dependency.ps1).parameters.keys
        foreach ($CmdParameter in $ResolveDependencyAvailableParams) {

            # The parameter has been explicitly used for calling the Build.ps1
            if ($MyInvocation.BoundParameters.ContainsKey($CmdParameter)) {
                $ParamValue = $MyInvocation.BoundParameters.ContainsKey($CmdParameter)
                Write-Debug " adding  $CmdParameter :: $ParamValue [from user-provided parameters to Build.ps1]"
                $ResolveDependencyParams.Add($CmdParameter, $ParamValue)
            }
            # The Parameter is defined in the Build manifest
            elseif ($BuildInfo.'Resolve-Dependency' -and $BuildInfo.'Resolve-Dependency'.ContainsKey($CmdParameter)) {
                $ParamValue = $BuildInfo.'Resolve-Dependency'.($CmdParameter)
                Write-Debug " adding  $CmdParameter :: $ParamValue [from Build Manifest]"
                $ResolveDependencyParams.Add($CmdParameter, $ParamValue)
            }
            # Use defaults parameter value from Build.ps1, if any
            else {
                if ($ParamValue = Get-Variable -Name $CmdParameter -ValueOnly -ErrorAction Ignore) {
                    Write-Debug " adding  $CmdParameter :: $ParamValue [from default Build.ps1 variable]"
                    $ResolveDependencyParams.add($CmdParameter, $ParamValue)
                }
            }
        }

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
