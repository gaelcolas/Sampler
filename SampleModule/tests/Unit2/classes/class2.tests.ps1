InModuleScope SampleModule {
    Describe class1 {
        Context 'Type creation' {
            It 'Has created a type named class2' {
                'class2' -as [Type] | Should -BeOfType [Type]
            }
        }

        Context 'Constructors' {
            It 'Has a default constructor' {
                [class2]::new() | Should -BeOfType [class2]
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