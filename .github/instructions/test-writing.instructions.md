---
description: 'Pester test authoring instructions'
applyTo: 'tests/**.Tests.ps1'
---

# Pester Tests Development Guidelines

## Blueprint structure

Every test file **must** begin with this exact top-level `BeforeAll` / `AfterAll` pair. Do not omit or reorder any line.

```powershell
BeforeAll {
    $script:moduleName = 'Sampler'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 2)
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    }

    # Re-import the module using force to get any code changes between runs.
    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Module -Name $script:moduleName
}
```

- The `$PSDefaultParameterValues` entries for `InModuleScope`, `Mock`, and `Should` scope all Pester commands to the module under test automatically — **always include them**.
- The `AfterAll` block must remove those same keys and unload the module to avoid state leaking between test runs.
- If mocking is required, mock only external boundaries (functions or cmdlets outside of the module), not internal pure helpers.
- Use `BeforeDiscovery` (outside `Describe`) for data-driven test cases passed via `-ForEach`.
- Place test-case-specific mocks in a `BeforeAll` block **inside** the relevant `Describe` or `Context` block, not at the top level.

## `It` block naming

- Start every `It` description with **`Should`** followed by a plain-English statement of the expected outcome:
  ```powershell
  It 'Should return the correct semantic version' { ... }
  It 'Should not throw an exception when instantiated' { ... }
  It 'Should return $false for missing attribute' { ... }
  ```
- For data-driven tests use `-ForEach` (Pester 5) and embed the case variable in the name with `<VariableName>`:
  ```powershell
  It 'Should call Invoke-Plaster with test case <TestCaseName>' -ForEach $testCases { ... }
  ```
- Use `-Skip:(<booleanExpression>)` for platform-conditional tests; never delete or comment them out:
  ```powershell
  It 'Should set the PSModulePath correctly' -Skip:(-not $IsWindows) { ... }
  ```

## Assertion style

Use the most specific assertion available — avoid `Should -Be $true` when a dedicated form exists.

| Scenario | Preferred assertion |
|---|---|
| Exact value match | `Should -Be 'value'` |
| Case-sensitive match | `Should -BeExactly 'Value'` |
| Regex match | `Should -Match 'pattern'` |
| Boolean true/false | `Should -BeTrue` / `Should -BeFalse` |
| Null or empty | `Should -BeNullOrEmpty` / `Should -Not -BeNullOrEmpty` |
| Exception expected | `{ ... } \| Should -Throw` |
| No exception expected | `{ ... } \| Should -Not -Throw` |
| Mock was called | `Should -Invoke -CommandName X -Exactly -Times 1 -Scope It` |
| Type check | `$x \| Should -BeOfType [ExpectedType]` |

- Always scope mock-call assertions with `-Scope It` so counts reset between tests.
- Call the function under test with its module-qualified name (`Sampler\Get-Foo`) to avoid accidentally calling a mock or a stale imported version.
