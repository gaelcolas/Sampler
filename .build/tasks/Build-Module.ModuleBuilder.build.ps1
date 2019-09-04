Param (

    [string]
    $ProjectName = (property ProjectName $(
            try { (Split-Path (git config --get remote.origin.url) -Leaf) -replace '\.git' }
            catch { Split-Path -Path $BuildRoot -Leaf }
        )
    ),

    [string]
    $SourcePath = (property SourcePath (Join-Path $BuildRoot $ProjectName)),

    [string]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot "output")),

    [string]
    $BuildModuleOutput = (property BuildModuleOutput (Join-Path $OutputDirectory $ProjectName)),

    [string]
    $ModuleVersion = (property ModuleVersion $(
            if (Get-Command gitversion -ErrorAction SilentlyContinue) {
                Write-Verbose "Using  ModuleVersion as resolved by gitversion"
                (gitversion | ConvertFrom-Json).InformationalVersion
            }
            else {
                Write-Verbose "Command gitversion not found, defaulting to 0.0.1"
                '0.0.1'
            }
        )),

    $BuildInfo = (property BuildInfo @{})
)

# Synopsis: Build the Module based on its Build.psd1 definition
Task Build_Module_ModuleBuilder {
    " Project Name      = $ProjectName"
    " Project Path      = $ProjectPath"
    " ModuleVersion     = $ModuleVersion"
    " Source Path       = $SourcePath"
    " OutputDirectory   = $OutputDirectory"
    " BuildModuleOutput = $BuildModuleOutput"

    Import-Module ModuleBuilder
    $BuildModuleParams = @{}

    foreach ($ParamName in (Get-Command Build-Module).Parameters.Keys) {
        if ($ValueFromBuildParam = Get-Variable -Name $ParamName -ValueOnly -ErrorAction SilentlyContinue) {
            Write-Build -Color DarkGray "Adding $ParamName with value $ValueFromBuildParam from current Variables"
            if ($ParamName -eq 'OutputDirectory') {
                $BuildModuleParams.add($ParamName, $BuildModuleOutput)
            }
            else {
                $BuildModuleParams.Add($ParamName, $ValueFromBuildParam)
            }
        }
        elseif($ValueFromBuildInfo = $BuildInfo[$ParamName]) {
            Write-Build -Color DarkGray "Adding $ParamName with value $ValueFromBuildInfo from Build Info"
            $BuildModuleParams.Add($ParamName,$ValueFromBuildInfo)
        }
        else {
            Write-Debug -Message "No value specified for $ParamName"
        }
    }
    # If Build-Module parameters are available in current session, use those
    # otherwise use params from BuildInfo if specified

    Write-Build -Color Green "Building Module to $($BuildModuleParams['OutputDirectory'])..."
    Build-Module @BuildModuleParams -SemVer $ModuleVersion
}

Task Build_NestedModules_ModuleBuilder {
    Import-Module ModuleBuilder

    $NestedModule = $BuildInfo.NestedModule
    foreach ($NestedModuleName in $NestedModule.Keys) {
        Write-Build -color yellow "Doing $NestedModuleName"
        $BuildModuleParam = $NestedModule[$NestedModuleName]
        $ModuleVersion = $ModuleVersion -replace '-.*'
        $BuildModuleParam['OutputDirectory'] = $ExecutionContext.InvokeCommand.ExpandString($BuildModuleParam['OutputDirectory'])
        Write-Build -color yellow "OutputDirectory for $NestedModuleName : $($BuildModuleParam['OutputDirectory'])"
        if (-Not (Split-Path -IsAbsolute $BuildModuleParam['OutputDirectory'])) {
            $BuildModuleParam['OutputDirectory'] = Join-Path -Path $BuildRoot -ChildPath $BuildModuleParam['OutputDirectory']
            Write-Build -color White "Absolute Path is: $($BuildModuleParam['OutputDirectory'])"
        }
        Build-Module @BuildModuleParam
    }
}
