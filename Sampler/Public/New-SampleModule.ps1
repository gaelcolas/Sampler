function New-SampleModule
{
    [CmdletBinding(DefaultParameterSetName = 'ByModuleType')]
    [OutputType([void])]
    param (
        [Parameter()]
        [Alias('Path')]
        [string]
        $DestinationPath = $(Read-Host -Prompt "Type '.' to use the current folder as destination, or type a path."),

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
        if (($paramValue = Get-Variable -Name $paramName -ValueOnly -ErrorAction SilentlyContinue) -and
            (-not $invokePlasterParam.ContainsKey($paramName))
        )
        {
            if ($paramName -eq 'LicenseType' -and $paramValue -eq 'none')
            {
                $invokePlasterParam.add('License', 'false')
                continue
            }
            elseif ($paramName -eq 'LicenseType')
            {
                $invokePlasterParam.add('License', 'true')
            }

            $invokePlasterParam.add($paramName, $paramValue)
        }
    }

    Invoke-Plaster @invokePlasterParam
}
