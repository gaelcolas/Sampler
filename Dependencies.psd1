@{
    # Set up a mini virtual environment...
    PSDependOptions = @{
        AddToPath = $True
        Parameters = @{
            Force = $True
            Import = $True
        }
    }

    buildhelpers = 'latest'
    pester = 'latest'
    PSScriptAnalyzer = 'latest'
    PlatyPS = 'latest'
    psdeploy = 'latest'
}