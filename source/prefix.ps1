<#
    Defines aliases used by InvokeBuild task discovery. These aliases point to
    task files shipped in the built module's Tasks directory and do not depend
    on functions declared later in the merged root module.
#>

$taskPath = Join-Path -Path $PSScriptRoot -ChildPath 'Tasks'
$taskPath = Join-Path -Path $taskPath -ChildPath 'Publish.PowerShellUniversal.build.ps1'
Set-Alias -Name 'Task.Publish_PowerShellUniversal' -Value $taskPath
