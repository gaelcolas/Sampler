@{ # Defaults Parameter value to be loaded by the Resolve-Dependency command (unless set in Bound Parameters)
    #PSDependTarget  = './output/modules'
    #Proxy = ''
    #ProxyCredential = '$MyCredentialVariable' #TODO: find a way to support credentials in build (resolve variable)
    Gallery         = 'PSGallery'

    # To use a private nuget repository change the following to your own feed. This must be a Nuget v2 feed due to
    # limitation in PowerShellGet v2.x. Example for Azure DevOps Server project-scoped feed. While resolving dependencies
    # it will be registered as a trusted repository with the name specified in the property 'Gallery' above. It will
    # be removed as repository when dependencies has been resolved, unless it was already registered to start with.
    # Currently only Windows integrated security works with private Nuget v2 feeds (or if it is a public feed with no
    # security), it is not possible yet to provide other credentials for the feed.
    #GallerySourceLocation = 'https://azdoserver.company.local/<org_name>/<project_name>/_packaging/<feed_name>/nuget/v2'

    #AllowOldPowerShellGetModule = $true
    #MinimumPSDependVersion = '0.3.0'
    AllowPrerelease = $false
    WithYAML        = $true # Will also bootstrap PowerShell-Yaml to read other config files
}
