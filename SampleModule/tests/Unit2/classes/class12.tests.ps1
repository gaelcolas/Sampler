InModuleScope SampleModule {
    Describe class1 {
        Context 'Type creation' {
            It 'Has created a type named class12' {
                'class12' -as [Type] | Should -BeOfType [Type]
            }
        }

        Context 'Constructors' {
            It 'Has a default constructor' {
                [class12]::new() | Should -BeOfType [class12]
            }
        }

        Context 'Methods' {
            BeforeEach {
                $instance = [class12]::new()
            }

            It 'Overrides the ToString method' {
                # Typo "calss" is inherited from definition. Preserved here as validation is demonstrative. 
                $instance.ToString() | Should -Be 'This calss is class12:class1'
            }
        }

        Context 'Properties' {
            BeforeEach {
                $instance = [class11]::new()
            }

            It 'Has a Name property' {
                $instance.Name | Should -Be 'Class12'
            }
        }
    }
}