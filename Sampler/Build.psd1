@{
    RequiredModules          = "./RequiredModules.psd1"
    CopyDirectories          = @(
        'DscResources'
    )
    # SubModules = CopyDirectories          = @(
    #     './DscResources/*'
    # )
    Path                     = "./Sampler.psd1"
    VersionedOutputDirectory = $true
    OutputDirectory          = "../output/Sampler"
}
