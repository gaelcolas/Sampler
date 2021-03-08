@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'Sampler.psm1'

    # Version number of this module.
    ModuleVersion     = '0.0.1'

    # Supported PSEditions
    # CompatiblePSEditions = @('Desktop','Core') # Removed to support PS 5.0

    # ID used to uniquely identify this module
    GUID              = 'b59b8442-9cf9-4c4b-bc40-035336ace573'

    # Author of this module
    Author            = 'Gael Colas'

    # Company or vendor of this module
    CompanyName       = 'SynEdgy Limited'

    # Copyright statement for this module
    Copyright         = '(c) Gael Colas. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Sample Module with Pipeline scripts and its Plaster template to create a module following some of the community accepted practices.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.0'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules   = @(
        'Plaster'
    )

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules     = @()

    # Functions to export from this module
    FunctionsToExport = ''

    # Cmdlets to export from this module
    CmdletsToExport   = ''

    # Variables to export from this module
    VariablesToExport = ''

    # Aliases to export from this module
    AliasesToExport   = '*'

    # List of all modules packaged with this module
    ModuleList        = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{
        PSData = @{
            # Extension for Plaster Template discoverability with `Get-PlasterTemplate -IncludeInstalledModules`
            Extensions   = @(
                @{
                    Module         = 'Plaster'
                    minimumVersion = '1.1.3'
                    Details        = @{
                        TemplatePaths = @(
                            'Templates\Classes'
                            'Templates\ClassResource'
                            'Templates\Composite'
                            'Templates\Enum'
                            'Templates\MofResource'
                            'Templates\PrivateFunction'
                            'Templates\PublicCallPrivateFunctions'
                            'Templates\PublicFunction'
                            'Templates\Sampler'
                        )
                    }
                }
            )

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('Template', 'pipeline', 'plaster', 'DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource', 'Windows', 'MacOS', 'Linux')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/gaelcolas/Sampler/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/gaelcolas/Sampler'

            # A URL to an icon representing this module.
            IconUri      = 'https://raw.githubusercontent.com/gaelcolas/Sampler/master/Sampler/assets/sampler.png'

            # ReleaseNotes of this module
            ReleaseNotes = ''

            Prerelease   = ''
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
