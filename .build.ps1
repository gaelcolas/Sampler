[cmdletBinding()]
Param (
    [Parameter(Position=0)]
    $Tasks,

    [switch]
    $ResolveDependency,

    [String]
    $BuildOutput = "BuildOutput",

    [String[]]
    $GalleryRepository,

    [Uri]
    $GalleryProxy,

    [Switch]
    $ForceEnvironmentVariables = [switch]$true,

    $MergeList = @('enum*',[PSCustomObject]@{Name='class*';order={(Import-PowerShellDataFile -EA 0 .\*\Classes\classes.psd1).order.indexOf($_.BaseName)}},'priv*','pub*')
    
    ,$TaskHeader = {
        param($Path)
        ''
        '=' * 79
        Write-Build Cyan "`t`t`t$($Task.Name.replace('_',' ').ToUpper())"
        Write-Build DarkGray  "$(Get-BuildSynopsis $Task)"
        '-' * 79
        Write-Build DarkGray "  $Path"
        Write-Build DarkGray "  $($Task.InvocationInfo.ScriptName):$($Task.InvocationInfo.ScriptLineNumber)"
        ''
    }

    ,$CodeCoverageThreshold = 80
)

Process {
    if ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {
        if ($PSboundParameters.ContainsKey('ResolveDependency')) {
            Write-Verbose "Dependency already resolved. Handing over to InvokeBuild."
            $null = $PSboundParameters.Remove('ResolveDependency')
        }
        Invoke-Build $Tasks $MyInvocation.MyCommand.Path @PSBoundParameters
        return
    }
    
    # Loading Build Tasks defined in the .build/ folder
    Get-ChildItem -Path "$PSScriptRoot/.build/" -Recurse -Include *.ps1 -Verbose |
        Foreach-Object {
            "Importing file $($_.BaseName)" | Write-Verbose
            . $_.FullName 
        }
    
    # Defining the task header for this Build Job
    if($TaskHeader) { Set-BuildHeader $TaskHeader }

    # Defining the Default task 'workflow' when invoked without -tasks parameter
    task .  Clean,
            Set_Build_Environment_Variables,
            Pester_Quality_Tests_Stop_On_Fail,
            Copy_Source_To_Module_BuildOutput,
            Merge_Source_Files_To_PSM1,
            Clean_Empty_Folders_from_Build_Output,
            Update_Module_Manifest,
            Run_Unit_Tests,
            Upload_Unit_Test_Results_To_AppVeyor,
            Fail_Build_if_Unit_Test_Failed, 
            Fail_if_Last_Code_Converage_is_Under_Threshold,
            IntegrationTests,
            Deploy_with_PSDeploy

    # Define a testAll tasks for interactive testing
    task testAll UnitTests, IntegrationTests, QualityTestsStopOnFail

    # Define a dummy task when you don't want any task executed (e.g. Only load PSModulePath)
    task Noop {}

}


begin {
    function Resolve-Dependency {
        [CmdletBinding()]
        param()

        if (!(Get-PackageProvider -Name NuGet -ForceBootstrap)) {
            $providerBootstrapParams = @{
                Name = 'nuget'
                force = $true
                ForceBootstrap = $true
            }
            if($PSBoundParameters.ContainsKey('verbose')) { $providerBootstrapParams.add('verbose',$verbose)}
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
                Scope = 'CurrentUser'
            }
            if($PSBoundParameters.ContainsKey('verbose')) { $InstallPSDependParams.add('verbose',$verbose)}
            if ($GalleryRepository) { $InstallPSDependParams.Add('Repository',$GalleryRepository) }
            if ($GalleryProxy)      { $InstallPSDependParams.Add('Proxy',$GalleryProxy) }
            if ($GalleryCredential) { $InstallPSDependParams.Add('ProxyCredential',$GalleryCredential) }
            Install-Module @InstallPSDependParams
        }

        $PSDependParams = @{
            Force = $true
            Path = "$PSScriptRoot\PSDepend.build.psd1"
        }
        if($PSBoundParameters.ContainsKey('verbose')) { $PSDependParams.add('verbose',$verbose)}
        Invoke-PSDepend @PSDependParams
        Write-Verbose "Project Bootstrapped, returning to Invoke-Build"
    }

    if (![io.path]::IsPathRooted($BuildOutput)) {
        $BuildOutput = Join-Path -Path $PSScriptRoot -ChildPath $BuildOutput
    }

    if(($Env:PSModulePath -split ';') -notcontains (Join-Path $BuildOutput 'modules') ) {
        $Env:PSModulePath = (Join-Path $BuildOutput 'modules') + ';' + $Env:PSModulePath
    }

    
    if ($ResolveDependency) {
        Write-Host "Resolving Dependencies... [this can take a moment]"
        $Params = @{}
        if ($PSboundParameters.ContainsKey('verbose')) {
            $Params.Add('verbose',$verbose)
        }
        Resolve-Dependency @Params
    }
}
