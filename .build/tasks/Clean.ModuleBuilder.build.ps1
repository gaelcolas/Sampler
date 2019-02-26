Param (
    # Base directory of all output (default to 'output')
    [string]$OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [string]$RequiredModulesDirectory = (property RequiredModulesDirectory $(Join-path $OutputDirectory 'RequiredModules'))
)

# Removes the BuildOutput\modules (errors if Pester is loaded)
task CleanAll Clean,CleanModule

# Synopsis: Deleting the content of the Build Output folder, except ./modules
task Clean {
    if (![io.path]::IsPathRooted($OutputDirectory)) {
        $OutputDirectory = Join-Path -Path $BuildRoot -ChildPath $OutputDirectory
    }

    $FolderToExclude = Split-Path -leaf $RequiredModulesDirectory
    Write-Build -Color Green "Removing $OutputDirectory\* excluding $FolderToExclude"
    Get-ChildItem $OutputDirectory -Exclude $FolderToExclude | Remove-Item -Force -Recurse

}

# Synopsis: Removes the Modules from BuildOutput\Modules folder, might fail if there's an handle on one file.
task CleanModule {
     if (![io.path]::IsPathRooted($OutputDirectory)) {
        $OutputDirectory = Join-Path -Path $BuildRoot -ChildPath $OutputDirectory
    }
    Write-Build -Color Green "Removing $OutputDirectory\*"
    Get-ChildItem $OutputDirectory | Remove-Item -Force -Recurse -ErrorAction Stop
}
