<#
    .SYNOPSIS
        Defines the exported alias for the PowerShell Universal InvokeBuild task file.

    .DESCRIPTION
        Creates the Task.Publish_PowerShellUniversal alias used by InvokeBuild task
        discovery to load the PowerShell Universal tasks shipped with this module.

    .EXAMPLE
        Get-Alias -Name 'Task.Publish_PowerShellUniversal'
#>

$taskPath = Join-Path -Path $PSScriptRoot -ChildPath 'Tasks'
$taskPath = Join-Path -Path $taskPath -ChildPath 'Publish.PowerShellUniversal.build.ps1'
Set-Alias -Name 'Task.Publish_PowerShellUniversal' -Value $taskPath
