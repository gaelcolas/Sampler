<#
    Localized resources for FileContent DSC resource.
#>
ConvertFrom-StringData -StringData @'
    ## Get
    GetCurrentState = Getting the current state of file '{0}'. (FC0001)

    ## Set
    SetDesiredState = Setting the desired state for file '{0}'. (FC0002)
    CreatingFile = Creating file '{0}' with specified content. (FC0003)
    UpdatingContent = Updating content of file '{0}'. (FC0004)

    ## Test
    TestDesiredState = Testing the desired state for file '{0}'. (FC0005)
'@
