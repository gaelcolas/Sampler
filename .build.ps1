[CmdletBinding()]
param(

    [Parameter(Position = 0)]
    [string[]]$Tasks = '.',

    [Parameter()]
    $BuildConfig = './Build.psd1',

    # A Specific folder to build the artefact into.
    [Parameter()]
    $OutputDirectory = 'output',

    # Can be a path (relative to $PSScriptRoot or absolute) to tell Resolve-Dependency & PSDepend where to save the required modules,
    # or use CurrentUser, AllUsers to target where to install missing dependencies
    # You can override the value for PSDepend in the Build.psd1 build manifest
    # This defaults to $OutputDirectory/modules (by default: ./output/modules)
    [Parameter()]
    $RequiredModulesDirectory = $(Join-path $OutputDirectory 'RequiredModules'),

    $CodeCoverageThreshold = 80,

    [Parameter()]
    [Alias('bootstrap')]
    [switch]$ResolveDependency,

    [parameter(DontShow)]
    [AllowNull()]
    $BuildInfo
)

# The BEGIN block (at the end of this file) handles the Bootstrap of the Environment before Invoke-Build can run the tasks
# if the -ResolveDependency (aka Bootstrap) is specified, the modules are already available, and can be auto loaded

Process {

    if ($MyInvocation.ScriptName -notLike '*Invoke-Build.ps1') {
        # Only run the process block through InvokeBuild (Look at the Begin block at the bottom of this script)
        return
    }

    # Execute the Build Process from the .build.ps1 path.
    Push-Location -Path $PSScriptRoot -StackName BeforeBuild

    try {
        Write-Host -ForeGroundColor magenta "[build] Parsing defined tasks"

        # Load Default BuildInfo if not provided as parameter
        # TODO: Replace with PoShCode/Configuration ~Get-DefaultParameter when available
        if (!$BuildInfo) {
            try {
                $BuildInfo = Import-PowerShellDataFile -Path $BuildConfig
            }
            catch {
                $BuildInfo = @{ }
            }
        }

        # If the Invoke-Build Task Header is specified in the Build Info, set it
        if ($BuildInfo.TaskHeader) {
            Set-BuildHeader ([scriptblock]::Create($BuildInfo.TaskHeader))
        }

        # Loading Build Tasks defined in the .build/ folder
        Get-ChildItem -Path ".build/" -Recurse -Include *.ps1 | Foreach-Object {
            "Importing file $($_.BaseName)" | Write-Verbose
            . $_.FullName
        }

        if ($BuildInfo.ModuleBuildTasks) {
            # TODO: Load Invoke-Build tasks from modules
            # Maybe the tasks are exported in the Module's PSData
            # Or we take a relative path to the ModuleBase
        }

        # Synopsis: Empty task, useful to test the bootstrap process
        task noop { }

        # Define default task sequence ("."), can be overridden in the $BuildInfo
        task .  Clean,
        Set_Build_Environment_Variables,
        Build_Module_ModuleBuilder,
        Pester_Tests_Stop_On_Fail,
        Pester_if_Code_Coverage_Under_Threshold


        # Load Invoke-Build task sequences/workflows from $BuildInfo
        foreach ($Workflow in $BuildInfo.BuildWorkflow.keys) {
            Write-Verbose "Creating Build Workflow '$Workflow' with tasks $($BuildInfo.BuildWorkflow.($Workflow) -join ', ')"
            task $Workflow $BuildInfo.BuildWorkflow.($Workflow)
        }

        Write-Host -ForeGroundColor magenta "[build] Executing requested workflow: $($Tasks -join ', ')"

        # TODO: Integrate Remaining tasks with this new build
        #     Upload_Unit_Test_Results_To_AppVeyor,
        #     Fail_Build_if_Unit_Test_Failed,
        #     Fail_if_Last_Code_Coverage_is_Under_Threshold,
        #     IntegrationTests,
        #     Deploy_with_PSDeploy

    }
    finally {
        Pop-Location -StackName BeforeBuild
    }
}

