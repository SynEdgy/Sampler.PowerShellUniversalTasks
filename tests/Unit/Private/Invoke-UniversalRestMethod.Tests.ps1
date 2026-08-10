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

Describe 'Invoke-UniversalRestMethod' {
    BeforeAll {
        Mock -CommandName Invoke-RestMethod -MockWith {
            [PSCustomObject]@{ name = 'response' }
        }
    }

    It 'Should invoke Invoke-RestMethod without a certificate bypass by default' {
        InModuleScope -Parameters @{ RequestParameters = @{ Uri = 'https://psu.example.test' } } -ScriptBlock {
            param
            (
                $RequestParameters
            )

            $result = Invoke-UniversalRestMethod -RestMethodParameters $RequestParameters

            $result.name | Should -Be 'response'
        }

        Should -Invoke -CommandName Invoke-RestMethod -Exactly -Times 1 -Scope It -ParameterFilter {
            -not $PSBoundParameters.ContainsKey('SkipCertificateCheck')
        }
    }

    It 'Should pass -SkipCertificateCheck to Invoke-RestMethod on PowerShell 6 and above' -Skip:($PSVersionTable.PSVersion.Major -lt 6) {
        InModuleScope -Parameters @{ RequestParameters = @{ Uri = 'https://psu.example.test' } } -ScriptBlock {
            param
            (
                $RequestParameters
            )

            $null = Invoke-UniversalRestMethod -RestMethodParameters $RequestParameters -SkipCertificateCheck $true
        }

        Should -Invoke -CommandName Invoke-RestMethod -Exactly -Times 1 -Scope It -ParameterFilter {
            $SkipCertificateCheck -eq $true
        }
    }

    It 'Should temporarily bypass certificate validation on Windows PowerShell' -Skip:($PSVersionTable.PSVersion.Major -ge 6) {
        InModuleScope -Parameters @{ RequestParameters = @{ Uri = 'https://psu.example.test' } } -ScriptBlock {
            param
            (
                $RequestParameters
            )

            $originalCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback

            $null = Invoke-UniversalRestMethod -RestMethodParameters $RequestParameters -SkipCertificateCheck $true

            [System.Net.ServicePointManager]::ServerCertificateValidationCallback | Should -Be $originalCallback
        }
    }
}
