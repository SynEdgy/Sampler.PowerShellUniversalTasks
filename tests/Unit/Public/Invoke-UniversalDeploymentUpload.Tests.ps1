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

Describe 'Invoke-UniversalDeploymentUpload' {
    BeforeAll {
        Mock -CommandName Test-Path -MockWith { $true }
        Mock -CommandName Invoke-RestMethod -MockWith {
            [PSCustomObject]@{ name = 'deployment' }
        }
    }

    It 'Should upload the package with bearer authentication' {
        $uploadParameters = @{
            Uri      = 'https://psu.example.test/api/v1/deployment'
            AppToken = 'token'
            Path     = (Join-Path -Path $TestDrive -ChildPath 'package.zip')
        }
        $result = Sampler.PowerShellUniversalTasks\Invoke-UniversalDeploymentUpload @uploadParameters

        $result.name | Should -Be 'deployment'
        Should -Invoke -CommandName Invoke-RestMethod -Exactly -Times 1 -Scope It -ParameterFilter {
            $Method -eq 'Put' -and
            $Headers.Authorization -eq 'Bearer token'
        }
    }

    It 'Should reject a missing deployment package' {
        Mock -CommandName Test-Path -MockWith { $false }
        $uploadParameters = @{
            Uri      = 'https://psu.example.test/api/v1/deployment'
            AppToken = 'token'
            Path     = (Join-Path -Path $TestDrive -ChildPath 'missing.zip')
        }

        {
            Sampler.PowerShellUniversalTasks\Invoke-UniversalDeploymentUpload @uploadParameters
        } | Should -Throw
    }
}
