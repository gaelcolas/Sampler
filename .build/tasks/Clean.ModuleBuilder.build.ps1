param (
    # Base directory of all output (default to 'output')
    [Parameter()]
    [System.String]
    $OutputDirectory = (property OutputDirectory (Join-Path -Path $BuildRoot -ChildPath 'output')),

    [Parameter()]
    [System.String]
    $RequiredModulesDirectory = (property RequiredModulesDirectory $(Join-Path -Path $OutputDirectory -ChildPath 'RequiredModules')),

    [Parameter()]
    [System.String]
    $AgentOutputSubdirectory = (property AgentOutputSubdirectory 'agentic')
)

# Removes the OutputDirectory\modules (errors if Pester is loaded)
task CleanAll Clean, CleanModule

# Synopsis: Deleting the content of the Build Output folder, except ./modules
task Clean {
    $OutputDirectory = Get-SamplerAbsolutePath -Path $OutputDirectory -RelativeTo $BuildRoot

    $foldersToExclude = @(Split-Path -Leaf -Path $RequiredModulesDirectory)

    if (-not [System.String]::IsNullOrWhiteSpace($AgentOutputSubdirectory))
    {
        $foldersToExclude += $AgentOutputSubdirectory
    }

    Write-Build -Color Green "Removing $OutputDirectory\* excluding $($foldersToExclude -join ', ')"

    Get-ChildItem -Path $OutputDirectory -Exclude $foldersToExclude | Remove-Item -Force -Recurse
}

# Synopsis: Removes the Modules from OutputDirectory\Modules folder, might fail if there's an handle on one file.
task CleanModule {
    $OutputDirectory =  Get-SamplerAbsolutePath -Path $OutputDirectory -RelativeTo $BuildRoot

    Write-Build -Color Green "Removing $OutputDirectory\*"

    Get-ChildItem $OutputDirectory | Remove-Item -Force -Recurse -ErrorAction 'Stop'
}
