$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            {
                Test-ModuleManifest $_.FullName -ErrorAction Stop
            }
            catch
            {
                $false
            } )
    }).BaseName

Import-Module $ProjectName

Describe 'New-JaCoCoDocument' {
    BeforeAll {
        # TODO: Move this function to TestHelpers and reuse it in other tests
        function Get-XmlAttribute
        {
            [CmdletBinding()]
            [OutputType([Hashtable])]
            param
            (
                [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
                [System.Xml.XmlDocument]
                $XmlDocument,

                [Parameter(Mandatory = $true)]
                [System.String]
                $XPath
            )

            $attributeValues = @{}

            $filteredDocument = $XmlDocument | Select-Xml -XPath $XPath

            ($filteredDocument.Node | Select-Xml -XPath '@*').Node | ForEach-Object -Process {
                $attributeValues[$_.Name] = $_.Value
            }

            return $attributeValues
        }
    }

    AfterEach {
        if ($null -ne $result)
        {
            Write-Verbose -Message (Format-Xml -XmlDocument $result)
        }
    }

    Context 'When calculating statistics for a single package' {
        BeforeAll {
            $mockHitCommands = [PSCustomObject] @{
                Class            = 'ResourceBase'
                Function         = 'Compare'
                HitCount         = 2
                SourceFile       = '.\Classes\001.ResourceBase.ps1'
                SourceLineNumber = 3
            }

            $mockMissedCommands = [PSCustomObject] @{
                Class            = 'ResourceBase'
                Function         = 'Compare'
                HitCount         = 0
                SourceFile       = '.\Classes\001.ResourceBase.ps1'
                SourceLineNumber = 4
            }

            $mockPackageName = '3.0.0'
        }

        It 'Should have added the report counter <CounterName> with the correct attributes' -TestCases @(
            @{
                CounterName = 'INSTRUCTION'
            }
            @{
                CounterName = 'LINE'
            }
            @{
                CounterName = 'METHOD'
            }
            @{
                CounterName = 'CLASS'
            }
        ) {
            param
            (
                $CounterName
            )

            $result = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $xPath = '/report/counter[@type="{0}"]' -f $CounterName

            $attributes = $result | Get-XmlAttribute -XPath $xPath

            switch ($CounterName)
            {
                'INSTRUCTION'
                {
                    $attributes.missed | Should -Be 1
                    $attributes.covered | Should -Be 1
                }

                'LINE'
                {
                    $attributes.missed | Should -Be 1
                    $attributes.covered | Should -Be 1
                }

                'METHOD'
                {
                    $attributes.missed | Should -Be 0
                    $attributes.covered | Should -Be 1
                }

                'CLASS'
                {
                    $attributes.missed | Should -Be 0
                    $attributes.covered | Should -Be 1
                }
            }
        }

        It 'Should have added one package name with the correct attributes' {
            $result = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $xPath = '/report/package'

            ($result | Get-XmlAttribute -XPath $xPath).name | Should -Be $mockPackageName
        }

        It 'Should have added the package counter <CounterName> with the correct attributes' -TestCases @(
            @{
                CounterName = 'INSTRUCTION'
            }
            @{
                CounterName = 'LINE'
            }
            @{
                CounterName = 'METHOD'
            }
            @{
                CounterName = 'CLASS'
            }
        ) {
            param
            (
                $CounterName
            )

            $result = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $xPath = '/report/package[@name="{0}"]/counter[@type="{1}"]' -f $mockPackageName, $CounterName

            $attributes = $result | Get-XmlAttribute -XPath $xPath

            switch ($CounterName)
            {
                'INSTRUCTION'
                {
                    $attributes.missed | Should -Be 1
                    $attributes.covered | Should -Be 1
                }

                'LINE'
                {
                    $attributes.missed | Should -Be 1
                    $attributes.covered | Should -Be 1
                }

                'METHOD'
                {
                    $attributes.missed | Should -Be 0
                    $attributes.covered | Should -Be 1
                }

                'CLASS'
                {
                    $attributes.missed | Should -Be 0
                    $attributes.covered | Should -Be 1
                }
            }
        }

        It 'Should have added the one class with the correct attributes' {
            $result = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $xPath = '/report/package[@name="{0}"]/class' -f $mockPackageName

            $attributes = $result | Get-XmlAttribute -XPath $xPath

            $attributes.name | Should -Be 'ResourceBase'
            $attributes.sourcefilename | Should -Be 'Classes/001.ResourceBase.ps1'
        }

        It 'Should have added the class counter <CounterName> with the correct attributes' -TestCases @(
            @{
                CounterName = 'INSTRUCTION'
            }
            @{
                CounterName = 'LINE'
            }
            @{
                CounterName = 'METHOD'
            }
            @{
                CounterName = 'CLASS'
            }
        ) {
            param
            (
                $CounterName
            )

            $result = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $xPath = '/report/package[@name="{0}"]/class/counter[@type="{1}"]' -f $mockPackageName, $CounterName

            $attributes = $result | Get-XmlAttribute -XPath $xPath

            switch ($CounterName)
            {
                'INSTRUCTION'
                {
                    $attributes.missed | Should -Be 1
                    $attributes.covered | Should -Be 1
                }

                'LINE'
                {
                    $attributes.missed | Should -Be 1
                    $attributes.covered | Should -Be 1
                }

                'METHOD'
                {
                    $attributes.missed | Should -Be 0
                    $attributes.covered | Should -Be 1
                }

                'CLASS'
                {
                    $attributes.missed | Should -Be 0
                    $attributes.covered | Should -Be 1
                }
            }
        }

        It 'Should have added the one method with the correct attributes' {
            $result = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $xPath = '/report/package[@name="{0}"]/class/method' -f $mockPackageName

            $attributes = $result | Get-XmlAttribute -XPath $xPath

            $attributes.name | Should -Be 'Compare'
            $attributes.desc | Should -Be '()'
            $attributes.line | Should -Be '3'
        }

        It 'Should have added the method counter <CounterName> with the correct attributes' -TestCases @(
            @{
                CounterName = 'INSTRUCTION'
            }
            @{
                CounterName = 'LINE'
            }
            @{
                CounterName = 'METHOD'
            }
        ) {
            param
            (
                $CounterName
            )

            $result = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $xPath = '/report/package[@name="{0}"]/class/method/counter[@type="{1}"]' -f $mockPackageName, $CounterName

            $attributes = $result | Get-XmlAttribute -XPath $xPath

            switch ($CounterName)
            {
                'INSTRUCTION'
                {
                    $attributes.missed | Should -Be 1
                    $attributes.covered | Should -Be 1
                }

                'LINE'
                {
                    $attributes.missed | Should -Be 1
                    $attributes.covered | Should -Be 1
                }

                'METHOD'
                {
                    $attributes.missed | Should -Be 0
                    $attributes.covered | Should -Be 1
                }
            }
        }

        It 'Should have added the one source file with the correct attributes' {
            $result = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $xPath = '/report/package[@name="{0}"]/sourcefile' -f $mockPackageName

            $attributes = $result | Get-XmlAttribute -XPath $xPath

            $attributes.name | Should -Be 'Classes/001.ResourceBase.ps1'
        }

        It 'Should have added the source file line <LineNumber> with the correct attributes' -TestCases @(
            @{
                LineNumber = 3
            }
            @{
                LineNumber = 4
            }
        ) {
            param
            (
                $LineNumber
            )

            $result = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $xPath = '/report/package[@name="{0}"]/sourcefile/line[@nr="{1}"]' -f $mockPackageName, $LineNumber

            $attributes = $result | Get-XmlAttribute -XPath $xPath

            switch ($LineNumber)
            {
                '3'
                {
                    $attributes.mi | Should -Be 0
                    $attributes.ci | Should -Be 1
                    $attributes.mb | Should -Be 0
                    $attributes.cb | Should -Be 0
                }

                '4'
                {
                    $attributes.mi | Should -Be 1
                    $attributes.ci | Should -Be 0
                    $attributes.mb | Should -Be 0
                    $attributes.cb | Should -Be 0
                }
            }
        }

        It 'Should have added the source file counter <CounterName> with the correct attributes' -TestCases @(
            @{
                CounterName = 'INSTRUCTION'
            }
            @{
                CounterName = 'LINE'
            }
            @{
                CounterName = 'METHOD'
            }
            @{
                CounterName = 'CLASS'
            }
        ) {
            param
            (
                $CounterName
            )

            $result = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $xPath = '/report/package[@name="{0}"]/sourcefile/counter[@type="{1}"]' -f $mockPackageName, $CounterName

            $attributes = $result | Get-XmlAttribute -XPath $xPath

            switch ($CounterName)
            {
                'INSTRUCTION'
                {
                    $attributes.missed | Should -Be 1
                    $attributes.covered | Should -Be 1
                }

                'LINE'
                {
                    $attributes.missed | Should -Be 1
                    $attributes.covered | Should -Be 1
                }

                'METHOD'
                {
                    $attributes.missed | Should -Be 0
                    $attributes.covered | Should -Be 1
                }

                'CLASS'
                {
                    $attributes.missed | Should -Be 0
                    $attributes.covered | Should -Be 1
                }
            }
        }
    }
}
