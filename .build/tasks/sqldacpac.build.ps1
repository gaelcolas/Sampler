param
(
    [Parameter()]
    [System.String]
    $SqlProjectName = (property SqlProjectName ''),

    [Parameter()]
    [System.String]
    $SourcePath = (property SourcePath ''),

    [Parameter()]
    [System.String]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [System.String]
    $BuiltModuleSubdirectory = (property BuiltModuleSubdirectory ''),

    [Parameter()]
    [System.Management.Automation.SwitchParameter]
    $VersionedOutputDirectory = (property VersionedOutputDirectory $true),

    [Parameter()]
    [System.String]
    $BuildModuleOutput = (property BuildModuleOutput (Join-Path $OutputDirectory $BuiltModuleSubdirectory)),

    [Parameter()]
    [System.String]
    $ReleaseNotesPath = (property ReleaseNotesPath (Join-Path $OutputDirectory 'ReleaseNotes.md')),

    [Parameter()]
    [System.String]
    $ModuleVersion = (property ModuleVersion ''),

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Build the Module based on its Build.psd1 definition
Task Build_dotnet_sqldacpac {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    $sqlSourcePath = Get-SamplerAbsolutePath -Path 'sql' -RelativeTo $SourcePath

    #TODO: ForEach ($sqlProjPath in Get-ChildItem -Path $sqlSourcePath -Filter *.sqlproj)
    $sqlProjectPath = Get-SamplerAbsolutePath -Path $SqlProjectName -RelativeTo $sqlSourcePath

    "`tDSC Test Output Folder   = '$DscTestOutputFolder'"
    #dotnet build .\source\samplerdb-sql\samplerdb-sql.sqlproj

    $sqlProjectPath = Join-Path -Path $SourcePath -ChildPath $SqlProjectName
    Write-Build -Color 'Magenta' -Text ('Building SQL DACPAC project: {0}' -f $sqlProjPath)
    $sqlProjectFile = Get-ChildItem -Path $sqlProjectPath -Filter *.sqlproj | Select-Object -First 1
    &dotnet build $sqlProjectFile.FullName
}
