function Install-UniversalModuleFromRepository
{
    <#
        .SYNOPSIS
            Installs a module on PowerShell Universal from a resource repository.

        .DESCRIPTION
            Reconciles the requested PowerShell resource repository, triggers a
            synchronous module deployment, and optionally removes the repository.

        .PARAMETER ServerUrl
            Base URL of the PowerShell Universal server.

        .PARAMETER AppToken
            Application token used to authenticate API requests.

        .PARAMETER ModuleName
            Name of the module to install.

        .PARAMETER ModuleVersion
            Version of the module to install.

        .PARAMETER RepositoryName
            Name of the PowerShell resource repository on the server.

        .PARAMETER RepositoryUrl
            URL or local path used by the PowerShell resource repository.

        .PARAMETER RepositoryAutoRemove
            Whether to remove the repository after the deployment attempt.

        .EXAMPLE
            Install-UniversalModuleFromRepository @installParameters
    #>
    [CmdletBinding()]
    [OutputType([System.Void])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AppToken,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleVersion,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RepositoryName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RepositoryUrl,

        [Parameter()]
        [System.Boolean]
        $RepositoryAutoRemove = $true
    )

    $headers = @{
        Authorization = 'Bearer {0}' -f $AppToken
        Accept        = 'application/json'
    }
    $repositoryEndpoint = '{0}/api/v1/resourceRepository' -f $ServerUrl
    $repositories = @(Invoke-RestMethod -Uri $repositoryEndpoint -Headers $headers -Method Get)
    $existingRepository = $repositories |
        Where-Object -FilterScript { $_.name -eq $RepositoryName } |
        Select-Object -First 1

    if ($existingRepository)
    {
        $sameUrl = [System.String]::Equals(
            [System.String] $existingRepository.url,
            $RepositoryUrl,
            [System.StringComparison]::OrdinalIgnoreCase
        )

        if ((-not $sameUrl -or -not [System.Boolean] $existingRepository.trusted) -and $RepositoryAutoRemove)
        {
            $deleteUri = '{0}/{1}' -f $repositoryEndpoint, [System.Uri]::EscapeDataString($RepositoryName)
            $null = Invoke-RestMethod -Uri $deleteUri -Headers $headers -Method Delete
            $existingRepository = $null
        }
    }

    if (-not $existingRepository)
    {
        $body = @{
            name    = $RepositoryName
            url     = $RepositoryUrl
            trusted = $true
            id      = 0
        } | ConvertTo-Json -Depth 5

        $null = Invoke-RestMethod -Uri $repositoryEndpoint -Headers $headers -Method Post -Body $body -ContentType 'application/json; charset=utf-8'
    }

    try
    {
        $deployUri = '{0}/api/v1/deployment/module/{1}/{2}?repository={3}&synchronous=true' -f @(
            $ServerUrl
            $ModuleName
            $ModuleVersion
            [System.Uri]::EscapeDataString($RepositoryName)
        )
        $null = Invoke-RestMethod -Uri $deployUri -Headers $headers -Method Put -ContentType 'application/octet-stream; charset=utf-8'
    }
    finally
    {
        if ($RepositoryAutoRemove)
        {
            $deleteUri = '{0}/{1}' -f $repositoryEndpoint, [System.Uri]::EscapeDataString($RepositoryName)
            try
            {
                $null = Invoke-RestMethod -Uri $deleteUri -Headers $headers -Method Delete
            }
            catch
            {
                Write-Warning -Message ("Failed to remove PowerShell resource repository '{0}': {1}" -f $RepositoryName, $_.Exception.Message)
            }
        }
    }
}
