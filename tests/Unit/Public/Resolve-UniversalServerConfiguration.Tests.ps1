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

Describe 'Resolve-UniversalServerConfiguration' {
    It 'Should resolve values from the UniversalServer build configuration' {
        $buildInfo = @{
            UniversalServer = @{
                UniversalServerUrl                      = 'https://psu.example.test/'
                UniversalServerAppToken                 = 'token'
                UniversalPSResourceRepositoryName       = 'internal'
                UniversalPSResourceRepositoryUrl        = 'https://packages.example.test'
                UniversalPSResourceRepositoryAutoRemove = $false
                UniversalUnpinned                       = $false
            }
        }

        $configuration = Sampler.PowerShellUniversalTasks\Resolve-UniversalServerConfiguration -BuildInfo $buildInfo -RequireRepository

        $configuration.ServerUrl | Should -Be 'https://psu.example.test'
        $configuration.AppToken | Should -Be 'token'
        $configuration.RepositoryName | Should -Be 'internal'
        $configuration.RepositoryUrl | Should -Be 'https://packages.example.test'
        $configuration.RepositoryAutoRemove | Should -BeFalse
        $configuration.Unpinned | Should -BeFalse
    }

    It 'Should use the default repository when no repository is configured' {
        $configurationParameters = @{
            ServerUrl         = 'https://psu.example.test'
            AppToken          = 'token'
            RequireRepository = $true
        }
        $configuration = Sampler.PowerShellUniversalTasks\Resolve-UniversalServerConfiguration @configurationParameters

        $configuration.RepositoryName | Should -Be 'output'
        $configuration.RepositoryUrl | Should -Be './output/'
    }

    It 'Should reject missing server authentication configuration' {
        {
            Sampler.PowerShellUniversalTasks\Resolve-UniversalServerConfiguration
        } | Should -Throw
    }
}
