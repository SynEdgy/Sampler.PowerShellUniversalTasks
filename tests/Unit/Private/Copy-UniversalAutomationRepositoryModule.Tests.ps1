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

Describe 'Copy-UniversalAutomationRepositoryModule' {
    BeforeAll {
        Mock -CommandName New-Item
        Mock -CommandName Copy-Item
        Mock -CommandName Test-Path -MockWith { $false }
    }

    It 'Should copy the module into its versioned repository directory' {
        InModuleScope -ScriptBlock {
            $module = New-Module -Name 'MyModule' -ScriptBlock { }

            Copy-UniversalAutomationRepositoryModule -Module $module -ModulesDestinationPath $Destination -Visited @{ }
        } -Parameters @{ Destination = $TestDrive }

        Should -Invoke -CommandName Copy-Item -Exactly -Times 1 -Scope It
    }
}
