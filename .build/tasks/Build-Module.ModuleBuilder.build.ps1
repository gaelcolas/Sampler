Param (

    [string]
    $ProjectName = (property ProjectName (Split-Path -Leaf $BuildRoot) ),

    $SourcePath = (property SourcePath (Join-path $BuildRoot "$ProjectName/[Bb]uild.psd1")),

    [string]
    $SourceFolder = $ProjectName,

    [string]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

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
    Import-Module ModuleBuilder

    # $BuildModuleParams = @{
    #     SourcePath
    #     OutputDirectory
    #     SemVer
    #     Version
    #     Prerelease
    #     BuildMetaData
    # }
    "Module version is $ModuleVersion"
    Build-Module -SourcePath $SourcePath -SemVer $ModuleVersion
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
