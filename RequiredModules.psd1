@{
    <#
        This is only required if you need to use PSDepend (using PowerShellGet)
        It is not required for PSResourceGet or ModuleFast.
        See Resolve-Dependency.psd1 on how to enable PSResourceGet or ModuleFast.
    #>
    # PSDependOptions                = @{
    #     AddToPath  = $true
    #     Target     = 'output\RequiredModules'
    #     Parameters = @{
    #         Repository = 'PSGallery'
    #     }
    # }

    InvokeBuild                 = 'latest'
    PSScriptAnalyzer            = 'latest'
    Pester                      = 'latest'
    Plaster                     = 'latest'
    ModuleBuilder               = 'latest'
    MarkdownLinkCheck           = 'latest'
    ChangelogManagement         = 'latest'
    'Sampler.GitHubTasks'       = 'latest'
    'DscResource.Test'          = 'latest'
    'DscResource.AnalyzerRules' = 'latest'
    xDscResourceDesigner        = 'latest'

    PlatyPS = 'latest'

    # TODO: This need to be documented.

    # PSDepend format is also supported. Must be exactly 9.1.0-preview0002

    'ComputerManagementDsc'                         = @{
       Version    = '9.1.0-preview0002'
       Parameters = @{
           AllowPrerelease = $true
       }
    }
    # PSPKI                          = '3.7.2'
    # LoopbackAdapter                = 'latest'


    # Below Nuget formats are supported for ModuleFast and only when ModuleFastBleedingEdge is set to $true.

    # Must be exactly 9.1.0-preview0002
    #'ComputerManagementDsc'        = '9.1.0-preview0002'
    #'ComputerManagementDsc'        = '@9.1.0-preview0002'
    #'ComputerManagementDsc'        = ':[9.1.0-preview0002]'

    # Must be greater than 9.1.0-preview0002
    #'ComputerManagementDsc'        = '>9.1.0-preview0002'

    # Must be less than 9.1.0-preview0002
    #'ComputerManagementDsc'        = '<9.1.0-preview0002'

    # Must be less than or equal to 9.1.0-preview0002
    #'ComputerManagementDsc'        = '<=9.1.0-preview0002'

    # Must be greater than or equal to 9.1.0-preview0002
    #'ComputerManagementDsc'        = '>=9.1.0-preview0002'

    # Must be greater than 9.1.0-preview0002
    #'ComputerManagementDsc'        = ':9.1.0-preview0002'

    # Must be less than 9.1.0-preview0002
    #'ComputerManagementDsc'        = ':(,9.1.0-preview0002)'
}
