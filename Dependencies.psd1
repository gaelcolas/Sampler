@{
    # Set up a mini virtual environment...
    PSDependOptions = @{
        AddToPath = $True
        Target = 'BuildOutput\modules'
        Parameters = @{
        }
    }

    buildhelpers = 'latest'
    invokeBuild = 'latest'
    pester = 'latest'
    PSScriptAnalyzer = 'latest'
    PlatyPS = 'latest'
    psdeploy = 'latest'

    #required for DSC authoring
    xDscResourceDesigner = 'latest'
}