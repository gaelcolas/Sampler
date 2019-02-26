@{
    Path = "./SampleModule/SampleModule.psd1"
    OutputDirectory      = "./output/SampleModule"

    BuildWorkflow        = @{
        '.' = @()
    }

    'Resolve-Dependency' = @{
        #PSDependTarget              = './output/modules'
        #Proxy = ''
        #ProxyCredential
        Gallery                     = 'PSGallery'
        # AllowOldPowerShellGetModule = $true
        #MinimumPSDependVersion = '0.3.0'
        AllowPrerelease             = $false
        Verbose                     = $false
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