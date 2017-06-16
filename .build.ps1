[cmdletBinding()]
Param (
    [Parameter(Position=0)]
    $Tasks,

    [switch]
    $NoDependency,

    [String]
    $BuildOutput = "BuildOutput",

    [String[]]
    $GalleryRepository,

    [Uri]
    $GalleryProxy,

    [Switch]
    $ForceEnvironmentVariables = [switch]$true,

    $MergeList = @('enum*',[PSCustomObject]@{Name='class*';order={(Import-PowerShellDataFile .\SampleModule\Classes\classes.psd1).order.indexOf($_.BaseName)}},'priv*','pub*')
    ,$CodeCoverageThreshold = 0
)

Process {
    if ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {
        Invoke-Build $Tasks $MyInvocation.MyCommand.Path @PSBoundParameters
        return
    }

    Get-ChildItem -Path "$PSScriptRoot/.build/" -Recurse -Include *.ps1 -Verbose |
        Foreach-Object {
            "Importing file $($_.BaseName)" | Write-Verbose
            . $_.FullName 
        }

    task .  Clean,
            SetBuildEnvironment,
            UnitTests,
            UploadUnitTestResultsToAppVeyor,
            FailBuildIfFailedUnitTest, 
            FailIfLastCodeConverageUnderThreshold,
            CopySourceToModuleOut,
            MergeFilesToPSM1,
            CleanOutputEmptyFolders,
            IntegrationTests, 
            QualityTestsStopOnFail

    task testAll UnitTests, IntegrationTests, QualityTestsStopOnFail
}


begin {
    function Resolve-Dependency {
        [CmdletBinding()]
        param()
        $VerbosePreference = 'Continue'

        if (!(Get-PackageProvider -Name NuGet -ForceBootstrap)) {
            $providerBootstrapParams = @{
                Name = 'nuget'
                force = $true
                ForceBootstrap = $true
            }
            if ($GalleryProxy) { $providerBootstrapParams.Add('Proxy',$GalleryProxy) }
            $null = Install-PackageProvider @providerBootstrapParams
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        }

        if (!(Get-Module -Listavailable PSDepend)) {
            Write-verbose "BootStrapping PSDepend"
            "Parameter $BuildOutput"| Write-verbose
            $InstallPSDependParams = @{
                Name = 'PSDepend'
                AllowClobber = $true
                Confirm = $false
                Force = $true
            }
            if ($GalleryRepository) { $InstallPSDependParams.Add('Repository',$GalleryRepository) }
            if ($GalleryProxy)      { $InstallPSDependParams.Add('Proxy',$GalleryProxy) }
            if ($GalleryCredential) { $InstallPSDependParams.Add('ProxyCredential',$GalleryCredential) }
            Install-Module @InstallPSDependParams
        }

        $PSDependParams = @{
            Force = $true
            Path = "$PSScriptRoot\Dependencies.psd1"
        }

        Invoke-PSDepend @PSDependParams
        Write-Verbose "Project Bootstrapped, returning to Invoke-Build"
    }

    if (!$NoDependency) {
        Resolve-Dependency -Verbose
    }
}
