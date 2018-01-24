Param (
    [string]
    $BuildOutput = (property BuildOutput 'BuildOutput')
)

# Removes the BuildOutput\modules (errors if Pester is loaded)
task CleanAll Clean,CleanModule

# Synopsis: Deleting the content of the Build Output folder, except ./modules
task Clean {
    if (![io.path]::IsPathRooted($BuildOutput)) {
        $BuildOutput = Join-Path -Path $BuildRoot -ChildPath $BuildOutput
    }

    if (Test-Path $BuildOutput) {
        Write-Build -Color Green "Removing $BuildOutput\* excluding modules"
        Get-ChildItem $BuildOutput -Exclude modules | Remove-Item -Force -Recurse
    }
}

# Synopsis: Removes the Modules from BuildOutput\Modules folder, might fail if there's an handle on one file.
task CleanModule {
     if (![io.path]::IsPathRooted($BuildOutput)) {
        $BuildOutput = Join-Path -Path $BuildRoot -ChildPath $BuildOutput
    }
    Write-Build -Color Green "Removing $BuildOutput\*"
    Get-ChildItem $BuildOutput | Remove-Item -Force -Recurse -Verbose -ErrorAction Stop
}
