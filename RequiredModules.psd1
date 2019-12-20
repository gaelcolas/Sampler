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
    Plaster              = 'latest'
    ModuleBuilder        = '1.0.0'
    # buildhelpers         = 'latest'
    # PSDeploy             = 'latest'
    ChangelogManagement  = 'latest'
    'DscResource.Test'   = 'latest'
    'DscResource.AnalyzerRules' = 'latest'
    xDscResourceDesigner        = 'latest'
    # PSPKI                       = 'latest'
    'DscResource.Common' = 'latest'

}
