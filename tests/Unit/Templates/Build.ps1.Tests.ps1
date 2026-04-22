Describe 'Sampler Build.ps1 template' {
    BeforeAll {
        $templatePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../Sampler/Templates/Build/build.ps1'
        $templatePath = (Resolve-Path -Path $templatePath).Path

        $tokens = $null
        $parseErrors = $null
        $script:ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $templatePath, [ref] $tokens, [ref] $parseErrors
        )
        $script:parseErrors = $parseErrors

        $script:tasksParam = $script:ast.FindAll({
                param ($node)
                $node -is [System.Management.Automation.Language.ParameterAst] -and
                $node.Name.VariablePath.UserPath -eq 'Tasks'
            }, $true) | Select-Object -First 1

        $script:completerAttr = $null
        if ($script:tasksParam)
        {
            $script:completerAttr = $script:tasksParam.Attributes |
                Where-Object { $_.TypeName.FullName -eq 'ArgumentCompleter' } |
                Select-Object -First 1
        }
    }

    It 'Parses without errors' {
        $script:parseErrors.Count | Should -Be 0
    }

    It 'Defines a $Tasks parameter' {
        $script:tasksParam | Should -Not -BeNullOrEmpty
    }

    It 'Has an ArgumentCompleter attribute on $Tasks' {
        $script:completerAttr | Should -Not -BeNullOrEmpty
    }

    Context 'When invoking the ArgumentCompleter against a fake workspace' {
        BeforeAll {
            $script:fakeRoot = Join-Path -Path $TestDrive -ChildPath 'FakeProject'
            $null = New-Item -ItemType Directory -Path $script:fakeRoot
            $null = New-Item -ItemType Directory -Path (Join-Path -Path $script:fakeRoot -ChildPath '.build')

            Set-Content -Path (Join-Path -Path $script:fakeRoot -ChildPath '.build/Foo.ps1') -Value 'task Foo {}'

            $yamlLines = @(
                'BuildWorkflow:'
                '  CompWorkflow:'
                '    - build'
                '    - test'
                '  OtherWf:'
                '    - noop'
                'NextKey: value'
            )
            Set-Content -Path (Join-Path -Path $script:fakeRoot -ChildPath 'build.yaml') -Value ($yamlLines -join [System.Environment]::NewLine)

            $fakeScriptPath = Join-Path -Path $script:fakeRoot -ChildPath 'Build.ps1'
            Set-Content -Path $fakeScriptPath -Value '# stub'

            $script:completerSource = $script:completerAttr.PositionalArguments[0].ScriptBlock.GetScriptBlock().ToString()

            # Run the completer in a fresh runspace with the fake workspace as
            # the current location. Because no script is being invoked,
            # $PSCommandPath is empty inside the runspace and the completer
            # falls back to $PWD.Path for its script root.
            function Invoke-Completer
            {
                param ([string] $WordToComplete)

                $ps = [powershell]::Create()
                try
                {
                    $null = $ps.AddScript("Set-Location -LiteralPath '$($script:fakeRoot.Replace("'", "''"))'")
                    $null = $ps.Invoke()
                    $ps.Commands.Clear()

                    $null = $ps.AddScript("`$completer = [scriptblock]::Create(@'`n$($script:completerSource)`n'@); & `$completer 'x' 'Tasks' '$WordToComplete' `$null `$null")
                    return $ps.Invoke()
                }
                finally
                {
                    $ps.Dispose()
                }
            }
        }

        It 'Returns a non-empty, sorted, deduplicated completion list' {
            $results = Invoke-Completer -WordToComplete ''
            $values = @($results | ForEach-Object { $_.CompletionText })

            $values | Should -Not -BeNullOrEmpty
            $values | Should -Contain '?'
            $values | Should -Contain 'Foo'
            $values | Should -Contain 'CompWorkflow'
            $values | Should -Contain 'OtherWf'

            # Sorted alphabetically.
            ($values -join '|') | Should -Be (($values | Sort-Object) -join '|')

            # Deduplicated (case-insensitive).
            ($values | Group-Object | Where-Object Count -gt 1) | Should -BeNullOrEmpty
        }

        It 'Filters results based on $wordToComplete' {
            $results = Invoke-Completer -WordToComplete 'Comp'
            $values = @($results | ForEach-Object { $_.CompletionText })

            $values | Should -Contain 'CompWorkflow'
            $values | Should -Not -Contain 'Foo'
            $values | Should -Not -Contain 'OtherWf'
        }

        It 'Emits CompletionResult objects with ParameterValue result type' {
            $results = @(Invoke-Completer -WordToComplete '')
            $results[0] | Should -BeOfType ([System.Management.Automation.CompletionResult])
            $results[0].ResultType | Should -Be ([System.Management.Automation.CompletionResultType]::ParameterValue)
        }
    }
}

