BeforeAll {
    $script:moduleName = 'Sampler.PowerShellUniversalTasks'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 2)
        & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

Describe 'Copy-UniversalRepositoryModule' {
    BeforeAll {
        Mock -CommandName New-Item
        Mock -CommandName Copy-Item
        Mock -CommandName Test-Path -MockWith { $false }
    }

    It 'Should copy the module into its versioned repository directory' {
        InModuleScope -ScriptBlock {
            $module = New-Module -Name 'MyModule' -ScriptBlock { }

            Copy-UniversalRepositoryModule -Module $module -ModulesDestinationPath $Destination -Visited @{ }
        } -Parameters @{ Destination = $TestDrive }

        Should -Invoke -CommandName Copy-Item -Exactly -Times 1 -Scope It
    }

    It 'Should process transitive dependencies with a queue and avoid cycles' {
        Mock -CommandName Test-Path -MockWith { $true }
        Mock -CommandName Get-SamplerModuleInfo -MockWith {
            if ($ModuleManifestPath -match 'RootModule')
            {
                return [PSCustomObject]@{
                    RequiredModules = @(
                        @{
                            ModuleName    = 'DependencyModule'
                            ModuleVersion = '1.0.0'
                        }
                    )
                }
            }

            [PSCustomObject]@{
                RequiredModules = @('RootModule')
            }
        }
        Mock -CommandName Get-Module -ParameterFilter {
            $ListAvailable -and $FullyQualifiedName.Name -eq 'DependencyModule'
        } -MockWith {
            New-Module -Name 'DependencyModule' -ScriptBlock { }
        }

        InModuleScope -ScriptBlock {
            $module = New-Module -Name 'RootModule' -ScriptBlock { }

            Copy-UniversalRepositoryModule -Module $module -ModulesDestinationPath $Destination -Visited @{ }
        } -Parameters @{ Destination = $TestDrive }

        Should -Invoke -CommandName Copy-Item -Exactly -Times 2 -Scope It
        Should -Invoke -CommandName Get-Module -Exactly -Times 1 -Scope It
        Should -Invoke -CommandName Get-SamplerModuleInfo -Exactly -Times 2 -Scope It
    }

    It 'Should copy only the highest resolved version when a dependency is required more than once' {
        $fixtureRoot = Join-Path -Path $TestDrive -ChildPath 'modules'
        $rootModulePath = Join-Path -Path $fixtureRoot -ChildPath 'RootModule'
        $branchModulePath = Join-Path -Path $fixtureRoot -ChildPath 'BranchModule'
        $sharedV1Path = Join-Path -Path $fixtureRoot -ChildPath 'SharedModuleV1'
        $sharedV2Path = Join-Path -Path $fixtureRoot -ChildPath 'SharedModuleV2'

        foreach ($moduleFixture in @(
                @{ Name = 'RootModule'; Path = $rootModulePath; Version = '1.0.0' }
                @{ Name = 'BranchModule'; Path = $branchModulePath; Version = '1.0.0' }
                @{ Name = 'SharedModule'; Path = $sharedV1Path; Version = '1.0.0' }
                @{ Name = 'SharedModule'; Path = $sharedV2Path; Version = '2.0.0' }
            ))
        {
            $null = New-Item -Path $moduleFixture.Path -ItemType Directory -Force
            $moduleScriptPath = Join-Path -Path $moduleFixture.Path -ChildPath ('{0}.psm1' -f $moduleFixture.Name)
            Set-Content -Path $moduleScriptPath -Value ''
            $manifestPath = Join-Path -Path $moduleFixture.Path -ChildPath ('{0}.psd1' -f $moduleFixture.Name)
            $manifestParameters = @{
                Path          = $manifestPath
                RootModule    = ('{0}.psm1' -f $moduleFixture.Name)
                ModuleVersion = $moduleFixture.Version
            }
            New-ModuleManifest @manifestParameters
        }

        $rootModule = Test-ModuleManifest -Path (Join-Path -Path $rootModulePath -ChildPath 'RootModule.psd1')
        $branchModule = Test-ModuleManifest -Path (Join-Path -Path $branchModulePath -ChildPath 'BranchModule.psd1')
        $sharedV1 = Test-ModuleManifest -Path (Join-Path -Path $sharedV1Path -ChildPath 'SharedModule.psd1')
        $sharedV2 = Test-ModuleManifest -Path (Join-Path -Path $sharedV2Path -ChildPath 'SharedModule.psd1')

        Mock -CommandName Test-Path -MockWith { $true }
        Mock -CommandName Get-SamplerModuleInfo -MockWith {
            if ($ModuleManifestPath -match 'RootModule')
            {
                return [PSCustomObject]@{
                    RequiredModules = @(
                        @{ ModuleName = 'BranchModule'; RequiredVersion = '1.0.0' }
                        @{ ModuleName = 'SharedModule'; RequiredVersion = '1.0.0' }
                    )
                }
            }

            if ($ModuleManifestPath -match 'BranchModule')
            {
                return [PSCustomObject]@{
                    RequiredModules = @(
                        @{ ModuleName = 'SharedModule'; RequiredVersion = '2.0.0' }
                    )
                }
            }

            [PSCustomObject]@{ RequiredModules = @() }
        }
        Mock -CommandName Get-Module -MockWith {
            if ($FullyQualifiedName.Name -eq 'BranchModule')
            {
                return $branchModule
            }

            if ($FullyQualifiedName.RequiredVersion -eq [System.Version] '2.0.0')
            {
                return $sharedV2
            }

            $sharedV1
        }

        InModuleScope -ScriptBlock {
            Copy-UniversalRepositoryModule -Module $RootModule -ModulesDestinationPath $Destination -Visited @{ }
        } -Parameters @{
            RootModule  = $rootModule
            Destination = $TestDrive
        }

        $expectedSharedDestination = Join-Path -Path $TestDrive -ChildPath 'SharedModule'
        $expectedSharedDestination = Join-Path -Path $expectedSharedDestination -ChildPath '2.0.0'

        Should -Invoke -CommandName Copy-Item -Exactly -Times 3 -Scope It
        Should -Invoke -CommandName Copy-Item -Exactly -Times 1 -Scope It -ParameterFilter {
            $Destination -eq $expectedSharedDestination
        }
    }
}
