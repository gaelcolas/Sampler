
<#
    .SYNOPSIS
        Create a Sampler scaffolding so you can add samples & build pipeline.

    .DESCRIPTION
        New-SamplerPipeline helps you bootstrap your project pipeline, whether it's for a Chocolatey
        package, Azure Policy Guest Configuration packages or just a pipeline for a CI process.

    .PARAMETER DestinationPath
        Destination of your project's root folder, defaults to the current directory ".".
        We assume that your current location is the module folder, and within this folder we
        will find the source folder, the tests folder and other supporting files such as build.ps1, the entry point.

    .PARAMETER Pipeline
        Type of Pipeline you would like to create at the destination folder. You can create a base pipeline using th
        value `Build` that will include the bootstrap and resolve dependency process, but you will need to edit
        the `Build.Yaml` to call the tasks you desire.
        You can also create a Chocolatey pipeline, preconfigured to build Chocolatey packages, or call a Sampler pipeline.

    .EXAMPLE
        C:\src> New-SamplerPipeline -DestinationPath . -Pipeline Build -ProjectName MyBuild -License 'true' -LicenseType MIT -SourceDirectory Source  -MainGitBranch main -ModuleDescription 'some desc' -CustomRepo PSGallery -Features All

    .NOTES
        Other parameters will be displayed based on the Template used for the pipeline.
        See Add-Sample to add elements such as functions (private or public), tests, DSC Resources to your project.
#>
function New-SamplerPipeline
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(DefaultParameterSetName = 'ByModuleType')]
    [OutputType([System.Void])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Path')]
        [System.String]
        $DestinationPath,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            'Build',
            'ChocolateyPipeline',
            'Sampler'
            )]
        [System.String]
        $Pipeline
    )

    dynamicparam
    {
        $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary

        if ($null -eq $Pipeline)
        {
            return
        }

        $PipelineTemplateFolder = Join-Path -Path 'Templates' -ChildPath $Pipeline
        $templatePath = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath $PipelineTemplateFolder

        $previousErrorActionPreference = $ErrorActionPreference

        try
        {
            <#
                Let's convert non-terminating errors in this function to terminating so we
                catch and format the error message as a warning.
            #>
            $ErrorActionPreference = 'Stop'

            <#
                The constrained runspace is not available in the dynamicparam block.  Shouldn't be needed
                since we are only evaluating the parameters in the manifest - no need for EvaluateConditionAttribute as we
                are not building up multiple parameter sets.  And no need for EvaluateAttributeValue since we are only
                grabbing the parameter's value which is static.
            #>
            $templateAbsolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TemplatePath)

            if (-not (Test-Path -LiteralPath $templateAbsolutePath -PathType 'Container'))
            {
                throw ("Can't find plaster template at {0}." -f $templateAbsolutePath)
            }

            $plasterModule = Get-Module -Name 'Plaster'

            <#
                Load manifest file using culture lookup (using Plaster module private function GetPlasterManifestPathForCulture).
                This is the current function that is called:
                https://github.com/PowerShellOrg/Plaster/blob/0506a26ffb532a335a4e62a8da31d9ca0177ae2a/src/InvokePlaster.ps1#L1478
            #>
            $manifestPath = & $plasterModule {
                param
                (
                    [Parameter()]
                    [System.String]
                    $templateAbsolutePath,

                    [Parameter()]
                    [System.String]
                    $Culture
                )

                GetPlasterManifestPathForCulture -TemplatePath $templateAbsolutePath -Culture $Culture
            } $templateAbsolutePath $PSCulture

            if (($null -eq $manifestPath) -or (-not (Test-Path -Path $manifestPath)))
            {
                return
            }

            $manifest = Plaster\Test-PlasterManifest -Path $manifestPath -ErrorAction Stop 3>$null

            <#
                The user-defined parameters in the Plaster manifest are converted to dynamic parameters
                which allows the user to provide the parameters via the command line.
                This enables non-interactive use cases.
            #>
            foreach ($node in $manifest.plasterManifest.Parameters.ChildNodes)
            {
                if ($node -isnot [System.Xml.XmlElement])
                {
                    continue
                }

                $name = $node.name
                $type = $node.type

                if ($node.prompt)
                {
                    $prompt = $node.prompt
                }
                else
                {
                    $prompt = "Missing Parameter $name"
                }

                if (-not $name -or -not $type)
                {
                    continue
                }

                # Configure ParameterAttribute and add to attr collection.
                $attributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
                $paramAttribute = New-Object -TypeName System.Management.Automation.ParameterAttribute
                $paramAttribute.HelpMessage = $prompt
                $attributeCollection.Add($paramAttribute)

                switch -regex ($type)
                {
                    'text|user-fullname|user-email'
                    {
                        $param = [System.Management.Automation.RuntimeDefinedParameter]::new($name, [System.String], $attributeCollection)

                        break
                    }

                    'choice|multichoice'
                    {
                        $choiceNodes = $node.ChildNodes
                        $setValues = New-Object -TypeName System.String[] -ArgumentList $choiceNodes.Count
                        $i = 0

                        foreach ($choiceNode in $choiceNodes)
                        {
                            $setValues[$i++] = $choiceNode.value
                        }

                        $validateSetAttr = New-Object -TypeName System.Management.Automation.ValidateSetAttribute -ArgumentList $setValues
                        $attributeCollection.Add($validateSetAttr)

                        if ($type -eq 'multichoice')
                        {
                            $type = [System.String[]]
                        }
                        else
                        {
                            $type = [System.String]
                        }

                        $param = [System.Management.Automation.RuntimeDefinedParameter]::new($name, $type, $attributeCollection)

                        break
                    }

                    default
                    {
                        throw "Unrecognized Parameter Type $type for attribute $name."
                    }
                }

                $paramDictionary.Add($name, $param)
            }
        }
        catch
        {
            Write-Warning -Message "Error processing Dynamic Parameters. $($_.Exception.Message)"
        }
        finally
        {
            $ErrorActionPreference = $previousErrorActionPreference
        }

        $paramDictionary
    }

    end
    {
        # Clone the the bound parameters.
        $plasterParameter = @{} + $PSBoundParameters

        $null = $plasterParameter.Remove('Pipeline')

        $PipelineTemplateFolder = Join-Path -Path 'Templates' -ChildPath $Pipeline
        $templatePath = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath $PipelineTemplateFolder

        $plasterParameter.Add('TemplatePath', $templatePath)

        if (-not $plasterParameter.ContainsKey('DestinationPath'))
        {
            $plasterParameter['DestinationPath'] = $DestinationPath
        }

        Invoke-Plaster @plasterParameter
    }
}
