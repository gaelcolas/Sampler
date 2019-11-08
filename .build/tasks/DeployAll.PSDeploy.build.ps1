Param (
    [Parameter()]
    [string]
    $BuildOutput = (property BuildOutput 'BuildOutput'),

    [Parameter()]
    [string]
    $ProjectName = (property ProjectName $(
            (Get-ChildItem $BuildRoot\*\*.psd1 | Where-Object {
                    ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                    $(try {
                            Test-ModuleManifest $_.FullName -ErrorAction Stop
                        }
                        catch {
                            $false
                        }) }
            ).BaseName
        )
    ),

    [Parameter()]
    [string]
    $PesterOutputFormat = (property PesterOutputFormat 'NUnitXml'),

    [Parameter()]
    [string]
    $APPVEYOR_JOB_ID = $(try {
            property APPVEYOR_JOB_ID
        }
        catch { ''
        }),

    [Parameter()]
    $DeploymentTags = $(try {
            property DeploymentTags
        }
        catch { ''
        }),

    [Parameter()]
    $DeployConfig = (property DeployConfig 'Deploy.PSDeploy.ps1')
)

# Synopsis: Deploy everything configured in PSDeploy
task Deploy_with_PSDeploy {

    if (![io.path]::IsPathRooted($BuildOutput)) {
        $BuildOutput = Join-Path -Path $BuildRoot -ChildPath $BuildOutput
    }

    $DeployFile = [io.path]::Combine($BuildRoot, $DeployConfig)

    "Deploying Module based on $DeployConfig config"

    $InvokePSDeployArgs = @{
        Path  = $DeployFile
        Force = $true
    }

    if ($DeploymentTags) {
        $null = $InvokePSDeployArgs.Add('Tags', $DeploymentTags)
    }

    Import-Module PSDeploy
    Invoke-PSDeploy @InvokePSDeployArgs
}
