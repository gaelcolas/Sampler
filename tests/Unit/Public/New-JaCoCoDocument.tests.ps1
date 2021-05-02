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
    AfterEach {
        if ($null -ne $xmlResult)
        {
            Write-Verbose -Message (Format-Xml -XmlDocument $xmlResult)
        }
    }

    Context 'When calculating statistics for a single package' {
        Context 'When there are just one class' {
            Context 'When there are one hit and one miss' {
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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/counter[@type="{0}"]' -f $CounterName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

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
                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package'

                    ($xmlResult | Get-XmlAttribute -XPath $xPath).name | Should -Be $mockPackageName
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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/counter[@type="{1}"]' -f $mockPackageName, $CounterName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

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
                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/class' -f $mockPackageName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/class/counter[@type="{1}"]' -f $mockPackageName, $CounterName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

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
                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/class/method' -f $mockPackageName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/class/method/counter[@type="{1}"]' -f $mockPackageName, $CounterName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

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
                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/sourcefile' -f $mockPackageName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/sourcefile/line[@nr="{1}"]' -f $mockPackageName, $LineNumber

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/sourcefile/counter[@type="{1}"]' -f $mockPackageName, $CounterName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

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

            Context 'When there are just one hit' {
                BeforeAll {
                    $mockHitCommands = [PSCustomObject] @{
                        Class            = 'ResourceBase'
                        Function         = 'Compare'
                        HitCount         = 2
                        SourceFile       = '.\Classes\001.ResourceBase.ps1'
                        SourceLineNumber = 3
                    }

                    $mockMissedCommands = @()

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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/counter[@type="{0}"]' -f $CounterName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

                    switch ($CounterName)
                    {
                        'INSTRUCTION'
                        {
                            $attributes.missed | Should -Be 0
                            $attributes.covered | Should -Be 1
                        }

                        'LINE'
                        {
                            $attributes.missed | Should -Be 0
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
                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package'

                    ($xmlResult | Get-XmlAttribute -XPath $xPath).name | Should -Be $mockPackageName
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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/counter[@type="{1}"]' -f $mockPackageName, $CounterName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

                    switch ($CounterName)
                    {
                        'INSTRUCTION'
                        {
                            $attributes.missed | Should -Be 0
                            $attributes.covered | Should -Be 1
                        }

                        'LINE'
                        {
                            $attributes.missed | Should -Be 0
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
                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/class' -f $mockPackageName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/class/counter[@type="{1}"]' -f $mockPackageName, $CounterName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

                    switch ($CounterName)
                    {
                        'INSTRUCTION'
                        {
                            $attributes.missed | Should -Be 0
                            $attributes.covered | Should -Be 1
                        }

                        'LINE'
                        {
                            $attributes.missed | Should -Be 0
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
                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/class/method' -f $mockPackageName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/class/method/counter[@type="{1}"]' -f $mockPackageName, $CounterName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

                    switch ($CounterName)
                    {
                        'INSTRUCTION'
                        {
                            $attributes.missed | Should -Be 0
                            $attributes.covered | Should -Be 1
                        }

                        'LINE'
                        {
                            $attributes.missed | Should -Be 0
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
                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/sourcefile' -f $mockPackageName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

                    $attributes.name | Should -Be 'Classes/001.ResourceBase.ps1'
                }

                It 'Should have added the source file line <LineNumber> with the correct attributes' {
                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/sourcefile/line[@nr="3"]' -f $mockPackageName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

                    $attributes.mi | Should -Be 0
                    $attributes.ci | Should -Be 1
                    $attributes.mb | Should -Be 0
                    $attributes.cb | Should -Be 0
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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/sourcefile/counter[@type="{1}"]' -f $mockPackageName, $CounterName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

                    switch ($CounterName)
                    {
                        'INSTRUCTION'
                        {
                            $attributes.missed | Should -Be 0
                            $attributes.covered | Should -Be 1
                        }

                        'LINE'
                        {
                            $attributes.missed | Should -Be 0
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

            Context 'When there are just one miss' {
                BeforeAll {
                    $mockHitCommands = @()

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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/counter[@type="{0}"]' -f $CounterName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

                    switch ($CounterName)
                    {
                        'INSTRUCTION'
                        {
                            $attributes.missed | Should -Be 1
                            $attributes.covered | Should -Be 0
                        }

                        'LINE'
                        {
                            $attributes.missed | Should -Be 1
                            $attributes.covered | Should -Be 0
                        }

                        'METHOD'
                        {
                            $attributes.missed | Should -Be 1
                            $attributes.covered | Should -Be 0
                        }

                        'CLASS'
                        {
                            $attributes.missed | Should -Be 1
                            $attributes.covered | Should -Be 0
                        }
                    }
                }

                It 'Should have added one package name with the correct attributes' {
                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package'

                    ($xmlResult | Get-XmlAttribute -XPath $xPath).name | Should -Be $mockPackageName
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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/counter[@type="{1}"]' -f $mockPackageName, $CounterName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

                    switch ($CounterName)
                    {
                        'INSTRUCTION'
                        {
                            $attributes.missed | Should -Be 1
                            $attributes.covered | Should -Be 0
                        }

                        'LINE'
                        {
                            $attributes.missed | Should -Be 1
                            $attributes.covered | Should -Be 0
                        }

                        'METHOD'
                        {
                            $attributes.missed | Should -Be 1
                            $attributes.covered | Should -Be 0
                        }

                        'CLASS'
                        {
                            $attributes.missed | Should -Be 1
                            $attributes.covered | Should -Be 0
                        }
                    }
                }

                It 'Should have added the one class with the correct attributes' {
                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/class' -f $mockPackageName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/class/counter[@type="{1}"]' -f $mockPackageName, $CounterName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

                    switch ($CounterName)
                    {
                        'INSTRUCTION'
                        {
                            $attributes.missed | Should -Be 1
                            $attributes.covered | Should -Be 0
                        }

                        'LINE'
                        {
                            $attributes.missed | Should -Be 1
                            $attributes.covered | Should -Be 0
                        }

                        'METHOD'
                        {
                            $attributes.missed | Should -Be 1
                            $attributes.covered | Should -Be 0
                        }

                        'CLASS'
                        {
                            $attributes.missed | Should -Be 1
                            $attributes.covered | Should -Be 0
                        }
                    }
                }

                It 'Should have added the one method with the correct attributes' {
                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/class/method' -f $mockPackageName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

                    $attributes.name | Should -Be 'Compare'
                    $attributes.desc | Should -Be '()'
                    $attributes.line | Should -Be '4'
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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/class/method/counter[@type="{1}"]' -f $mockPackageName, $CounterName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

                    switch ($CounterName)
                    {
                        'INSTRUCTION'
                        {
                            $attributes.missed | Should -Be 1
                            $attributes.covered | Should -Be 0
                        }

                        'LINE'
                        {
                            $attributes.missed | Should -Be 1
                            $attributes.covered | Should -Be 0
                        }

                        'METHOD'
                        {
                            $attributes.missed | Should -Be 1
                            $attributes.covered | Should -Be 0
                        }
                    }
                }

                It 'Should have added the one source file with the correct attributes' {
                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/sourcefile' -f $mockPackageName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

                    $attributes.name | Should -Be 'Classes/001.ResourceBase.ps1'
                }

                It 'Should have added the source file line <LineNumber> with the correct attributes' {
                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/sourcefile/line[@nr="4"]' -f $mockPackageName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

                    $attributes.mi | Should -Be 1
                    $attributes.ci | Should -Be 0
                    $attributes.mb | Should -Be 0
                    $attributes.cb | Should -Be 0
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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/sourcefile/counter[@type="{1}"]' -f $mockPackageName, $CounterName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

                    switch ($CounterName)
                    {
                        'INSTRUCTION'
                        {
                            $attributes.missed | Should -Be 1
                            $attributes.covered | Should -Be 0
                        }

                        'LINE'
                        {
                            $attributes.missed | Should -Be 1
                            $attributes.covered | Should -Be 0
                        }

                        'METHOD'
                        {
                            $attributes.missed | Should -Be 1
                            $attributes.covered | Should -Be 0
                        }

                        'CLASS'
                        {
                            $attributes.missed | Should -Be 1
                            $attributes.covered | Should -Be 0
                        }
                    }
                }
            }
        }

        Context 'When there are just code at script level' {
            Context 'When there are one hit and one miss' {
                BeforeAll {
                    $mockHitCommands = [PSCustomObject] @{
                        Class            = ''
                        Function         = ''
                        HitCount         = 2
                        SourceFile       = '.\suffix.ps1'
                        SourceLineNumber = 3
                    }

                    $mockMissedCommands = [PSCustomObject] @{
                        Class            = ''
                        Function         = ''
                        HitCount         = 0
                        SourceFile       = '.\suffix.ps1'
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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/counter[@type="{0}"]' -f $CounterName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

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
                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package'

                    ($xmlResult | Get-XmlAttribute -XPath $xPath).name | Should -Be $mockPackageName
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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/counter[@type="{1}"]' -f $mockPackageName, $CounterName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

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

                It 'Should have added the one <script> package with the correct attributes' {
                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/class' -f $mockPackageName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

                    $attributes.name | Should -Be '<script>'
                    $attributes.sourcefilename | Should -Be 'suffix.ps1'
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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/class/counter[@type="{1}"]' -f $mockPackageName, $CounterName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

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
                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/class/method' -f $mockPackageName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

                    $attributes.name | Should -Be '<script>'
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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/class/method/counter[@type="{1}"]' -f $mockPackageName, $CounterName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

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
                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/sourcefile' -f $mockPackageName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

                    $attributes.name | Should -Be 'suffix.ps1'
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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/sourcefile/line[@nr="{1}"]' -f $mockPackageName, $LineNumber

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

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

                    $xmlResult = Sampler\New-JaCoCoDocument -MissedCommands $mockMissedCommands -HitCommands $mockHitCommands -PackageName $mockPackageName

                    $xmlResult | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="{0}"]/sourcefile/counter[@type="{1}"]' -f $mockPackageName, $CounterName

                    $attributes = $xmlResult | Get-XmlAttribute -XPath $xPath

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
    }
}
