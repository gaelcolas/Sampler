$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# Convert-path required for PS7 or Join-Path fails
$ProjectPath = "$here\..\.." | Convert-Path
$ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
    ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
    $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch{$false}) }
).BaseName

$SourcePath = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch { $false }) }
    ).Directory.FullName

    Describe 'Changelog Management' -Tag 'Changelog' {
        It 'Changelog has been updated' -skip:(
            !([bool](Get-Command git -EA SilentlyContinue) -and
              [bool](&(Get-Process -id $PID).Path -NoProfile -Command 'git rev-parse --is-inside-work-tree 2>$null'))
            ) {
            # Get the list of changed files compared with master
            $HeadCommit = &git rev-parse HEAD
            $MasterCommit = &git rev-parse origin/master
            $filesChanged = &git diff $MasterCommit...$HeadCommit --name-only

            if($HeadCommit -ne $MasterCommit) { # if we're not testing same commit (i.e. master..master)
                $filesChanged.Where{ (Split-Path $_ -Leaf) -match '^changelog' } | Should -Not -BeNullOrEmpty
            }
        }

        It 'Changelog format compliant with keepachangelog format' -skip:(![bool](Get-Command git -EA SilentlyContinue)) {
            { Get-ChangelogData (Join-Path $ProjectPath 'CHANGELOG.md') -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Describe 'General module control' -Tags 'FunctionalQuality' {

        It 'imports without errors' {
            { Import-Module -Name $ProjectName -Force -ErrorAction Stop } | Should Not Throw
            Get-Module $ProjectName | Should Not BeNullOrEmpty
        }

        It 'Removes without error' {
            { Remove-Module -Name $ProjectName -ErrorAction Stop } | Should not Throw
            Get-Module $ProjectName | Should beNullOrEmpty
        }
    }

    #$PrivateFunctions = Get-ChildItem -Path "$ProjectPath\Private\*.ps1"
    #$PublicFunctions =  Get-ChildItem -Path "$ProjectPath\Public\*.ps1"
    $allModuleFunctions = @()
    $allModuleFunctions += Get-ChildItem -Path "$SourcePath/Private/*.ps1"
    $allModuleFunctions += Get-ChildItem -Path "$SourcePath/Public/*.ps1"

    if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
        $scriptAnalyzerRules = Get-ScriptAnalyzerRule
    }
    else {
        if ($ErrorActionPreference -ne 'Stop') {
            Write-Warning "ScriptAnalyzer not found!"
        }
        else {
            Throw "ScriptAnalyzer not found!"
        }
    }

    foreach ($function in $allModuleFunctions) {
        Describe "Quality for $($function.BaseName)" -Tags 'TestQuality' {
            It "$($function.BaseName) has a unit test" {
                Get-ChildItem "tests\" -recurse -include "$($function.BaseName).tests.ps1" | Should Not BeNullOrEmpty
            }

            if ($scriptAnalyzerRules) {
                It "Script Analyzer for $($function.BaseName)" {
                    forEach ($scriptAnalyzerRule in $scriptAnalyzerRules) {
                        $PSSAResult = (Invoke-ScriptAnalyzer -Path $function.FullName -IncludeRule $scriptAnalyzerRule)
                        ($PSSAResult | Select-Object Message, Line | Out-String) | Should -BeNullOrEmpty
                    }
                }
            }
        }

        Describe "Help for $($function.BaseName)" -Tags 'helpQuality' {
            $AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::
            ParseInput((Get-Content -raw $function.FullName), [ref]$null, [ref]$null)
            $AstSearchDelegate = { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }
            $ParsedFunction = $AbstractSyntaxTree.FindAll( $AstSearchDelegate, $true ) |
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

            $parameters = $ParsedFunction.Body.ParamBlock.Parameters.name.VariablePath.Foreach{ $_.ToString() }
            foreach ($parameter in $parameters) {
                It "Has help for Parameter: $parameter" {
                    $FunctionHelp.Parameters.($parameter.ToUpper()) | Should Not BeNullOrEmpty
                    $FunctionHelp.Parameters.($parameter.ToUpper()).Length | Should BeGreaterThan 25
                }
            }
        }
    }
