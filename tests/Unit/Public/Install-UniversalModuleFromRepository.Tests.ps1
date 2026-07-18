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

Describe 'Install-UniversalModuleFromRepository' {
    BeforeAll {
        Mock -CommandName Invoke-RestMethod -MockWith {
            if ($Method -eq 'Get')
            {
                return @()
            }
        }
    }

    It 'Should create deploy and remove the repository' {
        $installParameters = @{
            ServerUrl            = 'https://psu.example.test'
            AppToken             = 'token'
            ModuleName           = 'MyModule'
            ModuleVersion        = '1.2.3'
            RepositoryName       = 'internal'
            RepositoryUrl        = 'https://packages.example.test'
            RepositoryAutoRemove = $true
        }

        {
            Sampler.PowerShellUniversalTasks\Install-UniversalModuleFromRepository @installParameters
        } | Should -Not -Throw

        Should -Invoke -CommandName Invoke-RestMethod -Exactly -Times 1 -Scope It -ParameterFilter { $Method -eq 'Post' }
        Should -Invoke -CommandName Invoke-RestMethod -Exactly -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' }
        Should -Invoke -CommandName Invoke-RestMethod -Exactly -Times 1 -Scope It -ParameterFilter { $Method -eq 'Delete' }
    }
}
