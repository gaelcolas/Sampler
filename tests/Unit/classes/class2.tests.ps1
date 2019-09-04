$here = $PSScriptRoot
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

$modulePath = "$here\..\..\.." | Convert-Path
if (!$ProjectName) {
    $ProjectName = $(
        try {
            (Split-Path (git config --get remote.origin.url) -Leaf) -replace '\.git'
        }
        catch {
            Split-Path -Path $modulePath -Leaf
        }
    )
}

Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe class2 {
        Context 'Type creation' {
            It 'Has created a type named class2' {
                'class2' -as [Type] | Should -BeOfType [Type]
            }
        }

        Context 'Constructors' {
            It 'Has a default constructor' {
                $instance = [class2]::new()
                $instance | Should -Not -BeNullOrEmpty
                $instance.GetType().Name | Should -Be 'class2'
            }
        }

        Context 'Methods' {
            BeforeEach {
                $instance = [class2]::new()
            }

            It 'Overrides the ToString method' {
                # Typo "calss" is inherited from definition. Preserved here as validation is demonstrative.
                $instance.ToString() | Should -Be 'This calss is class2'
            }
        }

        Context 'Properties' {
            BeforeEach {
                $instance = [class2]::new()
            }

            It 'Has a Name property' {
                $instance.Name | Should -Be 'Class2'
            }
        }
    }
}
