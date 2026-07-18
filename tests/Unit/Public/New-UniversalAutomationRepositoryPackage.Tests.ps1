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

Describe 'New-UniversalAutomationRepositoryPackage' {
    BeforeAll {
        Mock -CommandName Test-Path -MockWith { $true }
        Mock -CommandName Test-ModuleManifest -MockWith {
            New-Module -Name 'MyModule' -ScriptBlock { }
        }
        Mock -CommandName Remove-Item
        Mock -CommandName New-Item
        Mock -CommandName Copy-UniversalAutomationRepositoryModule
        Mock -CommandName New-UniversalAutomationRepositoryManifest
        Mock -CommandName Compress-Archive
        Mock -CommandName Get-Item -MockWith {
            [System.IO.FileInfo]::new((Join-Path -Path $TestDrive -ChildPath 'MyModule.1.2.3.zip'))
        }
    }

    It 'Should create the repository package' {
        $packageParameters = @{
            BuiltModuleManifest = (Join-Path -Path $TestDrive -ChildPath 'MyModule.psd1')
            OutputDirectory     = $TestDrive
            ModuleVersion       = '1.2.3'
            Confirm             = $false
        }

        $result = Sampler.PowerShellUniversalTasks\New-UniversalAutomationRepositoryPackage @packageParameters

        $result.Name | Should -Be 'MyModule.1.2.3.zip'
        Should -Invoke -CommandName Copy-UniversalAutomationRepositoryModule -Exactly -Times 1 -Scope It
        Should -Invoke -CommandName New-UniversalAutomationRepositoryManifest -Exactly -Times 1 -Scope It
        Should -Invoke -CommandName Compress-Archive -Exactly -Times 1 -Scope It
    }
}
