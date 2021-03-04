<#
.SYNOPSIS
Adding code elements (function, enum, class, DSC Resource, tests...) to a module's source.

.DESCRIPTION
Add-Sample is an helper function to invoke a plaster template built-in the Sampler module.
With this function you can bootstrap your module project by adding classes, functions and
associated tests, examples and configuration elements.

.PARAMETER Sample
Specifies a sample component based on the Plaster templates embedded with this module.
The available types of module elements are:
    - Classes: A sample of 4 classes with inheritence and how to manage the orders to avoid parsing errors.
    - ClassResource: A Class-Based DSC Resources showing some best practices including tests, Reasons, localized strings.
    - Composite: A DSC Composite Resource (a configuration block) packaged the right way to make sure it's visible by Get-DscResource.
    - Enum: An example of a simple Enum.
    - MofResource: A sample of a MOF-Based DSC Resource following the DSC Community practices.
    - PrivateFunction: A sample of a Private function (not exported from the module) and its test.
    - PublicCallPrivateFunctions: A sample of 2 functions where the exported one (public) calls the private one, with the tests.
    - PublicFunction: A sample public function and its test.

.PARAMETER DestinationPath
Destination of your module source root folder, defaults to the current directory ".".
We assume that your current location is the module folder, and within this folder we
will find the source folder, the tests folder and other supporting files.

.EXAMPLE
C:\src\MyModule> Add-Sample -Sample PublicFunction -PublicFunctionName Get-MyStuff

.NOTES
This module requires and uses Plaster.
#>
function Add-Sample
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding()]
    [OutputType()]
    param
    (
        [Parameter()]
        # Add a sample component based on the Plaster templates embedded with this module.
        [ValidateSet('Classes', 'ClassFolderResource', 'ClassResource', 'Composite', 'Enum', 'Examples', 'GithubConfig', 'GCPackage', 'HelperSubModules', 'MofResource', 'PrivateFunction', 'PublicCallPrivateFunctions', 'PublicFunction', 'VscodeConfig')]
        [string]
        $Sample,

        [Parameter()]
        [System.String]
        $DestinationPath = '.'
    )

    dynamicparam
    {
        $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary

        if ($null -eq $Sample)
        {
            return
        }

        $sampleTemplateFolder = Join-Path -Path 'Templates' -ChildPath $Sample
        $templatePath = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath $sampleTemplateFolder

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
            Write-Warning "Error processing Dynamic Parameters. $($_.Exception.Message)"
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

        $null = $plasterParameter.Remove('Sample')

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
