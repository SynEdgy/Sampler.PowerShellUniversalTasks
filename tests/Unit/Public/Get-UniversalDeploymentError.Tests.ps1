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

Describe 'Get-UniversalDeploymentError' {
    It 'Should return deployment errors created after the specified time' {
        $since = [System.DateTimeOffset]::UtcNow.AddMinutes(-1)
        Mock -CommandName Invoke-RestMethod -MockWith {
            [PSCustomObject]@{
                page = @(
                    [PSCustomObject]@{
                        CreatedTime = [System.DateTimeOffset]::UtcNow.ToString('O')
                        Level       = 'Error'
                        Title       = 'Deployment error'
                        Description = 'Module deployment failed.'
                    }
                    [PSCustomObject]@{
                        CreatedTime = [System.DateTimeOffset]::UtcNow.ToString('O')
                        Level       = 'Information'
                        Title       = 'Deployment completed'
                        Description = 'Module installed.'
                    }
                )
            }
        }

        $parameters = @{
            ServerUrl = 'https://psu.example.test'
            AppToken  = 'token'
            Since     = $since
        }
        $result = @(Sampler.PowerShellUniversalTasks\Get-UniversalDeploymentError @parameters)

        $result.Count | Should -Be 1
        $result[0].Title | Should -Be 'Deployment error'
        Should -Invoke -CommandName Invoke-RestMethod -Exactly -Times 1 -Scope It -ParameterFilter {
            $Uri -eq 'https://psu.example.test/api/v1/notification/last' -and
            $Headers.Authorization -eq 'Bearer token' -and
            $Method -eq 'Get'
        }
    }

    It 'Should ignore deployment errors created before the specified time' {
        Mock -CommandName Invoke-RestMethod -MockWith {
            [PSCustomObject]@{
                page = @(
                    [PSCustomObject]@{
                        CreatedTime = [System.DateTimeOffset]::UtcNow.AddMinutes(-10).ToString('O')
                        Level       = 'Error'
                        Title       = 'Deployment error'
                        Description = 'Old deployment failed.'
                    }
                )
            }
        }

        $parameters = @{
            ServerUrl = 'https://psu.example.test'
            AppToken  = 'token'
            Since     = [System.DateTimeOffset]::UtcNow.AddMinutes(-1)
        }
        $result = @(Sampler.PowerShellUniversalTasks\Get-UniversalDeploymentError @parameters)

        $result.Count | Should -Be 0
    }

    It 'Should apply the optional notification text filter' {
        Mock -CommandName Invoke-RestMethod -MockWith {
            [PSCustomObject]@{
                page = @(
                    [PSCustomObject]@{
                        CreatedTime = [System.DateTimeOffset]::UtcNow.ToString('O')
                        Level       = 'Error'
                        Title       = 'Deployment error'
                        Description = 'MyModule failed to load.'
                    }
                    [PSCustomObject]@{
                        CreatedTime = [System.DateTimeOffset]::UtcNow.ToString('O')
                        Level       = 'Error'
                        Title       = 'Deployment error'
                        Description = 'OtherModule failed to load.'
                    }
                )
            }
        }

        $parameters = @{
            ServerUrl  = 'https://psu.example.test'
            AppToken   = 'token'
            Since      = [System.DateTimeOffset]::UtcNow.AddMinutes(-1)
            FilterText = 'MyModule'
        }
        $result = @(Sampler.PowerShellUniversalTasks\Get-UniversalDeploymentError @parameters)

        $result.Count | Should -Be 1
        $result[0].Description | Should -Match 'MyModule'
    }
}
