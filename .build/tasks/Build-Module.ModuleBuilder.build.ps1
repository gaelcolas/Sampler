Param (

    [string]
    $ProjectName = (property ProjectName $(
            #Find the module manifest to deduce the Project Name
            (Get-ChildItem $BuildRoot\*\*.psd1 | Where-Object {
                ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch{$false}) }
            ).BaseName
        )
    ),

    [string]
    $SourcePath = (property SourcePath ((Get-ChildItem $BuildRoot\*\*.psd1 | Where-Object {
                    ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                    $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch { $false }) }
            ).Directory.FullName)
    ),

    [string]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot "output")),

    [string]
    $BuildModuleOutput = (property BuildModuleOutput (Join-Path $OutputDirectory $ProjectName)),

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

    $BuildInfo = (property BuildInfo @{})
)

# Synopsis: Build the Module based on its Build.psd1 definition
Task Build_Module_ModuleBuilder {
    " Project Name      = $ProjectName"
    " ModuleVersion     = $ModuleVersion"
    " Source Path       = $SourcePath"
    " OutputDirectory   = $OutputDirectory"
    " BuildModuleOutput = $BuildModuleOutput"

    Import-Module ModuleBuilder
    $BuildModuleParams = @{}

    foreach ($ParamName in (Get-Command Build-Module).Parameters.Keys) {
        # If Build-Module parameters are available in current session, use those
        # otherwise use params from BuildInfo if specified
        if ($ValueFromBuildParam = Get-Variable -Name $ParamName -ValueOnly -ErrorAction SilentlyContinue) {
            Write-Build -Color DarkGray "Adding $ParamName with value $ValueFromBuildParam from current Variables"
            if ($ParamName -eq 'OutputDirectory') {
                $BuildModuleParams.add($ParamName, $BuildModuleOutput)
            }
            else {
                $BuildModuleParams.Add($ParamName, $ValueFromBuildParam)
            }
        }
        elseif ($ValueFromBuildInfo = $BuildInfo[$ParamName]) {
            Write-Build -Color DarkGray "Adding $ParamName with value $ValueFromBuildInfo from Build Info"
            $BuildModuleParams.Add($ParamName, $ValueFromBuildInfo)
        }
        else {
            Write-Debug -Message "No value specified for $ParamName"
        }
    }

    Write-Build -Color Green "Building Module to $($BuildModuleParams['OutputDirectory'])..."
    Build-Module @BuildModuleParams -SemVer $ModuleVersion
}

Task Build_NestedModules_ModuleBuilder {
    Import-Module ModuleBuilder -ErrorAction Stop
    $ModuleVersion, $VersionMetadata = $ModuleVersion -split '\+', 2
    $ModuleVersionFolder, $PrereleaseTag = $ModuleVersion -split '\-', 2

    $NestedModule = $BuildInfo.NestedModule
    foreach ($NestedModuleName in $NestedModule.Keys) {
        Write-Build -color DarkGray "Building nested module $NestedModuleName"

        $BuildModuleParam = $NestedModule[$NestedModuleName]
        $BuildModuleParam['OutputDirectory'] = $ExecutionContext.InvokeCommand.ExpandString($BuildModuleParam['OutputDirectory'])

        Write-Build -color yellow "OutputDirectory for $NestedModuleName : $($BuildModuleParam['OutputDirectory'])"
        if (-Not (Split-Path -IsAbsolute $BuildModuleParam['OutputDirectory'])) {
            $BuildModuleParam['OutputDirectory'] = Join-Path -Path $BuildRoot -ChildPath $BuildModuleParam['OutputDirectory']
            Write-Build -color White "Absolute Path is: $($BuildModuleParam['OutputDirectory'])"
        }
        Build-Module @BuildModuleParam
    }
}
