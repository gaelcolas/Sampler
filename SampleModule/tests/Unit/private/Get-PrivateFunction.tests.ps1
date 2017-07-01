InModuleScope SampleModule {
    Describe Get-PrivateFunction {
        Context 'Default' {
            BeforeEach {
                $return = Get-PrivateFunction -PrivateData 'string'
            }

            It 'Returns a single object' {
                ($return | Measure-Object).Count | Should -Be 1
            }

            It 'Returns a string based on the parameter PrivateData' {
                $return | Should -Be 'string'
            }
        }
    }
}