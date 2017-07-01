InModuleScope SampleModule {
    Describe class11 {
        Context 'Type creation' {
            It 'Has created a type named class11' {
                'class11' -as [Type] | Should -BeOfType [Type]
            }
        }

        Context 'Constructors' {
            It 'Has a default constructor' {
                $instance = [class11]::new()
                $instance | Should -Not -BeNullOrEmpty
                $instance.GetType().Name | Should -Be 'class11'
            }
        }

        Context 'Methods' {
            BeforeEach {
                $instance = [class11]::new()
            }

            It 'Overrides the ToString method' {
                # Typo "calss" is inherited from definition. Preserved here as validation is demonstrative. 
                $instance.ToString() | Should -Be 'This calss is class11:class1'
            }
        }

        Context 'Properties' {
            BeforeEach {
                $instance = [class11]::new()
            }

            It 'Has a Name property' {
                $instance.Name | Should -Be 'Class11'
            }
        }
    }
}