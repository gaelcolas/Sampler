@{
    Path = "./Build.psd1"
    OutputDirectory = "./output/SampleModule"
    'Resolve-Dependency' = @{
        DependencyFile = './PSDepend.build.psd1'
        PSDependTarget = './output/modules'
        Scope = 'CurrentUser'
        #Proxy = ''
        #ProxyCredential
        Gallery = 'PSGallery'
        AllowOldPowerShellGetModule = $false
        #MinimumPSDependVersion = '0.3.0'
        AllowPrerelease = $false
        Verbose = $false
    }
    TaskHeader = '
        param($Path)
        ""
        "=" * 79
        Write-Build Cyan "`t`t`t$($Task.Name.replace("_"," ").ToUpper())"
        Write-Build DarkGray  "$(Get-BuildSynopsis $Task)"
        "-" * 79
        Write-Build DarkGray "  $Path"
        Write-Build DarkGray "  $($Task.InvocationInfo.ScriptName):$($Task.InvocationInfo.ScriptLineNumber)"
        ""
    '


}