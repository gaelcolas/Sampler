param (
    [Parameter()]
    [string]
    $BuildOutput = (property BuildOutput 'BuildOutput'),

    [Parameter()]
    [string]
    $ProjectName = (property ProjectName ''),

    [Parameter()]
    [string]
    $PesterOutputFormat = (property PesterOutputFormat 'NUnitXml'),

    [Parameter()]
    [string]
    $APPVEYOR_JOB_ID = $(try
        {
            property APPVEYOR_JOB_ID
        }
        catch
        {
            ''
        }),

    [Parameter()]
    $DeploymentTags = $(try
        {
            property DeploymentTags
        }
        catch
        {
            ''
        }),

    [Parameter()]
    $DeployConfig = (property DeployConfig 'Deploy.PSDeploy.ps1')
)

# Synopsis: Deploy everything configured in PSDeploy
task Deploy_with_PSDeploy {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    if (![io.path]::IsPathRooted($BuildOutput))
    {
        $BuildOutput = Join-Path -Path $BuildRoot -ChildPath $BuildOutput
    }

    $DeployFile = [io.path]::Combine($BuildRoot, $DeployConfig)

    "Deploying Module based on $DeployConfig config"

    $InvokePSDeployArgs = @{
        Path  = $DeployFile
        Force = $true
    }

    if ($DeploymentTags)
    {
        $null = $InvokePSDeployArgs.Add('Tags', $DeploymentTags)
    }

    Import-Module PSDeploy
    Invoke-PSDeploy @InvokePSDeployArgs
}
