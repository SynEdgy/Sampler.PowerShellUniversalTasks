function Copy-UniversalAutomationRepositoryModule
{
    <#
        .SYNOPSIS
            Copies a module and its dependencies into a PSU repository layout.

        .DESCRIPTION
            Recursively copies a module and each RequiredModules dependency into
            versioned folders below the automation repository Modules directory.

        .PARAMETER Module
            Module information for the module that is copied.

        .PARAMETER ModulesDestinationPath
            Destination Modules directory in the staged repository.

        .PARAMETER Visited
            Hashtable used to prevent duplicate copies and dependency cycles.

        .EXAMPLE
            Copy-UniversalAutomationRepositoryModule -Module $module -ModulesDestinationPath $path -Visited @{}
    #>
    [CmdletBinding()]
    [OutputType([System.Void])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSModuleInfo]
        $Module,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ModulesDestinationPath,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Visited
    )

    if ($Visited.ContainsKey($Module.Name))
    {
        return
    }

    $Visited[$Module.Name] = $true
    $moduleDestination = Join-Path -Path $ModulesDestinationPath -ChildPath $Module.Name
    $moduleDestination = Join-Path -Path $moduleDestination -ChildPath $Module.Version.ToString()

    $null = New-Item -Path $moduleDestination -ItemType Directory -Force
    Copy-Item -Path (Join-Path -Path $Module.ModuleBase -ChildPath '*') -Destination $moduleDestination -Recurse -Force

    $manifestPath = Join-Path -Path $Module.ModuleBase -ChildPath ('{0}.psd1' -f $Module.Name)
    if (-not (Test-Path -Path $manifestPath))
    {
        return
    }

    $moduleInfo = Get-SamplerModuleInfo -ModuleManifestPath $manifestPath
    foreach ($requiredModule in @($moduleInfo.RequiredModules))
    {
        if (-not $requiredModule)
        {
            continue
        }

        $moduleSpecification = [Microsoft.PowerShell.Commands.ModuleSpecification] $requiredModule
        $resolvedModule = Get-Module -ListAvailable -FullyQualifiedName $moduleSpecification |
            Sort-Object -Property Version -Descending |
            Select-Object -First 1

        if (-not $resolvedModule)
        {
            throw "Required module '$($moduleSpecification.Name)' for '$($Module.Name)' was not found on PSModulePath."
        }

        Copy-UniversalAutomationRepositoryModule -Module $resolvedModule -ModulesDestinationPath $ModulesDestinationPath -Visited $Visited
    }
}
