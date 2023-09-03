Describe 'Resolve dependencies' {
    BeforeAll {
        $repositoryPath =  Join-Path -Path $PSScriptRoot -ChildPath '../../'
    }

    Context 'When using PowerShellGet' {
        BeforeAll {
            $testTargetPath = Join-Path -Path $TestDrive -ChildPath 'PowerShellGet'

            Copy-Item -Recurse -Path $repositoryPath -Destination $testTargetPath -Force

            Remove-Item -Path (Join-Path -Path $testTargetPath -ChildPath 'output/RequiredModules') -Recurse -Force
        }

        BeforeEach {
            # Must be set here so $Using:PWD works.
            Set-Location -Path $testTargetPath
        }

        It 'Should resolve dependencies without throwing' {
            # Running in separate job so that we do not mess up the current session.
            Start-Job -ScriptBlock {
                Set-Location $using:PWD

                ./build.ps1 -ResolveDependency -Tasks 'noop' 4>&1 5>&1 6>&1 > $null
            } |
                Receive-Job -Wait -AutoRemoveJob -ErrorVariable buildError

            $buildError | Should -BeNullOrEmpty
        }
    }

    # Skip this test on Windows PowerShell as the method is unsupported.
    Context 'When using ModuleFast' -Skip:($PSVersionTable.PSEdition -eq 'Desktop') {
        BeforeAll {
            $testTargetPath = Join-Path -Path $TestDrive -ChildPath 'ModuleFast'

            Copy-Item -Recurse -Path $repositoryPath -Destination $testTargetPath -Force

            # Must keep the folder RequiredModules, but the content must be removed.
            Remove-Item -Path (Join-Path -Path $testTargetPath -ChildPath 'output/RequiredModules/*') -Recurse -Force
        }

        BeforeEach {
            # Must be set here so $Using:PWD works.
            Set-Location -Path $testTargetPath
        }

        It 'Should resolve dependencies without throwing' {
            # Running in separate job so that we do not mess up the current session.
            Start-Job -ScriptBlock {
                Set-Location $using:PWD

                <#
                    Remove the real Sampler output folder paths from PSModulePath so that
                    the command Get-FastModulePlan does not find modules installed.
                #>
                $env:PSModulePath = (
                    $env:PSModulePath -split [System.IO.Path]::PathSeparator |
                        Where-Object -FilterScript {
                            $_ -notlike '*Sampler*'
                        }
                ) -join [System.IO.Path]::PathSeparator

                ./build.ps1 -ResolveDependency -Tasks 'noop' -UseModuleFast 4>&1 5>&1 6>&1 > $null
            } |
                Receive-Job -Wait -AutoRemoveJob -ErrorVariable buildError

            $buildError | Should -BeNullOrEmpty
        }
    }

    Context 'When using PSResourceGet' {
        BeforeAll {
            $testTargetPath = Join-Path -Path $TestDrive -ChildPath 'PSResourceGet'

            Copy-Item -Recurse -Path $repositoryPath -Destination $testTargetPath -Force

            Remove-Item -Path (Join-Path -Path $testTargetPath -ChildPath 'output/RequiredModules') -Recurse -Force
        }

        BeforeEach {
            # Must be set here so $Using:PWD works.
            Set-Location -Path $testTargetPath
        }

        It 'Should resolve dependencies without throwing' {
            # Running in separate job so that we do not mess up the current session.
            Start-Job -ScriptBlock {
                Set-Location $using:PWD

                ./build.ps1 -ResolveDependency -Tasks 'noop' -UsePSResourceGet 4>&1 5>&1 6>&1 > $null
            } |
                Receive-Job -Wait -AutoRemoveJob -ErrorVariable buildError

            $buildError | Should -BeNullOrEmpty
        }
    }
}
