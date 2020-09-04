function New-SampleModule
{
    [CmdletBinding(DefaultParameterSetName = 'ByModuleType')]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('Path')]
        [string]
        $DestinationPath,

        [Parameter(ParameterSetName = 'ByModuleType')]
        [string]
        [ValidateSet('SimpleModule_NoBuild','SimpleModule', 'CompleteModule', 'CompleteModule_NoBuild', 'dsccommunity')]
        $ModuleType = 'SimpleModule',

        [Parameter()]
        [string]
        $ModuleAuthor = $Env:USERNAME,

        [Parameter(Mandatory = $true)]
        [string]
        $ModuleName,

        [Parameter()]
        [AllowNull()]
        [string]
        $ModuleDescription,

        [Parameter()]
        [string]
        $CustomRepo = 'PSGallery',

        [Parameter()]
        [string]
        $ModuleVersion = '0.0.1',

        [Parameter()]
        [string]
        [ValidateSet('MIT','Apache','None')]
        $LicenseType = 'MIT',

        [Parameter()]
        [string]
        # Validate source, src, $ModuleName
        [ValidateSet('source','src')]
        $SourceDirectory = 'source',

        [Parameter(ParameterSetName = 'ByFeature')]
        [ValidateSet('All',
            'Enum',
            'Classes',
            'DSCResources',
            'ClassDSCResource',
            'SampleScripts',
            'git',
            'Gherkin',
            'UnitTests',
            'ModuleQuality',
            'Build',
            'AppVeyor',
            'TestKitchen'
            )]
        [string[]]
        $Features
    )

    $templateSubPath = 'Templates/Sampler'
    $samplerBase = $MyInvocation.MyCommand.Module.ModuleBase

    $invokePlasterParam = @{
        TemplatePath = Join-Path -Path $samplerBase -ChildPath $templateSubPath
        DestinationPath   = $DestinationPath
        NoLogo            = $true
        ModuleName        = $ModuleName
    }

    foreach ($paramName in $MyInvocation.MyCommand.Parameters.Keys)
    {
        $paramValue = Get-Variable -Name $paramName -ValueOnly -ErrorAction SilentlyContinue
        # if $paramName is $null, leave it to Plaster to ask the user
        if ($paramvalue -and -not $invokePlasterParam.ContainsKey($paramName))
        {
            $invokePlasterParam.add($paramName, $paramValue)
        }
    }

    if ($LicenseType -eq 'none')
    {
        $invokePlasterParam.Remove('LicenseType')
        $invokePlasterParam.add('License', 'false')
    }
    else
    {
        $invokePlasterParam.add('License', 'true')
    }

    Invoke-Plaster @invokePlasterParam
}
