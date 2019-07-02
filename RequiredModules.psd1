@{
    # Set up a mini virtual environment...
    PSDependOptions      = @{
        AddToPath  = $True
        Target     = 'output\RequiredModules'
        Parameters = @{
        }
    }

    invokeBuild          = 'latest'
    PSScriptAnalyzer     = 'latest'
    pester               = 'latest'
    ModuleBuilder        = 'latest'
    buildhelpers         = 'latest'
    psdeploy             = 'latest'

    #required for DSC authoring
    xDscResourceDesigner = 'latest'
    'PowerShell/DscResource.Tests' = @{
        Target = '.'
        parameters = @{
            TargetType     = 'exact'
            ExtractProject = $false
        }
        Version = 'master'
    }
}
