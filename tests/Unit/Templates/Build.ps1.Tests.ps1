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

            # Tasks file with both a real task and a comment line that begins
            # with the literal text "task something" but is not a real task
            # declaration. The completer must NOT pick up "comment" as a task.
            $tricky = @(
                'task Bar { }'
                '<#'
                '    task comment $foo is described in the help block'
                '#>'
            ) -join [System.Environment]::NewLine
            Set-Content -Path (Join-Path -Path $script:fakeRoot -ChildPath '.build/Bar.ps1') -Value $tricky

            # The fixture exercises three things:
            #   1. Plain workflow aliases (CompWorkflow, OtherWf, TrailingWf).
            #   2. An in-yaml scriptblock value with nested braces (Inline). Its
            #      key must be picked up, but identifiers that appear *inside*
            #      the scriptblock body must not be treated as workflow aliases.
            #   3. A non-workflow root key (NextKey) that terminates the block.
            $yamlLines = @(
                'BuildWorkflow:'
                ''
                '  CompWorkflow:'
                '    - build'
                '    - test'
                ''
                '  OtherWf:'
                '    - noop'
                ''
                '  # An in-yaml scriptblock value with nested braces.'
                '  Inline: {'
                '    if ($true) {'
                '      InnerKey: not_a_workflow'
                '    }'
                '  }'
                ''
                '  TrailingWf:'
                '    - x'
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
                param
                (
                    [Parameter(Mandatory = $true)]
                    [AllowEmptyString()]
                    [System.String]
                    $WordToComplete
                )

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

        It 'Returns the workflow aliases, the local task and the help token' {
            $results = Invoke-Completer -WordToComplete ''
            $values = @($results | ForEach-Object { $_.CompletionText })

            $values | Should -Not -BeNullOrEmpty
            $values | Should -Contain '?'
            $values | Should -Contain 'Foo'
            $values | Should -Contain 'Bar'
            $values | Should -Contain 'CompWorkflow'
            $values | Should -Contain 'OtherWf'
            $values | Should -Contain 'Inline'
            $values | Should -Contain 'TrailingWf'
        }

        It 'Does not pick up identifiers from comment text that mentions "task <name>"' {
            $results = Invoke-Completer -WordToComplete ''
            $values = @($results | ForEach-Object { $_.CompletionText })

            # 'comment' appears inside a <# ... #> help block on a line that
            # reads 'task comment $foo is described ...'. The regex must reject
            # it because it is followed by a $ variable reference, which is
            # not a valid Invoke-Build task signature.
            $values | Should -Not -Contain 'comment'
        }

        It 'Does not pick up identifiers inside an in-yaml scriptblock value' {
            $results = Invoke-Completer -WordToComplete ''
            $values = @($results | ForEach-Object { $_.CompletionText })

            # 'InnerKey' lives inside the Inline scriptblock body and must not
            # be treated as a top-level workflow alias.
            $values | Should -Not -Contain 'InnerKey'
        }

        It 'Preserves YAML / file declaration order (no alphabetical sort)' {
            $results = Invoke-Completer -WordToComplete ''
            $values = @($results | ForEach-Object { $_.CompletionText })

            # Workflow aliases appear in their declaration order from the YAML,
            # followed by the local '.build/' tasks (in Get-ChildItem order,
            # which is alphabetical by file name on Windows: Bar.ps1, Foo.ps1),
            # followed by the Invoke-Build help token. We assert *relative*
            # order rather than equality, to stay robust to other workspace
            # artefacts that the completer may legitimately discover.
            $expectedOrder = @('CompWorkflow', 'OtherWf', 'Inline', 'TrailingWf', 'Bar', 'Foo', '?')

            $actualPositions = foreach ($name in $expectedOrder)
            {
                [System.Array]::IndexOf([System.Object[]] $values, $name)
            }

            $actualPositions | Should -Not -Contain -1

            $sortedPositions = $actualPositions | Sort-Object
            ($actualPositions -join '|') | Should -Be ($sortedPositions -join '|')
        }

        It 'Deduplicates entries (case-insensitive)' {
            $results = Invoke-Completer -WordToComplete ''
            $values = @($results | ForEach-Object { $_.CompletionText })

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
