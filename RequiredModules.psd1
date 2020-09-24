@{
    PSDependOptions             = @{
        AddToPath  = $true
        Target     = 'output\RequiredModules'
        Parameters = @{}
    }

    InvokeBuild                 = 'latest'
    PSScriptAnalyzer            = '1.19.0'
    Pester                      = '4.10.1'
    Plaster                     = 'latest'
    ModuleBuilder               = @{
        Name = 'ModuleBuilder'
        DependencyType = 'PSGalleryModule'
        Parameters = @{
            AllowPrerelease = $true
        }

        Version = '2.0.0-VersionedOutput'
    }

    MarkdownLinkCheck           = 'latest'
    ChangelogManagement         = 'latest'
    'DscResource.Test'          = 'latest'
    'DscResource.AnalyzerRules' = 'latest'
    xDscResourceDesigner        = 'latest'
}
