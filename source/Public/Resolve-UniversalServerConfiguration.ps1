function Resolve-UniversalServerConfiguration
{
    <#
        .SYNOPSIS
            Resolves PowerShell Universal deployment settings for build tasks.

        .DESCRIPTION
            Combines explicit task parameters, the UniversalServer section from
            build.yaml, and build environment variables into one validated object.

        .PARAMETER BuildInfo
            Build configuration data loaded by Sampler from build.yaml.

        .PARAMETER ServerUrl
            Explicit PowerShell Universal server URL.

        .PARAMETER AppToken
            Explicit PowerShell Universal application token.

        .PARAMETER RepositoryName
            Explicit PowerShell resource repository name.

        .PARAMETER RepositoryUrl
            Explicit PowerShell resource repository URL or local path.

        .PARAMETER RepositoryAutoRemove
            Whether the resource repository is removed after deployment.

        .PARAMETER Unpinned
            Whether the uploaded automation repository is deployed unpinned.

        .PARAMETER RepositoryAutoRemoveWasBound
            Indicates that RepositoryAutoRemove was supplied explicitly.

        .PARAMETER UnpinnedWasBound
            Indicates that Unpinned was supplied explicitly.

        .PARAMETER RequireRepository
            Requires and resolves resource repository settings.

        .EXAMPLE
            Resolve-UniversalServerConfiguration -BuildInfo $BuildInfo
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param
    (
        [Parameter()]
        [System.Collections.Hashtable]
        $BuildInfo = @{ },

        [Parameter()]
        [System.String]
        $ServerUrl,

        [Parameter()]
        [System.String]
        $AppToken,

        [Parameter()]
        [System.String]
        $RepositoryName,

        [Parameter()]
        [System.String]
        $RepositoryUrl,

        [Parameter()]
        [System.Boolean]
        $RepositoryAutoRemove = $true,

        [Parameter()]
        [System.Boolean]
        $Unpinned = $true,

        [Parameter()]
        [System.Boolean]
        $RepositoryAutoRemoveWasBound = $false,

        [Parameter()]
        [System.Boolean]
        $UnpinnedWasBound = $false,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $RequireRepository
    )

    $server = $BuildInfo.UniversalServer

    if ([System.String]::IsNullOrWhiteSpace($ServerUrl))
    {
        $ServerUrl = $server.UniversalServerUrl
    }

    if ([System.String]::IsNullOrWhiteSpace($ServerUrl))
    {
        $ServerUrl = $env:UniversalServerUrl
    }

    if ([System.String]::IsNullOrWhiteSpace($AppToken))
    {
        $AppToken = $server.UniversalServerAppToken
    }

    if ([System.String]::IsNullOrWhiteSpace($AppToken))
    {
        $AppToken = $env:UniversalServerAppToken
    }

    if ([System.String]::IsNullOrWhiteSpace($ServerUrl))
    {
        throw 'UniversalServerUrl is required. Set UniversalServer.UniversalServerUrl in build.yaml or provide the build parameter.'
    }

    if ([System.String]::IsNullOrWhiteSpace($AppToken))
    {
        throw 'UniversalServerAppToken is required. Provide it through the build environment or a local secrets file.'
    }

    if ([System.String]::IsNullOrWhiteSpace($RepositoryName))
    {
        $RepositoryName = $server.UniversalPSResourceRepositoryName
    }

    if ([System.String]::IsNullOrWhiteSpace($RepositoryUrl))
    {
        $RepositoryUrl = $server.UniversalPSResourceRepositoryUrl
    }

    if ($RequireRepository -and [System.String]::IsNullOrWhiteSpace($RepositoryName))
    {
        $RepositoryName = 'output'
    }

    if ($RequireRepository -and [System.String]::IsNullOrWhiteSpace($RepositoryUrl))
    {
        $RepositoryUrl = './output/'
    }

    if (-not $RepositoryAutoRemoveWasBound -and $null -ne $server.UniversalPSResourceRepositoryAutoRemove)
    {
        $RepositoryAutoRemove = [System.Convert]::ToBoolean($server.UniversalPSResourceRepositoryAutoRemove)
    }

    if (-not $UnpinnedWasBound -and $null -ne $server.UniversalUnpinned)
    {
        $Unpinned = [System.Convert]::ToBoolean($server.UniversalUnpinned)
    }

    [PSCustomObject]@{
        ServerUrl            = $ServerUrl.TrimEnd('/')
        AppToken             = $AppToken
        RepositoryName       = $RepositoryName
        RepositoryUrl        = $RepositoryUrl
        RepositoryAutoRemove = $RepositoryAutoRemove
        Unpinned             = $Unpinned
    }
}
