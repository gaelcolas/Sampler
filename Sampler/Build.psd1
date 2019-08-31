@{
    CopyDirectories          = @(
        'DscResources',
        'HelperSubmodule',
        '..\.build\tasks',
        'en',
        'assets',
        'PlasterTemplate'
    )
    suffix = 'suffix.ps1'
        # SubModules = CopyDirectories          = @(
    #     './DscResources/*'
    # )
    Path                     = "./Sampler.psd1"
    VersionedOutputDirectory = $true
    OutputDirectory          = "../output/Sampler"
}
