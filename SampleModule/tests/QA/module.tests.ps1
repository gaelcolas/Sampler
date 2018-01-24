$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

$modulePath = "$here\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf


Describe 'General module control' -Tags 'FunctionalQuality'  {

    It 'imports without errors' {
        { Import-Module -Name $modulePath -Force -ErrorAction Stop } | Should Not Throw
        Get-Module $moduleName | Should Not BeNullOrEmpty
    }

    It 'Removes without error' {
        { Remove-Module -Name $moduleName -ErrorAction Stop} | Should not Throw
        Get-Module $moduleName | Should beNullOrEmpty
    }
}

#$PrivateFunctions = Get-ChildItem -Path "$modulePath\Private\*.ps1"
#$PublicFunctions =  Get-ChildItem -Path "$modulePath\Public\*.ps1"
$allModuleFunctions = @()
$allModuleFunctions += Get-ChildItem -Path "$modulePath\Private\*.ps1"
$allModuleFunctions += Get-ChildItem -Path "$modulePath\Public\*.ps1"

if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
    $scriptAnalyzerRules = Get-ScriptAnalyzerRule
}
else {
    if($ErrorActionPreference -ne 'Stop') {
        Write-Warning "ScriptAnalyzer not found!"
    }
    else {
        Throw "ScriptAnalyzer not found!"
    }
}

foreach ($function in $allModuleFunctions) {
    Describe "Quality for $($function.BaseName)" -Tags 'TestQuality' {
        It "$($function.BaseName) has a unit test" {
            Get-ChildItem "$modulePath\tests\Unit\" -recurse -include "$($function.BaseName).tests.ps1" | Should Not BeNullOrEmpty
        }
            
        if ($scriptAnalyzerRules) {
            It "Script Analyzer for $($function.BaseName)" {
                forEach ($scriptAnalyzerRule in $scriptAnalyzerRules) {
                    $PSSAResult = (Invoke-ScriptAnalyzer -Path $function.FullName -IncludeRule $scriptAnalyzerRule)
                    ($PSSAResult | Select-Object Message,Line | Out-String) | Should -BeNullOrEmpty
                }
            }
        }
    }

    Describe "Help for $($function.BaseName)" -Tags 'helpQuality' {
            $AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::
                ParseInput((Get-Content -raw $function.FullName), [ref]$null, [ref]$null)
                $AstSearchDelegate = { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }
                $ParsedFunction = $AbstractSyntaxTree.FindAll( $AstSearchDelegate,$true )   |
                                    ? Name -eq $function.BaseName
            $FunctionHelp = $ParsedFunction.GetHelpContent()

            It 'Has a SYNOPSIS' {
                $FunctionHelp.Synopsis | should not BeNullOrEmpty
            }

            It 'Has a Description, with length > 40' {
                $FunctionHelp.Description.Length | Should beGreaterThan 40
            }

            It 'Has at least 1 example' {
                $FunctionHelp.Examples.Count | Should beGreaterThan 0 
                $FunctionHelp.Examples[0] | Should match ([regex]::Escape($function.BaseName))
                $FunctionHelp.Examples[0].Length | Should BeGreaterThan ($function.BaseName.Length + 10)
            }

            $parameters = $ParsedFunction.Body.ParamBlock.Parameters.name.VariablePath.Foreach{$_.ToString() }
            foreach ($parameter in $parameters) {
                It "Has help for Parameter: $parameter" {
                    $FunctionHelp.Parameters.($parameter.ToUpper())        | Should Not BeNullOrEmpty
                    $FunctionHelp.Parameters.($parameter.ToUpper()).Length | Should BeGreaterThan 25
                }
            }
    }
}

