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

Describe 'New-UniversalAutomationRepositoryManifest' {
    It 'Should create the repository descriptor for the module' {
        $manifestPath = Join-Path -Path $TestDrive -ChildPath 'MyModule.psd1'

        InModuleScope -ScriptBlock {
            $module = New-Module -Name 'MyModule' -ScriptBlock { }

            New-UniversalAutomationRepositoryManifest -Path $ManifestPath -Module $module -ModuleVersion '1.2.3-preview1' -Confirm:$false
        } -Parameters @{ ManifestPath = $manifestPath }

        $manifest = Import-PowerShellDataFile -Path $manifestPath
        $manifest.RootModule | Should -Be 'MyModule'
        $manifest.ModuleVersion.ToString() | Should -Be '1.2.3'
        $manifest.PrivateData | Should -BeOfType [System.Collections.Hashtable]
        $manifest.PrivateData.PSData | Should -BeOfType [System.Collections.Hashtable]
        $manifest.PrivateData.PSData.Prerelease | Should -Be 'preview1'
        Get-Content -Path $manifestPath -Raw | Should -Not -Match "PSData\s*=\s*'System.Collections.Hashtable'"
    }

    It 'Should create the repository descriptor without a prerelease tag when the version has none' {
        $manifestPath = Join-Path -Path $TestDrive -ChildPath 'MyModule.psd1'

        InModuleScope -ScriptBlock {
            $module = New-Module -Name 'MyModule' -ScriptBlock { }

            New-UniversalAutomationRepositoryManifest -Path $ManifestPath -Module $module -ModuleVersion '1.2.3' -Confirm:$false
        } -Parameters @{ ManifestPath = $manifestPath }

        $manifest = Import-PowerShellDataFile -Path $manifestPath
        $manifest.RootModule | Should -Be 'MyModule'
        $manifest.ModuleVersion.ToString() | Should -Be '1.2.3'
        $manifest.ContainsKey('PrivateData') | Should -BeFalse
    }
}
