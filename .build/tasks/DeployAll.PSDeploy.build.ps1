Param (
    [string]
    $BuildOutput = (property BuildOutput 'BuildOutput'),

    [string]
    $ProjectName = (property ProjectName (Split-Path -Leaf $BuildRoot) ),

    [string]
    $PesterOutputFormat = (property PesterOutputFormat 'NUnitXml'),

    [string]
    $APPVEYOR_JOB_ID = $(try {property APPVEYOR_JOB_ID} catch {}),

    $DeploymentTags = $(try {property DeploymentTags} catch {}),

    $DeployConfig = (property DeployConfig 'Deploy.PSDeploy.ps1')
)

# Synopsis: Deploy everything configured in PSDeploy
task Deploy_with_PSDeploy {

    if (![io.path]::IsPathRooted($BuildOutput)) {
        $BuildOutput = Join-Path -Path $BuildRoot -ChildPath $BuildOutput
    }

    $DeployFile =  [io.path]::Combine($BuildRoot, $DeployConfig)
    
    "Deploying Module based on $DeployConfig config"
    
    $InvokePSDeployArgs = @{
        Path    = $DeployFile
        Force   = $true
    }

    if($DeploymentTags) {
        $null = $InvokePSDeployArgs.Add('Tags',$DeploymentTags)
    }
    
    Import-Module PSDeploy
    Invoke-PSDeploy @InvokePSDeployArgs
}