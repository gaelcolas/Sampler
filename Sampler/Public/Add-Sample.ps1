function Add-Sample
{
    [CmdletBinding()]
    [OutputType()]
    param (
        [Parameter()]
        # Add a sample component based on the Plaster templates embedded with this module.
        [ValidateSet('Classes','ClassResource','Composite','Enum','Examples','MofResource','PrivateFunction','PublicCallPrivateFunctions','PublicFunction')]
        [string]
        $Sample,

        [Parameter()]
        # Destination folder where to add the Sample files to the module.
        # This assume the repository root folder, not the source folder.
        [string]
        $DestinationPath = '.'
    )

    dynamicParam
    {

        $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        if ($null -eq $Sample)
        {
            return
        }

        $sampleTemplateFolder = Join-Path -Path 'Templates' -ChildPath $Sample
        $templatePath = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath $sampleTemplateFolder

        if (-not (Test-Path $templateManifest))
        {
            return
        }

        try
        {
            # Let's convert non-terminating errors in this function to terminating so we
            # catch and format the error message as a warning.
            $ErrorActionPreference = 'Stop'

            # The constrained runspace is not available in the dynamicparam block.  Shouldn't be needed
            # since we are only evaluating the parameters in the manifest - no need for EvaluateConditionAttribute as we
            # are not building up multiple parametersets.  And no need for EvaluateAttributeValue since we are only
            # grabbing the parameter's value which is static.
            $templateAbsolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TemplatePath)
            if (!(Test-Path -LiteralPath $templateAbsolutePath -PathType Container))
            {
                throw ($LocalizedData.ErrorTemplatePathIsInvalid_F1 -f $templateAbsolutePath)
            }

            $plasterModule = Get-Module Plaster

            # Load manifest file using culture lookup (using Plaster module private function GetPlasterManifestPathForCulture)
            $manifestPath = &$plasterModule {
                param (
                    $templateAbsolutePath,
                    $PSCulture
                )
                 GetPlasterManifestPathForCulture $templateAbsolutePath $PSCulture
            } $templateAbsolutePath $PSCulture

            if (($null -eq $manifestPath) -or (!(Test-Path $manifestPath)))
            {
                return
            }

            $manifest = Plaster\Test-PlasterManifest -Path $manifestPath -ErrorAction Stop 3>$null

            # The user-defined parameters in the Plaster manifest are converted to dynamic parameters
            # which allows the user to provide the parameters via the command line.
            # This enables non-interactive use cases.
            foreach ($node in $manifest.plasterManifest.parameters.ChildNodes)
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

                if (!$name -or !$type)
                {
                    continue
                }

                # Configure ParameterAttribute and add to attr collection
                $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                $paramAttribute = New-Object System.Management.Automation.ParameterAttribute
                $paramAttribute.HelpMessage = $prompt
                $attributeCollection.Add($paramAttribute)

                switch -regex ($type)
                {
                    'text|user-fullname|user-email' {
                        $param = [System.Management.Automation.RuntimeDefinedParameter]::new($name, [string], $attributeCollection)
                        break
                    }

                    'choice|multichoice' {
                        $choiceNodes = $node.ChildNodes
                        $setValues = New-Object string[] $choiceNodes.Count
                        $i = 0

                        foreach ($choiceNode in $choiceNodes)
                        {
                            $setValues[$i++] = $choiceNode.value
                        }

                        $validateSetAttr = New-Object System.Management.Automation.ValidateSetAttribute $setValues
                        $attributeCollection.Add($validateSetAttr)

                        if ($type -eq 'multichoice')
                        {
                            $type = [string[]]
                        }
                        else
                        {
                            $type = [string]
                        }

                        $param = [System.Management.Automation.RuntimeDefinedParameter]::new($name, $type, $attributeCollection)
                        break
                    }

                    default {
                        throw "Unrecognized Parameter Type $type for attribute $name"
                    }
                }

                $paramDictionary.Add($name, $param)
            }
        }
        catch
        {
            Write-Warning "Error processing Dynamic Parameters. $($_.Exception.Message)"
        }

        $paramDictionary
    }

    process {
        $plasterParameter = $PSBoundParameters
        $null = $plasterParameter.remove('Sample')
        $sampleTemplateFolder = Join-Path -Path 'Templates' -ChildPath $Sample
        $templatePath = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath $sampleTemplateFolder
        $plasterParameter.Add('TemplatePath', $templatePath)
        if (-not $plasterParameter.ContainsKey('DestinationPath'))
        {
            $plasterParameter['DestinationPath'] = $DestinationPath
        }

        Invoke-Plaster @plasterParameter
    }
}
