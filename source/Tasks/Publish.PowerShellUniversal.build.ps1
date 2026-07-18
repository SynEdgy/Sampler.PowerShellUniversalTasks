param
(
    [Parameter()]
    [System.String]
    $OutputDirectory = (property OutputDirectory (Join-Path -Path $BuildRoot -ChildPath 'output')),

    [Parameter()]
    [System.String]
    $UniversalServerUrl = (property UniversalServerUrl ''),

    [Parameter()]
    [System.String]
    $UniversalServerAppToken = (property UniversalServerAppToken ''),

    [Parameter()]
    [System.String]
    $UniversalPSResourceRepositoryName = (property UniversalPSResourceRepositoryName ''),

    [Parameter()]
    [System.String]
    $UniversalPSResourceRepositoryUrl = (property UniversalPSResourceRepositoryUrl ''),

    [Parameter()]
    [System.Boolean]
    $UniversalPSResourceRepositoryAutoRemove = (property UniversalPSResourceRepositoryAutoRemove $true),

    [Parameter()]
    [System.String]
    $UniversalRepositoryStagingDirectoryName = (property UniversalRepositoryStagingDirectoryName 'PsuRepository'),

    [Parameter()]
    [System.String]
    $UniversalRepositoryZipName = (property UniversalRepositoryZipName ''),

    [Parameter()]
    [System.Boolean]
    $UniversalRepositoryAsModule = (property UniversalRepositoryAsModule $false),

    [Parameter()]
    [System.Boolean]
    $UniversalUnpinned = (property UniversalUnpinned $true),

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

$TaskParameterNames = @($PSBoundParameters.Keys)

# Synopsis: Upload the packed module directly to the PowerShell Universal deployment endpoint.
task publish_packed_module_to_universal_server {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.
    . Set-SamplerTaskVariable
    $secretsPath = Join-Path -Path $BuildRoot -ChildPath 'secrets.local.ps1'
    if (Test-Path -Path $secretsPath)
    {
        . $secretsPath
    }

    $configurationParameters = @{
        BuildInfo                    = $BuildInfo
        ServerUrl                    = $UniversalServerUrl
        AppToken                     = $UniversalServerAppToken
        RepositoryName               = $UniversalPSResourceRepositoryName
        RepositoryUrl                = $UniversalPSResourceRepositoryUrl
        RepositoryAutoRemove         = $UniversalPSResourceRepositoryAutoRemove
        Unpinned                     = $UniversalUnpinned
        RepositoryAutoRemoveWasBound = 'UniversalPSResourceRepositoryAutoRemove' -in $TaskParameterNames
        UnpinnedWasBound             = 'UniversalUnpinned' -in $TaskParameterNames
    }
    $configuration = Sampler.PowerShellUniversalTasks\Resolve-UniversalServerConfiguration @configurationParameters
    $packagePath = Join-Path -Path $OutputDirectory -ChildPath ('{0}.{1}.nupkg' -f $ProjectName, $ModuleVersion)
    $endpoint = '{0}/api/v1/deployment/module/{1}/{2}?repository=output&synchronous=true' -f @(
        $configuration.ServerUrl
        $ProjectName
        $ModuleVersion
    )

    $null = Sampler.PowerShellUniversalTasks\Invoke-UniversalDeploymentUpload -Uri $endpoint -AppToken $configuration.AppToken -Path $packagePath
    Write-Build -Color Green -Text ("Published module '{0}' version '{1}' to PowerShell Universal." -f $ProjectName, $ModuleVersion)
}

# Synopsis: Reconcile a PowerShell resource repository on the server and install the built module from it.
task publish_module_from_psresource_repos_to_universal_server {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.
    . Set-SamplerTaskVariable
    $secretsPath = Join-Path -Path $BuildRoot -ChildPath 'secrets.local.ps1'
    if (Test-Path -Path $secretsPath)
    {
        . $secretsPath
    }

    $configurationParameters = @{
        BuildInfo                    = $BuildInfo
        ServerUrl                    = $UniversalServerUrl
        AppToken                     = $UniversalServerAppToken
        RepositoryName               = $UniversalPSResourceRepositoryName
        RepositoryUrl                = $UniversalPSResourceRepositoryUrl
        RepositoryAutoRemove         = $UniversalPSResourceRepositoryAutoRemove
        Unpinned                     = $UniversalUnpinned
        RepositoryAutoRemoveWasBound = 'UniversalPSResourceRepositoryAutoRemove' -in $TaskParameterNames
        UnpinnedWasBound             = 'UniversalUnpinned' -in $TaskParameterNames
        RequireRepository            = $true
    }
    $configuration = Sampler.PowerShellUniversalTasks\Resolve-UniversalServerConfiguration @configurationParameters
    $repositoryUrl = $configuration.RepositoryUrl
    if ($repositoryUrl -notmatch '^[a-z][a-z0-9+.-]*://')
    {
        $repositoryUrl = Get-SamplerAbsolutePath -Path $repositoryUrl -RelativeTo $BuildRoot
        $null = New-Item -Path $repositoryUrl -ItemType Directory -Force
    }

    $installParameters = @{
        ServerUrl             = $configuration.ServerUrl
        AppToken              = $configuration.AppToken
        ModuleName            = $ProjectName
        ModuleVersion         = $ModuleVersion
        RepositoryName        = $configuration.RepositoryName
        RepositoryUrl         = $repositoryUrl
        RepositoryAutoRemove  = $configuration.RepositoryAutoRemove
    }

    Sampler.PowerShellUniversalTasks\Install-UniversalModuleFromRepository @installParameters
    Write-Build -Color Green -Text ("Installed module '{0}' version '{1}' from repository '{2}'." -f $ProjectName, $ModuleVersion, $configuration.RepositoryName)
}

# Synopsis: Package the built module and its dependencies as an offline PowerShell Universal automation repository.
task package_universal_automation_repository {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.
    . Set-SamplerTaskVariable

    if (-not $BuiltModuleManifest)
    {
        throw "No valid manifest found for project '$ProjectName'. Run the build task first."
    }

    $packageParameters = @{
        BuiltModuleManifest  = $BuiltModuleManifest
        OutputDirectory      = $OutputDirectory
        ModuleVersion        = $ModuleVersion
        StagingDirectoryName = $UniversalRepositoryStagingDirectoryName
        ZipName              = $UniversalRepositoryZipName
    }

    $package = Sampler.PowerShellUniversalTasks\New-UniversalAutomationRepositoryPackage @packageParameters -Confirm:$false
    Write-Build -Color Green -Text ("Packaged the PowerShell Universal automation repository at '{0}'." -f $package.FullName)
}

# Synopsis: Upload an offline automation repository package to the PowerShell Universal deployment endpoint.
task publish_universal_automation_repository_to_server {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.
    . Set-SamplerTaskVariable
    $secretsPath = Join-Path -Path $BuildRoot -ChildPath 'secrets.local.ps1'
    if (Test-Path -Path $secretsPath)
    {
        . $secretsPath
    }

    $configurationParameters = @{
        BuildInfo                    = $BuildInfo
        ServerUrl                    = $UniversalServerUrl
        AppToken                     = $UniversalServerAppToken
        RepositoryName               = $UniversalPSResourceRepositoryName
        RepositoryUrl                = $UniversalPSResourceRepositoryUrl
        RepositoryAutoRemove         = $UniversalPSResourceRepositoryAutoRemove
        Unpinned                     = $UniversalUnpinned
        RepositoryAutoRemoveWasBound = 'UniversalPSResourceRepositoryAutoRemove' -in $TaskParameterNames
        UnpinnedWasBound             = 'UniversalUnpinned' -in $TaskParameterNames
    }
    $configuration = Sampler.PowerShellUniversalTasks\Resolve-UniversalServerConfiguration @configurationParameters
    $zipName = if ([System.String]::IsNullOrWhiteSpace($UniversalRepositoryZipName))
    {
        '{0}.{1}.zip' -f $ProjectName, $ModuleVersion
    }
    else
    {
        $UniversalRepositoryZipName
    }
    $packagePath = Join-Path -Path $OutputDirectory -ChildPath $zipName
    $endpoint = '{0}/api/v1/deployment?asModule={1}&unpinned={2}' -f @(
        $configuration.ServerUrl
        $UniversalRepositoryAsModule.ToString().ToLowerInvariant()
        $configuration.Unpinned.ToString().ToLowerInvariant()
    )

    $deployment = Sampler.PowerShellUniversalTasks\Invoke-UniversalDeploymentUpload -Uri $endpoint -AppToken $configuration.AppToken -Path $packagePath
    Write-Build -Color Green -Text ("Deployed automation repository '{0}' version '{1}'." -f $deployment.name, $deployment.version)
}
