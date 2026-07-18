BeforeAll {
    $script:moduleName = 'Sampler.PowerShellUniversalTasks'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 2)
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

Describe 'Sampler.PowerShellUniversalTasks task exports' {
    It 'Should export the PowerShell Universal task file alias' {
        $module = Get-Module -Name $script:moduleName
        $alias = $module.ExportedAliases['Task.Publish_PowerShellUniversal']

        $alias | Should -Not -BeNullOrEmpty
        $alias.ResolvedCommand.Path | Should -Match 'Tasks[\\/]Publish\.PowerShellUniversal\.build\.ps1$'
    }

    It 'Should ship the task file in the Tasks directory' {
        $module = Get-Module -Name $script:moduleName
        $taskPath = Join-Path -Path $module.ModuleBase -ChildPath 'Tasks'
        $taskFilePath = Join-Path -Path $taskPath -ChildPath 'Publish.PowerShellUniversal.build.ps1'

        $taskFilePath | Should -Exist
    }
}
