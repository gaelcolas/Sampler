@{
    RequiredModules          = "./RequiredModules.psd1"
    CopyDirectories          = @(
        'DscResources'
    )
    SubModules = CopyDirectories          = @(
        './DscResources/*'
    )
    Path                     = "./SampleModule.psd1"
    VersionedOutputDirectory = $true
    OutputDirectory          = "../output/SampleModule"
}