Begin {
    # Bootstrapping the environment before using Invoke-Build as task runner

    if ($MyInvocation.ScriptName -notLike '*Invoke-Build.ps1') {
        Write-Host -foregroundColor Green "[pre-build] Starting Build Init"
        Push-Location $PSScriptRoot -StackName BuildModule
    }

    if ($RequiredModulesDirectory -in @('CurrentUser', 'AllUsers')) {
        # Installing modules instead of saving them
        Write-Host -foregroundColor Green "[pre-build] Required Modules will be installed for $RequiredModulesDirectory, not saved."
        # Tell Resolve-Dependency to use provided scope as the -PSDependTarget if not overridden in Build.psd1
        $PSDependTarget = $RequiredModulesDirectory
    }
    else {
        if (-Not (Split-Path -IsAbsolute -Path $OutputDirectory)) {
            $OutputDirectory = Join-Path -Path $PSScriptRoot -ChildPath $OutputDirectory
        }

        # Resolving the absolute path to save the required modules to
        if (-Not (Split-Path -IsAbsolute -Path $RequiredModulesDirectory)) {
            $RequiredModulesDirectory = Join-Path -Path $PSScriptRoot -ChildPath $RequiredModulesDirectory
        }

        # Create the output/modules folder if not exists, or resolve the Absolute path otherwise
        if (Resolve-Path $RequiredModulesDirectory -ErrorAction SilentlyContinue) {
            Write-Debug "[pre-build] Required Modules path already exist at $RequiredModulesDirectory"
            $RequiredModulesPath = Convert-Path $RequiredModulesDirectory
        }
        else {
            Write-Host -foregroundColor Green "[pre-build] Creating required modules directory $RequiredModulesDirectory."
            $RequiredModulesPath = (New-Item -ItemType Directory -Force -Path $RequiredModulesDirectory).FullName
        }

        # Prepending $RequiredModulesPath folder to PSModulePath to resolve from this folder FIRST
        if ($RequiredModulesDirectory -notIn @('CurrentUser', 'AllUsers') -and
            (($Env:PSModulePath -split ';') -notContains $RequiredModulesDirectory)) {
            Write-Host -foregroundColor Green "[pre-build] Prepending '$RequiredModulesDirectory' folder to PSModulePath"
            $Env:PSModulePath = $RequiredModulesDirectory + ';' + $Env:PSModulePath
        }

        # Prepending $OutputDirectory folder to PSModulePath to resolve built module from this folder
        if (($Env:PSModulePath -split ';') -notContains $OutputDirectory) {
            Write-Host -foregroundColor Green "[pre-build] Prepending '$OutputDirectory' folder to PSModulePath"
            $Env:PSModulePath = $OutputDirectory + ';' + $Env:PSModulePath
        }

        # Tell Resolve-Dependency to use $RequiredModulesPath as -PSDependTarget if not overridden in Build.psd1
        $PSDependTarget = $RequiredModulesPath
    }

    if ($ResolveDependency) {
        Write-Host -Object "[pre-build] Resolving dependencies." -foregroundColor Green
        $ResolveDependencyParams = @{ }
        $ResolveDependencyAvailableParams = (get-command -Name '.\Resolve-Dependency.ps1').parameters.keys
        foreach ($CmdParameter in $ResolveDependencyAvailableParams) {

            # The parameter has been explicitly used for calling the .build.ps1
            if ($MyInvocation.BoundParameters.ContainsKey($CmdParameter)) {
                $ParamValue = $MyInvocation.BoundParameters.ContainsKey($CmdParameter)
                Write-Debug " adding  $CmdParameter :: $ParamValue [from user-provided parameters to Build.ps1]"
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

    if ($MyInvocation.ScriptName -notLike '*Invoke-Build.ps1') {
        Write-Verbose "Bootstrap completed. Handing back to InvokeBuild."
        if ($PSBoundParameters.ContainsKey('ResolveDependency')) {
            Write-Verbose "Dependency already resolved. Removing task"
            $null = $PSBoundParameters.Remove('ResolveDependency')
        }
        Write-Host -foregroundColor Green "[build] Starting build with InvokeBuild."
        Invoke-Build @PSBoundParameters -Task $Tasks $MyInvocation.MyCommand.Path
        Pop-Location -StackName BuildModule
        return
    }
}
