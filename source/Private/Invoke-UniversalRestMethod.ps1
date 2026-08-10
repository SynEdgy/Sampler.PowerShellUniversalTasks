function Invoke-UniversalRestMethod
{
    <#
        .SYNOPSIS
            Invokes Invoke-RestMethod with optional certificate validation bypass.

        .DESCRIPTION
            Forwards the supplied parameters to Invoke-RestMethod. When
            SkipCertificateCheck is enabled, the request bypasses TLS
            certificate validation using the native parameter on PowerShell 6
            and above, or a temporary ServicePointManager callback on Windows
            PowerShell.

        .PARAMETER RestMethodParameters
            Parameters forwarded to Invoke-RestMethod.

        .PARAMETER SkipCertificateCheck
            Whether to bypass TLS certificate validation for the request.

        .EXAMPLE
            Invoke-UniversalRestMethod -RestMethodParameters $requestParameters -SkipCertificateCheck $true
    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $RestMethodParameters,

        [Parameter()]
        [System.Boolean]
        $SkipCertificateCheck = $false
    )

    if (-not $SkipCertificateCheck)
    {
        return Invoke-RestMethod @RestMethodParameters
    }

    if ($PSVersionTable.PSVersion.Major -ge 6)
    {
        return Invoke-RestMethod @RestMethodParameters -SkipCertificateCheck
    }

    $originalCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback

    try
    {
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

        Invoke-RestMethod @RestMethodParameters
    }
    finally
    {
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $originalCallback
    }
}
