function Copy-UniversalRepositoryModule
{
    <#
        .SYNOPSIS
            Copies a module and its dependencies into a PSU repository layout.

        .DESCRIPTION
            Uses a queue to copy a module and each transitive RequiredModules
            dependency into versioned folders below the repository Modules directory.
            First-discovery order is preserved, and a selected module is replaced
            only when a later requirement resolves to a higher version.

        .PARAMETER Module
            Module information for the module that is copied.

        .PARAMETER ModulesDestinationPath
            Destination Modules directory in the staged repository.

        .PARAMETER Visited
            Hashtable used to prevent duplicate copies and dependency cycles.

        .EXAMPLE
            Copy-UniversalRepositoryModule -Module $module -ModulesDestinationPath $path -Visited @{}
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

    $moduleQueue = [System.Collections.Queue]::new()
    $selectedModules = @{ }
    $moduleDiscoveryOrder = [System.Collections.ArrayList]::new()
    $inspectedModuleVersions = @{ }
    $moduleQueue.Enqueue($Module)

    while ($moduleQueue.Count -gt 0)
    {
        $currentModule = [System.Management.Automation.PSModuleInfo] $moduleQueue.Dequeue()
        $moduleVersionKey = '{0}|{1}' -f $currentModule.Name, $currentModule.Version
        if ($inspectedModuleVersions.ContainsKey($moduleVersionKey))
        {
            continue
        }

        $inspectedModuleVersions[$moduleVersionKey] = $true
        if (-not $selectedModules.ContainsKey($currentModule.Name))
        {
            $selectedModules[$currentModule.Name] = $currentModule
            $null = $moduleDiscoveryOrder.Add($currentModule.Name)
        }
        elseif ($currentModule.Version -gt $selectedModules[$currentModule.Name].Version)
        {
            $selectedModules[$currentModule.Name] = $currentModule
        }

        $manifestPath = Join-Path -Path $currentModule.ModuleBase -ChildPath ('{0}.psd1' -f $currentModule.Name)
        if (-not (Test-Path -Path $manifestPath))
        {
            continue
        }

        $moduleInfo = Get-SamplerModuleInfo -ModuleManifestPath $manifestPath
        foreach ($requiredModule in @($moduleInfo.RequiredModules))
        {
            if (-not $requiredModule)
            {
                continue
            }

            $moduleSpecification = [Microsoft.PowerShell.Commands.ModuleSpecification] $requiredModule
            if ($selectedModules.ContainsKey($moduleSpecification.Name))
            {
                $requiredVersion = $moduleSpecification.RequiredVersion
                if (-not $requiredVersion)
                {
                    $requiredVersion = $moduleSpecification.Version
                }

                if (-not $requiredVersion -or
                    $selectedModules[$moduleSpecification.Name].Version -ge $requiredVersion)
                {
                    continue
                }
            }

            $resolvedModule = Get-Module -ListAvailable -FullyQualifiedName $moduleSpecification |
                Sort-Object -Property Version -Descending |
                Select-Object -First 1

            if (-not $resolvedModule)
            {
                throw "Required module '$($moduleSpecification.Name)' for '$($currentModule.Name)' was not found on PSModulePath."
            }

            $moduleQueue.Enqueue($resolvedModule)
        }
    }

    foreach ($selectedModuleName in $moduleDiscoveryOrder)
    {
        $selectedModule = [System.Management.Automation.PSModuleInfo] $selectedModules[$selectedModuleName]
        $Visited[$selectedModule.Name] = $true
        $moduleDestination = Join-Path -Path $ModulesDestinationPath -ChildPath $selectedModule.Name
        $moduleDestination = Join-Path -Path $moduleDestination -ChildPath $selectedModule.Version.ToString()

        $null = New-Item -Path $moduleDestination -ItemType Directory -Force
        Copy-Item -Path (Join-Path -Path $selectedModule.ModuleBase -ChildPath '*') -Destination $moduleDestination -Recurse -Force
    }
}
