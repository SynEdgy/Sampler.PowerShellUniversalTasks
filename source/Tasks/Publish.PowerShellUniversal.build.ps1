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
    [System.Boolean]
    $UniversalSkipCertificateCheck = (property UniversalSkipCertificateCheck $false),

    [Parameter()]
    [ValidateRange(0, 300)]
    [System.Int32]
    $UniversalDeploymentNotificationDelaySeconds = (property UniversalDeploymentNotificationDelaySeconds 2),

    [Parameter()]
    [ValidateRange(1, 3600)]
    [System.Int32]
    $UniversalDeploymentNotificationLookbackSeconds = (property UniversalDeploymentNotificationLookbackSeconds 120),

    [Parameter()]
    [System.String]
    $UniversalDeploymentNotificationFilter = (property UniversalDeploymentNotificationFilter ''),

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
        SkipCertificateCheck         = $UniversalSkipCertificateCheck
        SkipCertificateCheckWasBound = 'UniversalSkipCertificateCheck' -in $TaskParameterNames
    }
    $configuration = Sampler.PowerShellUniversalTasks\Resolve-UniversalServerConfiguration @configurationParameters
    $packagePath = Join-Path -Path $OutputDirectory -ChildPath ('{0}.{1}.nupkg' -f $ProjectName, $ModuleVersion)
    $endpoint = '{0}/api/v1/deployment/module/{1}/{2}?repository=output&synchronous=true' -f @(
        $configuration.ServerUrl
        $ProjectName
        $ModuleVersion
    )

    $script:UniversalDeploymentStartedAt = [System.DateTimeOffset]::UtcNow
    $null = Sampler.PowerShellUniversalTasks\Invoke-UniversalDeploymentUpload -Uri $endpoint -AppToken $configuration.AppToken -Path $packagePath -SkipCertificateCheck $configuration.SkipCertificateCheck
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
        SkipCertificateCheck         = $UniversalSkipCertificateCheck
        SkipCertificateCheckWasBound = 'UniversalSkipCertificateCheck' -in $TaskParameterNames
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
        SkipCertificateCheck  = $configuration.SkipCertificateCheck
    }

    $script:UniversalDeploymentStartedAt = [System.DateTimeOffset]::UtcNow
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
        SkipCertificateCheck         = $UniversalSkipCertificateCheck
        SkipCertificateCheckWasBound = 'UniversalSkipCertificateCheck' -in $TaskParameterNames
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

    $script:UniversalDeploymentStartedAt = [System.DateTimeOffset]::UtcNow
    $deployment = Sampler.PowerShellUniversalTasks\Invoke-UniversalDeploymentUpload -Uri $endpoint -AppToken $configuration.AppToken -Path $packagePath -SkipCertificateCheck $configuration.SkipCertificateCheck
    Write-Build -Color Green -Text ("Deployed automation repository '{0}' version '{1}'." -f $deployment.name, $deployment.version)
}

# Synopsis: Fail the build when PowerShell Universal reports a deployment error notification.
task assert_universal_deployment_succeeded {
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
        SkipCertificateCheck         = $UniversalSkipCertificateCheck
        SkipCertificateCheckWasBound = 'UniversalSkipCertificateCheck' -in $TaskParameterNames
    }
    $configuration = Sampler.PowerShellUniversalTasks\Resolve-UniversalServerConfiguration @configurationParameters

    $universalServer = $BuildInfo.UniversalServer
    if ($UniversalDeploymentNotificationDelaySeconds -eq 2 -and
        $null -ne $universalServer.UniversalDeploymentNotificationDelaySeconds)
    {
        $UniversalDeploymentNotificationDelaySeconds = [System.Convert]::ToInt32(
            $universalServer.UniversalDeploymentNotificationDelaySeconds
        )
    }

    if ($UniversalDeploymentNotificationLookbackSeconds -eq 120 -and
        $null -ne $universalServer.UniversalDeploymentNotificationLookbackSeconds)
    {
        $UniversalDeploymentNotificationLookbackSeconds = [System.Convert]::ToInt32(
            $universalServer.UniversalDeploymentNotificationLookbackSeconds
        )
    }

    if ([System.String]::IsNullOrWhiteSpace($UniversalDeploymentNotificationFilter) -and
        -not [System.String]::IsNullOrWhiteSpace($universalServer.UniversalDeploymentNotificationFilter))
    {
        $UniversalDeploymentNotificationFilter = [System.String] $universalServer.UniversalDeploymentNotificationFilter
    }

    if ($UniversalDeploymentNotificationDelaySeconds -lt 0 -or
        $UniversalDeploymentNotificationDelaySeconds -gt 300)
    {
        throw 'UniversalDeploymentNotificationDelaySeconds must be between 0 and 300.'
    }

    if ($UniversalDeploymentNotificationLookbackSeconds -lt 1 -or
        $UniversalDeploymentNotificationLookbackSeconds -gt 3600)
    {
        throw 'UniversalDeploymentNotificationLookbackSeconds must be between 1 and 3600.'
    }

    if ($UniversalDeploymentNotificationDelaySeconds -gt 0)
    {
        Write-Build -Color DarkGray -Text ("Waiting {0} second(s) for deployment notifications." -f $UniversalDeploymentNotificationDelaySeconds)
        Start-Sleep -Seconds $UniversalDeploymentNotificationDelaySeconds
    }

    $notificationSince = $script:UniversalDeploymentStartedAt
    if (-not $notificationSince)
    {
        $notificationSince = [System.DateTimeOffset]::UtcNow.AddSeconds(-$UniversalDeploymentNotificationLookbackSeconds)
        Write-Build -Color Yellow -Text ("Deployment start time was not recorded. Checking the last {0} second(s)." -f $UniversalDeploymentNotificationLookbackSeconds)
    }

    $notificationFilter = $UniversalDeploymentNotificationFilter
    $errorParameters = @{
        ServerUrl            = $configuration.ServerUrl
        AppToken             = $configuration.AppToken
        Since                = $notificationSince
        FilterText           = $notificationFilter
        SkipCertificateCheck = $configuration.SkipCertificateCheck
    }
    $deploymentErrors = @(Sampler.PowerShellUniversalTasks\Get-UniversalDeploymentError @errorParameters)

    if ($deploymentErrors.Count -gt 0)
    {
        $errorSummary = $deploymentErrors | ForEach-Object -Process {
            '[{0}] [{1}] {2}: {3}' -f $_.CreatedTime, $_.Level, $_.Title, $_.Description
        }

        Write-Build -Color Red -Text 'PowerShell Universal deployment validation failed:'
        foreach ($errorMessage in $errorSummary)
        {
            Write-Build -Color Red -Text ("  {0}" -f $errorMessage)
        }

        $failureMessage = 'PowerShell Universal deployment validation failed after {0}:{1}{2}' -f @(
            $notificationSince
            [System.Environment]::NewLine
            ($errorSummary -join [System.Environment]::NewLine)
        )
        throw $failureMessage
    }

    Write-Build -Color Green -Text ("No PowerShell Universal deployment error notifications were found after {0}." -f $notificationSince)
}

# Synopsis: Install the module from a PSU resource repository and validate deployment notifications.
task publish_psu_pull_module_from_psresourcerepo publish_module_from_psresource_repos_to_universal_server, assert_universal_deployment_succeeded

# Synopsis: Package and deploy an offline PSU automation repository and validate deployment notifications.
task publish_psu_push_repository package_universal_automation_repository, publish_universal_automation_repository_to_server, assert_universal_deployment_succeeded
